import Foundation

// MARK: - Block-level markdown (line parser — Foundation only, unit-tested)

enum MarkdownBlock: Equatable {
    case heading(level: Int, text: String)
    case code(String)
    case task(done: Bool, text: String)
    case bullet(String)
    case numbered(String)
    case paragraph(String)
}

func parseMarkdown(_ source: String) -> [MarkdownBlock] {
    var blocks: [MarkdownBlock] = []
    var paragraph: [String] = []
    var codeLines: [String]?
    let heading = /^(#{1,6})\s+(.*)$/
    let task = /^\s*[-*]\s+\[([ xX])\]\s*(.*)$/
    let bullet = /^\s*[-*]\s+(.*)$/
    let numbered = /^\s*\d+[.)]\s+(.*)$/

    func flushParagraph() {
        if !paragraph.isEmpty {
            blocks.append(.paragraph(paragraph.joined(separator: " ")))
            paragraph = []
        }
    }

    for line in source.components(separatedBy: .newlines) {
        if var code = codeLines {
            if line.hasPrefix("```") {
                blocks.append(.code(code.joined(separator: "\n")))
                codeLines = nil
            } else {
                code.append(line)
                codeLines = code
            }
        } else if line.hasPrefix("```") {
            flushParagraph()
            codeLines = []
        } else if let match = line.wholeMatch(of: heading) {
            flushParagraph()
            blocks.append(.heading(level: match.output.1.count, text: String(match.output.2)))
        } else if let match = line.wholeMatch(of: task) {
            flushParagraph()
            blocks.append(.task(done: match.output.1 != " ", text: String(match.output.2)))
        } else if let match = line.wholeMatch(of: bullet) {
            flushParagraph()
            blocks.append(.bullet(String(match.output.1)))
        } else if let match = line.wholeMatch(of: numbered) {
            flushParagraph()
            blocks.append(.numbered(String(match.output.1)))
        } else if line.trimmingCharacters(in: .whitespaces).isEmpty {
            flushParagraph()
        } else {
            paragraph.append(line)
        }
    }
    flushParagraph()
    if let code = codeLines {
        blocks.append(.code(code.joined(separator: "\n"))) // unclosed fence: keep the text
    }
    return blocks
}

// MARK: - SwiftUI rendering with live inline formatting

import SwiftUI

struct MarkdownPreviewView: View {
    let source: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(parseMarkdown(source).enumerated()), id: \.offset) { _, block in
                    blockView(block)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }

    @ViewBuilder
    private func blockView(_ block: MarkdownBlock) -> some View {
        switch block {
        case .heading(let level, let text):
            Text(inline(text)).font(headingFont(level))
        case .code(let code):
            Text(code)
                .font(.system(.callout, design: .monospaced))
                .textSelection(.enabled)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.primary.opacity(0.06), in: .rect(cornerRadius: 6))
        case .task(let done, let text):
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Image(systemName: done ? "checkmark.square.fill" : "square")
                    .foregroundStyle(done ? Color.accentColor : .secondary)
                Text(inline(text))
            }
        case .bullet(let text):
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("•").foregroundStyle(.secondary)
                Text(inline(text))
            }
            .padding(.leading, 8)
        case .numbered(let text):
            Text(inline(text)).padding(.leading, 8)
        case .paragraph(let text):
            Text(inline(text))
        }
    }

    private func headingFont(_ level: Int) -> Font {
        switch level {
        case 1: .title
        case 2: .title2
        case 3: .title3
        default: .headline
        }
    }

    private func inline(_ text: String) -> AttributedString {
        (try? AttributedString(
            markdown: text,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        )) ?? AttributedString(text)
    }
}
