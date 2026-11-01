import AppKit

// Mirrors web Line.drawShape(): one segment per child, placed on the radius
// and rotated around its midpoint by the child angle. Never filled.
final class LineLayer: BaseLayer {
    override class var defaults: LayerDefaults {
        LayerDefaults(radius: 100, color: "#FFFFFF", filled: false, lineWidth: 1,
                      nbrChilds: 6, childSize: 50)
    }

    required init(data: LayerData) {
        super.init(data: data)
        filled = false
    }

    private func getStep() -> CGFloat {
        return .pi / (nbrChilds / 2)
    }

    private func calcChildEndpoints(
        posX: CGFloat, posY: CGFloat,
        angle: CGFloat, childOffset: CGFloat,
        radius: CGFloat, childSize: CGFloat,
        stretchX: CGFloat, stretchY: CGFloat
    ) -> (x1: CGFloat, y1: CGFloat, x2: CGFloat, y2: CGFloat) {
        let midDist = radius - childSize / 2
        let mx = posX + midDist * stretchX * cos(angle)
        let my = posY + midDist * stretchY * sin(angle)

        let vx = (childSize / 2) * stretchX * cos(angle)
        let vy = (childSize / 2) * stretchY * sin(angle)

        let cosO = cos(childOffset)
        let sinO = sin(childOffset)
        let rx = vx * cosO - vy * sinO
        let ry = vx * sinO + vy * cosO

        return (mx + rx, my + ry, mx - rx, my - ry)
    }

    override func drawShape(in context: CGContext, screenSize: CGSize, scale: CGFloat) {
        let step = getStep()
        // Negative / NaN step would never end the loop (nbrChilds = 0 gives an
        // infinite step: a single line, like the web)
        guard step > 0 else { return }
        let childOffset = getChildAngle()
        var curAngle = getCurrentAngle()

        let _radius = radius * scale
        let _childSize = (childSize != 0 ? childSize : radius) * scale
        let posX = calcPosX(screenSize: screenSize, scale: scale)
        let posY = calcPosY(screenSize: screenSize, scale: scale)
        let stretchX = calcStretchX()
        let stretchY = calcStretchY()

        var i: CGFloat = 0
        var guardCount = 0
        while i < 2 * .pi && guardCount < 10_000 {
            guardCount += 1
            let (x1, y1, x2, y2) = calcChildEndpoints(
                posX: posX, posY: posY,
                angle: curAngle, childOffset: childOffset,
                radius: _radius + _childSize / 2, childSize: _childSize,
                stretchX: stretchX, stretchY: stretchY
            )
            context.beginPath()
            context.move(to: CGPoint(x: x1, y: y1))
            context.addLine(to: CGPoint(x: x2, y: y2))
            drawPath(in: context, scale: scale)
            curAngle += step
            i += step
        }
    }
}
