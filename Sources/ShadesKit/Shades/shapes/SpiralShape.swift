import AppKit

final class SpiralShadeItem: ShadeItem {
    override func draw(_ ctx: CGContext, _ config: ShadeConfig, _ offset: ShadePoint) {
        for i in 0..<config.nbrShades {
            setColors(ctx, config.gradRatio, i)
            let factor = 1 - (config.gradRatio * CGFloat(i)) / 100
            let cx = config.center.x + (position.x - config.totalWidth / 2 + config.width / 2) + offset.x * factor
            let cy = config.center.y + (position.y - config.totalHeight / 2 + config.width / 2) + offset.y * factor
            let r = config.width / 2
            let startAngle = angle + CGFloat(config.nbrShades - i) * 8 * .pi / 180
            let endAngle = angle + CGFloat(180 + (config.nbrShades - i) * 8) * .pi / 180

            ctx.beginPath()
            ctx.addArc(center: CGPoint(x: cx, y: cy), radius: r,
                       startAngle: startAngle, endAngle: endAngle, clockwise: false)
            drawPath(ctx)

            if rotation {
                angle += (2 / CGFloat(config.nbrShades)) * .pi / 180
            }
        }
    }
}
