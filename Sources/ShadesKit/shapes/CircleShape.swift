import AppKit

final class CircleShadeItem: ShadeItem {
    override func draw(_ ctx: CGContext, _ config: ShadeConfig, _ offset: ShadePoint) {
        for i in 0..<config.nbrShades {
            setColors(ctx, config.gradRatio, i)
            let factor = 1 - (config.gradRatio * CGFloat(i)) / 100
            let cx = config.center.x + (position.x - config.totalWidth / 2 + config.width / 2) + offset.x * factor
            let cy = config.center.y + (position.y - config.totalHeight / 2 + config.width / 2) + offset.y * factor
            let r = config.width / 2
            ctx.beginPath()
            ctx.addEllipse(in: CGRect(x: cx - r, y: cy - r, width: config.width, height: config.width))
            drawPath(ctx)
        }
    }
}
