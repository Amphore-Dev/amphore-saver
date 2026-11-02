import AppKit

class ShadeItem {
    var position: ShadePoint
    var angle: CGFloat = 0
    var rotation: Bool
    var color: ShadeColor
    var filled: Bool
    var lineCap: CGLineCap

    init(x: CGFloat, y: CGFloat, color: ShadeColor,
         filled: Bool = false, rotation: Bool = false, lineCap: CGLineCap = .butt) {
        self.position = ShadePoint(x: x, y: y)
        self.color = color
        self.filled = filled
        self.rotation = rotation
        self.lineCap = lineCap
    }

    func draw(_ ctx: CGContext, _ config: ShadeConfig, _ offset: ShadePoint) {}

    func setColors(_ ctx: CGContext, _ gradRatio: CGFloat, _ i: Int) {
        let alpha = max(0, 1 - (gradRatio * CGFloat(i)) / 100)
        let c = color.withAlpha(alpha).cgColor
        if filled { ctx.setFillColor(c) }
        else { ctx.setStrokeColor(c) }
    }

    func drawPath(_ ctx: CGContext) {
        ctx.setLineCap(lineCap)
        if filled { ctx.fillPath() }
        else { ctx.strokePath() }
    }
}
