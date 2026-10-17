import SwiftUI

struct ContentView: View {
    @ObservedObject var store: NoteStore

    var body: some View {
        HStack(spacing: 0) {
            sidebar
                .frame(width: 190)
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

    private var sidebar: some View {
        List(store.notes) { note in
            Button { store.select(note) } label: {
                Label(note.name, systemImage: "doc.text")
                    .lineLimit(1)
            }
            .buttonStyle(.plain)
            .listRowBackground(
                note == store.currentNote ? Color.accentColor.opacity(0.15) : Color.clear
            )
        }
        .listStyle(.sidebar)
    }

    private var header: some View {
        HStack {
            Text(store.currentNote?.name ?? "No Note")
                .font(.headline)
                .lineLimit(1)
            Spacer()
            Button { store.newNote() } label: {
                Image(systemName: "plus")
            }
            .help("New note")
            Button(role: .destructive) {
                if let note = store.currentNote { store.delete(note) }
            } label: {
                Image(systemName: "trash")
            }
            .help("Delete note")
            .disabled(store.currentNote == nil)
        }
        .buttonStyle(.borderless)
        .padding(8)
    }
}
