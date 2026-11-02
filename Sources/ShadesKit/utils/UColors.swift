import Foundation

func rgbToHex(_ color: ShadeColor) -> String {
    color.hex
}

func randomColor() -> ShadeColor {
    ShadeColor(
        r: CGFloat(Int.random(in: 0...255)),
        g: CGFloat(Int.random(in: 0...255)),
        b: CGFloat(Int.random(in: 0...255))
    )
}
