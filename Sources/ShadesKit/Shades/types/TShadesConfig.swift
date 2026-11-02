import AppKit

struct ShadeConfig {
    var width: CGFloat
    var height: CGFloat
    var spacing: CGFloat
    var thickness: CGFloat
    var nbrShades: Int
    var nbrItemsX: Int
    var nbrItemsY: Int
    var center: ShadePoint
    var totalWidth: CGFloat
    var totalHeight: CGFloat
    var gradRatio: CGFloat
    var type: ShadeType
    var colors: [ShadeColor]
    var mainColor: ShadeColor
    var lineCap: CGLineCap
    var fillFilter: (ShadeColor, ShadeColor) -> Bool
    var rotationFilter: (ShadeColor, ShadeColor) -> Bool
}
