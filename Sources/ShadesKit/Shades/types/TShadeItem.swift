import AppKit

struct ShadeColor: Sendable {
    let r: CGFloat
    let g: CGFloat
    let b: CGFloat

    var hex: String {
        String(format: "#%02X%02X%02X", Int(r), Int(g), Int(b))
    }

    func withAlpha(_ alpha: CGFloat) -> NSColor {
        NSColor(srgbRed: r / 255.0, green: g / 255.0, blue: b / 255.0, alpha: alpha)
    }
}
