import Foundation

struct Note: Identifiable, Equatable, Hashable {
    let url: URL
    var id: URL { url }
    var name: String { url.deletingPathExtension().lastPathComponent }
}

/// Plain `.md` files in ~/Documents/MenuBarNotes. Writes are atomic and
/// coordinated so cloud-sync daemons never see partial or conflicting files.
final class NoteStore: NSObject, ObservableObject {
    @Published var notes: [Note] = []
    @Published var currentNote: Note?
    @Published var text: String = ""
    @Published var saveError: String?

    let directory: URL
    private var pendingSave: DispatchWorkItem?
    // Presenter callbacks use their own serial queue so NSFileCoordinator never re-enters this presenter while a callback is in flight (deadlock).
    private let presenterQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "MenuBarNotes.filePresenter"
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    override init() {
        directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("MenuBarNotes")
        super.init()
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        NSFileCoordinator.addFilePresenter(self)
        refreshList()
    }

    // MARK: Editing

    func select(_ note: Note) {
        guard note != currentNote else { return }
        flushSave()
        currentNote = note
        text = read(note.url) ?? ""
    }

    func newNote() {
        flushSave()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH.mm.ss"
        let url = directory.appendingPathComponent("Note \(formatter.string(from: Date())).md")
        write(url, Data())
        refreshList()
        if let note = notes.first(where: { $0.url == url }) {
            currentNote = note
            text = ""
        }
    }

    func delete(_ note: Note) {
        flushSave()
        var error: NSError?
        NSFileCoordinator(filePresenter: self).coordinate(writingItemAt: note.url, options: .forDeleting, error: &error) { url in
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                self.fail("Couldn't delete \(note.name): \(error.localizedDescription)")
            }
        }
        if let error { fail("Couldn't delete \(note.name): \(error.localizedDescription)") }
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
        write(note.url, Data(text.utf8))
    }

    // MARK: Disk

    private func read(_ url: URL) -> String? {
        var result: String?
        var error: NSError?
        NSFileCoordinator(filePresenter: self).coordinate(readingItemAt: url, options: [], error: &error) { url in
            do {
                result = try String(contentsOf: url, encoding: .utf8)
            } catch {
                self.fail("Couldn't read \(url.lastPathComponent): \(error.localizedDescription)")
            }
        }
        return result
    }

    private func write(_ url: URL, _ data: Data) {
        var error: NSError?
        NSFileCoordinator(filePresenter: self).coordinate(writingItemAt: url, options: .forReplacing, error: &error) { url in
            do {
                try data.write(to: url, options: .atomic)
            } catch {
                self.fail("Couldn't save \(url.lastPathComponent): \(error.localizedDescription)")
            }
        }
    }

    private func fail(_ message: String) {
        NSLog("MenuBarNotes: %@", message)
        saveError = message
    }

    private func refreshList() {
        let urls = ((try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? [])
            .filter { $0.pathExtension.lowercased() == "md" }
            .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
        notes = urls.map { Note(url: $0) }
        if let current = currentNote, let match = notes.first(where: { $0.url == current.url }) {
            currentNote = match
        } else {
            currentNote = notes.first
            text = currentNote.flatMap { read($0.url) } ?? ""
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
            self.refreshList()
        }
    }
}
