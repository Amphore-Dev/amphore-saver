import AppKit

extension CGColor {
    /// Parses #RGB, #RGBA, #RRGGBB or #RRGGBBAA (white when invalid).
    static func fromHex(_ hex: String) -> CGColor {
        var h = hex.trimmingCharacters(in: .whitespaces)
        if h.hasPrefix("#") { h = String(h.dropFirst()) }
        if h.count == 3 || h.count == 4 {
            h = h.map { "\($0)\($0)" }.joined()
        }

        guard (h.count == 6 || h.count == 8), let value = UInt64(h, radix: 16) else {
            return CGColor(red: 1, green: 1, blue: 1, alpha: 1)
        }

        if h.count == 8 {
            let r = CGFloat((value >> 24) & 0xFF) / 255
            let g = CGFloat((value >> 16) & 0xFF) / 255
            let b = CGFloat((value >> 8) & 0xFF) / 255
            let a = CGFloat(value & 0xFF) / 255
            return CGColor(red: r, green: g, blue: b, alpha: a)
        }

        let r = CGFloat((value >> 16) & 0xFF) / 255
        let g = CGFloat((value >> 8) & 0xFF) / 255
        let b = CGFloat(value & 0xFF) / 255
        return CGColor(red: r, green: g, blue: b, alpha: 1)
    }
}
