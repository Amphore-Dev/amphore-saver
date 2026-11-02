import AppKit
import CoreText
import ScreensaverCore

final class TextShadeItem: ShadeItem {
    nonisolated(unsafe) private static var formatters: [String: DateFormatter] = [:]

    static nonisolated(unsafe) let customFont: CTFont? = {
        guard let url = ResourceBundle.named("amphore-saver_ShadesKit", containing: TextShadeItem.self)?
            .url(forResource: "Remained", withExtension: "ttf") else { return nil }
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        guard let descriptors = CTFontManagerCreateFontDescriptorsFromURL(url as CFURL) as? [CTFontDescriptor],
              let descriptor = descriptors.first else { return nil }
        return CTFontCreateWithFontDescriptor(descriptor, 0, nil)
    }()

    private func text(format: String) -> String {
        let formatter = Self.formatters[format] ?? {
            let f = DateFormatter()
            f.dateFormat = format
            Self.formatters[format] = f
            return f
        }()
        return formatter.string(from: Date())
    }

    override func draw(_ ctx: CGContext, _ config: ShadeConfig, _ offset: ShadePoint) {
        let font: NSFont
        if let ctFont = Self.customFont {
            font = CTFontCreateCopyWithAttributes(ctFont, config.width, nil, nil) as NSFont
        } else {
            font = NSFont.monospacedDigitSystemFont(ofSize: config.width, weight: .bold)
        }

        for i in 0..<config.nbrShades {
            let alpha = max(0, 1 - (config.gradRatio * CGFloat(i)) / 100)
            let nsColor = color.withAlpha(alpha)
            let factor = 1 - (config.gradRatio * CGFloat(i)) / 100

            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: nsColor,
            ]
            let str = text(format: config.timeFormat) as NSString
            let size = str.size(withAttributes: attrs)

            let drawX = config.width / 2 + config.center.x
                + (position.x - config.totalWidth / 2) + offset.x * factor - size.width / 2
            let drawY = config.height / 2 + config.center.y
                + (position.y - config.totalHeight / 2) + offset.y * factor - size.height / 2

            str.draw(at: NSPoint(x: drawX, y: drawY), withAttributes: attrs)
        }
    }
}
