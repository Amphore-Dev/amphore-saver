import AppKit

final class LineLayer: BaseLayer {

    private func getStep() -> CGFloat {
        return .pi / (CGFloat(nbrChilds) / 2)
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

    override func drawContent(in context: CGContext, screenSize: CGSize, scale: CGFloat) {

        let _lineWidth = lineWidth * scale
       
	    let step = getStep()
        let childOffset = getChildAngle()
       
	    var curAngle = getCurrentAngle()
       
        let _radius = radius * scale
        let _childSize = (childSize > 0 ? childSize : radius) * scale
	    let posX = calcPosX(screenSize: screenSize, scale: scale)
        let posY = calcPosY(screenSize: screenSize, scale: scale)
		let stretchX = calcStretchX()
        let stretchY = calcStretchY()


        context.setLineWidth(_lineWidth)

        var i: CGFloat = 0
        while i < 2 * .pi {
            let (x1, y1, x2, y2) = calcChildEndpoints(
                posX: posX, posY: posY,
                angle: curAngle, childOffset: childOffset,
                radius: _radius + (_childSize / 2), childSize: _childSize,
                stretchX: stretchX, stretchY: stretchY
            )
            context.beginPath()
            context.move(to: CGPoint(x: x1, y: y1))
            context.addLine(to: CGPoint(x: x2, y: y2))
            context.strokePath()
            curAngle += step
            i += step
        }
    }
}
