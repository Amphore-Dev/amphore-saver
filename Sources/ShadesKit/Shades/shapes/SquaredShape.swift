import AppKit

final class SquaredShadeItem: ShadeItem {
    override func draw(_ ctx: CGContext, _ config: ShadeConfig, _ offset: ShadePoint) {
        for i in 0..<config.nbrShades {
            setColors(ctx, config.gradRatio, i)
            let factor = 1 - (config.gradRatio * CGFloat(i)) / 100
            let rect = CGRect(
                x: config.center.x + (position.x - config.totalWidth / 2) + offset.x * factor,
                y: config.center.y + (position.y - config.totalHeight / 2) + offset.y * factor,
                width: config.width,
                height: config.height
            )
            ctx.beginPath()
            ctx.addRect(rect)
            drawPath(ctx)
        }
    }
}
