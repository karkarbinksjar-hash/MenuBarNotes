import AppKit

/// Vector brand mark shared by the menu bar item, the About panel and the app icon.
/// Drawn programmatically so the menu bar glyph is crisp at every scale and can
/// adopt the system template tint without shipping extra image resources.
enum BrandMark {
    /// Monochrome template glyph for the status item (18 pt by default).
    static func statusItemImage(size: CGFloat = 18) -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            let s = min(rect.width, rect.height)
            func pt(_ x: CGFloat, _ y: CGFloat) -> NSPoint {
                NSPoint(x: rect.minX + x * s, y: rect.minY + y * s)
            }

            let page = NSBezierPath()
            page.move(to: pt(0.19, 0.10))
            page.line(to: pt(0.81, 0.10))
            page.line(to: pt(0.81, 0.57))
            page.line(to: pt(0.55, 0.88))
            page.line(to: pt(0.19, 0.88))
            page.close()
            page.lineWidth = max(1, 0.085 * s)
            page.lineJoinStyle = .round
            page.lineCapStyle = .round

            NSColor.black.setStroke()
            page.stroke()

            let fold = NSBezierPath()
            fold.move(to: pt(0.55, 0.88))
            fold.line(to: pt(0.55, 0.58))
            fold.line(to: pt(0.81, 0.58))
            fold.lineWidth = page.lineWidth
            fold.lineJoinStyle = .round
            fold.stroke()

            let text = NSBezierPath()
            text.lineWidth = max(1, 0.075 * s)
            text.lineCapStyle = .round
            text.move(to: pt(0.31, 0.69))
            text.line(to: pt(0.50, 0.69))
            text.move(to: pt(0.31, 0.52))
            text.line(to: pt(0.65, 0.52))
            text.move(to: pt(0.31, 0.35))
            text.line(to: pt(0.52, 0.35))
            text.stroke()
            return true
        }
        image.isTemplate = true
        return image
    }

    /// Full-colour icon used in the About panel (and as a preview of the bundle icon).
    static func appIconImage(size: CGFloat = 512) -> NSImage {
        NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            let s = min(rect.width, rect.height)
            func pt(_ x: CGFloat, _ y: CGFloat) -> NSPoint {
                NSPoint(x: rect.minX + x * s, y: rect.minY + y * s)
            }
            func box(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) -> NSRect {
                NSRect(x: rect.minX + x * s, y: rect.minY + y * s, width: width * s, height: height * s)
            }

            // Indigo → violet tile
            let tile = NSBezierPath(roundedRect: box(0.028, 0.028, 0.944, 0.944),
                                    xRadius: 0.221 * s, yRadius: 0.221 * s)
            let colors = [
                NSColor(srgbRed: 0.545, green: 0.302, blue: 0.941, alpha: 1),
                NSColor(srgbRed: 0.424, green: 0.486, blue: 1.000, alpha: 1),
            ]
            if let gradient = NSGradient(colors: colors) {
                gradient.draw(in: tile, angle: 90)
            } else {
                NSColor(srgbRed: 0.49, green: 0.39, blue: 0.97, alpha: 1).setFill()
                tile.fill()
            }

            // Page with folded corner
            let page = NSBezierPath(roundedRect: box(0.258, 0.172, 0.514, 0.656),
                                    xRadius: 0.058 * s, yRadius: 0.058 * s)
            NSColor.white.setFill()
            page.fill()

            let fold = NSBezierPath()
            fold.move(to: pt(0.642, 0.828))
            fold.line(to: pt(0.772, 0.828))
            fold.line(to: pt(0.772, 0.688))
            fold.close()
            NSColor(srgbRed: 0.827, green: 0.863, blue: 1.0, alpha: 1).setFill()
            fold.fill()

            // Markdown hash
            let hash = NSBezierPath()
            hash.lineWidth = 0.032 * s
            hash.lineCapStyle = .round
            hash.move(to: pt(0.406, 0.616))
            hash.line(to: pt(0.372, 0.752))
            hash.move(to: pt(0.505, 0.616))
            hash.line(to: pt(0.471, 0.752))
            hash.move(to: pt(0.350, 0.664))
            hash.line(to: pt(0.528, 0.664))
            hash.move(to: pt(0.340, 0.714))
            hash.line(to: pt(0.518, 0.714))
            NSColor(srgbRed: 0.310, green: 0.275, blue: 0.898, alpha: 1).setStroke()
            hash.stroke()

            // Heading and body lines
            NSColor(srgbRed: 0.141, green: 0.165, blue: 0.290, alpha: 1).setFill()
            NSBezierPath(roundedRect: box(0.592, 0.664, 0.144, 0.039),
                         xRadius: 0.020 * s, yRadius: 0.020 * s).fill()
            NSColor(srgbRed: 0.765, green: 0.800, blue: 0.902, alpha: 1).setFill()
            for (y, end) in [(0.586, 0.728), (0.522, 0.672), (0.458, 0.698)] {
                NSBezierPath(roundedRect: box(0.336, y, end - 0.336, 0.034),
                             xRadius: 0.017 * s, yRadius: 0.017 * s).fill()
            }

            // Done badge
            NSColor.white.setFill()
            NSBezierPath(ovalIn: box(0.608, 0.206, 0.204, 0.204)).fill()
            NSColor(srgbRed: 0.133, green: 0.773, blue: 0.369, alpha: 1).setFill()
            NSBezierPath(ovalIn: box(0.628, 0.226, 0.164, 0.164)).fill()

            let check = NSBezierPath()
            check.lineWidth = 0.030 * s
            check.lineCapStyle = .round
            check.lineJoinStyle = .round
            check.move(to: pt(0.669, 0.308))
            check.line(to: pt(0.699, 0.278))
            check.line(to: pt(0.752, 0.336))
            NSColor.white.setStroke()
            check.stroke()
            return true
        }
    }
}
