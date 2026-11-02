import AppKit

final class TriangleShadeItem: ShadeItem {
    override func draw(_ ctx: CGContext, _ config: ShadeConfig, _ offset: ShadePoint) {
        for i in 0..<config.nbrShades {
            setColors(ctx, config.gradRatio, i)
            let factor = 1 - (config.gradRatio * CGFloat(i)) / 100
            let cx = config.center.x + (position.x - config.totalWidth / 2 + config.width / 2) + offset.x * factor
            let cy = config.center.y + (position.y - config.totalHeight / 2 + config.width / 2) + offset.y * factor
            let w = config.width

            ctx.beginPath()
            ctx.move(to: CGPoint(x: cx + cos(angle) * w, y: cy + sin(angle) * w))
            ctx.addLine(to: CGPoint(x: cx + cos(angle + 2 * .pi / 3) * w,
                                    y: cy + sin(angle + 2 * .pi / 3) * w))
            ctx.addLine(to: CGPoint(x: cx + cos(angle + 4 * .pi / 3) * w,
                                    y: cy + sin(angle + 4 * .pi / 3) * w))
            ctx.closePath()
            drawPath(ctx)

            if rotation {
                angle += (0.3 / CGFloat(config.nbrShades)) * .pi / 180
            }
        }
    }
}
