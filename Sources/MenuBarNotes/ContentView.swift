import SwiftUI

struct ContentView: View {
    @ObservedObject var store: NoteStore
    @State private var searchText = ""

    var body: some View {
        HStack(spacing: 0) {
            sidebar
                .frame(width: 200)
            Divider()
            VStack(spacing: 0) {
                header
                Divider()
                TextEditor(text: $store.text)
                    .font(.system(.body, design: .monospaced))
                    .frame(minWidth: 320)
                    .onChange(of: store.text) { store.scheduleSave() }
            }
            Divider()
            MarkdownPreviewView(source: store.text)
                .frame(minWidth: 320)
        }
        .frame(width: 940, height: 560)
        .alert(
            "Something went wrong",
            isPresented: Binding(
                get: { store.saveError != nil },
                set: { if !$0 { store.saveError = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(store.saveError ?? "")
        }
    }

    private var visibleNotes: [Note] {
        NoteOrdering.filter(store.notes, query: searchText)
    }

    private var currentIsPinned: Bool {
        guard let note = store.currentNote else { return false }
        return store.isPinned(note)
    }

    private var sidebar: some View {
        VStack(spacing: 0) {
            TextField("Search notes", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding(8)

            List(visibleNotes) { note in
                Button { store.select(note) } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.text")
                        Text(note.name)
                            .lineLimit(1)
                        Spacer(minLength: 0)
                        if store.isPinned(note) {
                            Image(systemName: "pin.fill")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .buttonStyle(.plain)
                .listRowBackground(
                    note == store.currentNote ? Color.accentColor.opacity(0.15) : Color.clear
                )
                .contextMenu {
                    Button(store.isPinned(note) ? "Unpin Note" : "Pin to Top") {
                        store.togglePin(note)
                    }
                    Divider()
                    Button("Move to Trash", role: .destructive) {
                        store.delete(note)
                    }
                }
            }
            .listStyle(.sidebar)
            .overlay {
                if visibleNotes.isEmpty {
                    Text(searchText.isEmpty ? "No notes yet" : "No matches")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Text(store.currentNote?.name ?? "No Note")
                .font(.headline)
                .lineLimit(1)
            Spacer()
            if store.currentNote != nil {
                Text("\(NoteMetrics.wordCount(in: store.text)) words")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                saveStatus
            }
            Button {
                if let note = store.currentNote { store.togglePin(note) }
            } label: {
                Image(systemName: currentIsPinned ? "pin.fill" : "pin")
            }
            .help(currentIsPinned ? "Unpin note" : "Pin note to top")
            .disabled(store.currentNote == nil)

            Button { store.newNote() } label: {
                Image(systemName: "plus")
            }
            .help("New note (⌥⌘N)")

            Button(role: .destructive) {
                if let note = store.currentNote { store.delete(note) }
            } label: {
                Image(systemName: "trash")
            }
            .help("Move note to Trash")
            .disabled(store.currentNote == nil)
        }
        .buttonStyle(.borderless)
        .padding(8)
    }

    @ViewBuilder
    private var saveStatus: some View {
        if let savedAt = store.lastSavedAt {
            Text("Saved \(savedAt, style: .time)")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            Text("Not saved yet")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
