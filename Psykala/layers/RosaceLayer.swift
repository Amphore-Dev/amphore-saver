import AppKit

// Mirrors web Rosace.draw() exactly:
// step = π / nbrChilds  (loop increment)
// childAngle += π / (nbrChilds / 2)  (= 2π / nbrChilds, angle increment)
// circle center: (posX + radius * stretchX * cos, posY + radius * stretchY * sin)
// circle radius: childSize (= childSize || radius in web)
final class RosaceLayer: BaseLayer {
    override func drawContent(in context: CGContext, screenSize: CGSize, scale: CGFloat) {

        let posX = calcPosX(screenSize: screenSize, scale: scale)
        let posY = calcPosY(screenSize: screenSize, scale: scale)
        let _radius = radius * scale
        let _childSize = (childSize > 0 ? childSize : radius) * scale
        let _lineWidth = lineWidth * scale
        let n = CGFloat(nbrChilds)
        let step = CGFloat.pi / n
        let angleStep = CGFloat.pi / (n / 2)
        var childAngle = getCurrentAngle()

        var i: CGFloat = 0
        while i < 2 * .pi {
            let cx = posX + _radius * stretch.x * cos(childAngle)
            let cy = posY + _radius * stretch.y * sin(childAngle)
            let rect = CGRect(x: cx - _childSize, y: cy - _childSize,
                              width: 2 * _childSize, height: 2 * _childSize)
            if filled {
                context.fillEllipse(in: rect)
            } else {
                context.setLineWidth(_lineWidth)
                context.strokeEllipse(in: rect)
            }
            childAngle += angleStep
            i += step
        }
    }
}
