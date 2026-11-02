import AppKit

final class KGColors {

    static func colorFromHex(_ hex: String) -> NSColor {
        let s = hex.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: s).scanHexInt64(&rgb)
        return NSColor(
            red:   CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8)  & 0xFF) / 255,
            blue:  CGFloat( rgb        & 0xFF) / 255,
            alpha: 1
        )
    }

    static func allPalettes() -> [[NSColor]] {
        let hexPalettes: [[String]] = [
            // Océan
            ["#001f3f", "#2E86AB", "#A23B72", "#F18F01",
             "#C73E1D", "#7FDBFF", "#85C1E9", "#48C9B0", "#52BE80", "#F8C471"],
            // Coucher de soleil
            ["#FF6B6B", "#FF8E53", "#FF6B9D", "#FFD93D",
             "#6BCF7F", "#4ECDC4", "#45B7D1", "#96CEB4", "#FFEAA7", "#DDA0DD"],
            // Sombre
            ["#2C3E50", "#34495E", "#E74C3C", "#E67E22",
             "#F39C12", "#27AE60", "#16A085", "#3498DB", "#9B59B6", "#95A5A6"],
            // Cyberpunk
            ["#0F3460", "#533483", "#E94560", "#0F4C75",
             "#3282B8", "#BBE1FA", "#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4"],
            // Pastèque
            ["#007A3D", "#FFFFFF", "#FF0000"],
        ]
        return hexPalettes.map { $0.map { colorFromHex($0) } }
    }

    static func randomPalette() -> [NSColor] {
        let palettes = allPalettes()
        return palettes[Int.random(in: 0..<palettes.count)]
    }

    static func paletteAtIndex(_ index: Int) -> [NSColor] {
        let palettes = allPalettes()
        return palettes[max(0, min(index, palettes.count - 1))]
    }
}
