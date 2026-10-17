import Foundation

/// Plain `.md` files in ~/Documents/MenuBarNotes. Writes are atomic and
/// coordinated so cloud-sync daemons never see partial or conflicting files.
final class NoteStore: NSObject, ObservableObject {
    @Published var notes: [Note] = []
    @Published var currentNote: Note?
    @Published var text: String = ""
    @Published var saveError: String?
    @Published private(set) var pinnedFileName: String?
    @Published private(set) var lastSavedAt: Date?

    let directory: URL
    private var pendingSave: DispatchWorkItem?
    private var pendingRefresh: DispatchWorkItem?
    // Presenter callbacks use their own serial queue so NSFileCoordinator never re-enters this presenter while a callback is in flight (deadlock).
    private let presenterQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "MenuBarNotes.filePresenter"
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    private static let pinnedDefaultsKey = "pinnedNoteFileName"
    private static let nameFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH.mm.ss"
        return formatter
    }()

    override init() {
        directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("MenuBarNotes")
        super.init()
        pinnedFileName = UserDefaults.standard.string(forKey: Self.pinnedDefaultsKey)
        // 0o700: other local accounts cannot browse a synced folder full of notes.
        try? FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700]
        )
        NSFileCoordinator.addFilePresenter(self)
        refreshList()
    }

    // MARK: Editing

    func select(_ note: Note) {
        guard note != currentNote else { return }
        flushSave()
        currentNote = note
        text = read(note.url) ?? ""
        lastSavedAt = nil
    }

    func newNote() {
        flushSave()
        let base = "Note \(Self.nameFormatter.string(from: Date()))"
        let existing = Set(notes.map { $0.fileName.lowercased() })
        var fileName = "\(base).md"
        var counter = 2
        while existing.contains(fileName.lowercased()) {
            fileName = "\(base) \(counter).md"
            counter += 1
        }

        let url = directory.appendingPathComponent(fileName)
        guard write(url, Data()) else { return }
        refreshList()
        if let note = notes.first(where: { $0.url == url }) {
            currentNote = note
            text = ""
            lastSavedAt = Date()
        }
    }

    func delete(_ note: Note) {
        flushSave()
        var coordinationError: NSError?
        NSFileCoordinator(filePresenter: self).coordinate(writingItemAt: note.url, options: .forDeleting, error: &coordinationError) { url in
            do {
                try FileManager.default.trashItem(at: url, resultingItemURL: nil)
            } catch {
                self.fail("Couldn't move \(note.name) to Trash: \(error.localizedDescription)")
            }
        }
        if let coordinationError {
            fail("Couldn't move \(note.name) to Trash: \(coordinationError.localizedDescription)")
        }
        if currentNote?.url == note.url {
            currentNote = nil
            text = ""
        }
        refreshList()
    }

    func scheduleSave() {
        pendingSave?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.flushSave() }
        pendingSave = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: work)
    }

    func flushSave() {
        pendingSave?.cancel()
        pendingSave = nil
        guard let note = currentNote else { return }
        // Skip no-op writes so our own saves don't bounce back through the file presenter.
        guard read(note.url) != text else { return }
        if write(note.url, Data(text.utf8)) {
            lastSavedAt = Date()
        }
    }

    /// Cloud clients fire a burst of presenter callbacks per file save. Coalesce
    /// them into a single directory scan instead of enumerating on every event.
    private func scheduleRefresh() {
        pendingRefresh?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.pendingRefresh = nil
            self.refreshList()
        }
        pendingRefresh = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: work)
    }

    // MARK: Pinning

    func isPinned(_ note: Note) -> Bool {
        note.fileName == pinnedFileName
    }

    func togglePin(_ note: Note) {
        let newValue = isPinned(note) ? nil : note.fileName
        pinnedFileName = newValue
        UserDefaults.standard.set(newValue, forKey: Self.pinnedDefaultsKey)
        notes = NoteOrdering.arrange(notes, pinnedFileName: newValue)
    }

    // MARK: Disk

    private func read(_ url: URL) -> String? {
        guard FileSafety.isSafeNote(url, in: directory) else {
            fail("Refused to read \(url.lastPathComponent): it is not a regular note in the notes folder.")
            return nil
        }
        guard !FileSafety.isOversized(url) else {
            fail("\(url.lastPathComponent) is larger than \(FileSafety.maxNoteBytes / 1_048_576) MB and was not opened.")
            return nil
        }
        var result: String?
        var coordinationError: NSError?
        NSFileCoordinator(filePresenter: self).coordinate(readingItemAt: url, options: [], error: &coordinationError) { url in
            do {
                result = try String(contentsOf: url, encoding: .utf8)
            } catch {
                self.fail("Couldn't read \(url.lastPathComponent): \(error.localizedDescription)")
            }
        }
        return result
    }

    @discardableResult
    private func write(_ url: URL, _ data: Data) -> Bool {
        guard FileSafety.isSafeDestination(url, in: directory) else {
            fail("Refused to write \(url.lastPathComponent): it is not a regular note in the notes folder.")
            return false
        }
        guard !FileSafety.isOversized(url) else {
            fail("Refused to overwrite \(url.lastPathComponent): the on-disk file is unexpectedly large.")
            return false
        }
        var succeeded = false
        var coordinationError: NSError?
        NSFileCoordinator(filePresenter: self).coordinate(writingItemAt: url, options: .forReplacing, error: &coordinationError) { url in
            do {
                try data.write(to: url, options: .atomic)
                succeeded = true
            } catch {
                self.fail("Couldn't save \(url.lastPathComponent): \(error.localizedDescription)")
            }
        }
        if let coordinationError {
            fail("Couldn't save \(url.lastPathComponent): \(coordinationError.localizedDescription)")
        }
        return succeeded
    }

    private func fail(_ message: String) {
        NSLog("MenuBarNotes: %@", message)
        saveError = message
    }

    private func refreshList() {
        pendingRefresh?.cancel()
        pendingRefresh = nil
        let urls = ((try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey, .isSymbolicLinkKey]
        )) ?? [])
            .filter { $0.pathExtension.lowercased() == "md" && !$0.lastPathComponent.hasPrefix(".") }
            .filter { FileSafety.isSafeNote($0, in: directory) }
        notes = NoteOrdering.arrange(urls.map { Note(url: $0) }, pinnedFileName: pinnedFileName)
        if let current = currentNote, let match = notes.first(where: { $0.url == current.url }) {
            currentNote = match
        } else {
            currentNote = notes.first
            text = currentNote.flatMap { read($0.url) } ?? ""
            lastSavedAt = nil
        }
    }
}

// MARK: - External change tracking (cloud sync, other editors)

extension NoteStore: NSFilePresenter {
    var presentedItemURL: URL? { directory }
    var presentedItemOperationQueue: OperationQueue { presenterQueue }

    func presentedSubitemDidChange(at url: URL) {
        // Hop to main before coordinating so we never call NSFileCoordinator from the presenter queue.
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if url == self.currentNote?.url, let content = self.read(url), content != self.text {
                self.text = content // external edit wins; our pending save is a no-op afterwards
            }
            self.scheduleRefresh()
        }
    }
}
