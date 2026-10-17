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
            continue
        }
        if line.hasPrefix("```") {
            flushParagraph()
            codeLines = []
            continue
        }

        let text = line.drop { $0 == " " || $0 == "\t" }

        if text.hasPrefix("#") {
            let level = text.prefix { $0 == "#" }.count
            let rest = text.dropFirst(level)
            if level <= 6, rest.hasPrefix(" ") {
                flushParagraph()
                blocks.append(.heading(level: level, text: String(rest.dropFirst(1))))
                continue
            }
        }

        if text.hasPrefix("- ") || text.hasPrefix("* ") {
            let rest = text.dropFirst(2)
            flushParagraph()
            if rest.hasPrefix("["), rest.count >= 3 {
                let mark = rest[rest.index(after: rest.startIndex)]
                if rest[rest.index(rest.startIndex, offsetBy: 2)] == "]", mark == " " || mark == "x" || mark == "X" {
                    let body = rest.dropFirst(3).drop { $0 == " " }
                    blocks.append(.task(done: mark != " ", text: String(body)))
                    continue
                }
            }
            blocks.append(.bullet(String(rest)))
            continue
        }

        if let first = text.first, first.isNumber {
            var digits = text.startIndex
            while digits < text.endIndex, text[digits].isNumber { digits = text.index(after: digits) }
            if digits < text.endIndex, text[digits] == "." || text[digits] == ")" {
                let after = text.index(after: digits)
                if after < text.endIndex, text[after] == " " {
                    flushParagraph()
                    blocks.append(.numbered(String(text[text.index(after: after)...])))
                    continue
                }
            }
        }

        if text.isEmpty {
            flushParagraph()
        } else {
            paragraph.append(String(text))
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
            let blocks = parseMarkdown(source)
            VStack(alignment: .leading, spacing: 10) {
                ForEach(blocks.indices, id: \.self) { index in
                    blockView(blocks[index])
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
