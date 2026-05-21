import AppKit

final class CircleLayer: BaseLayer {
	override func drawContent(in context: CGContext, screenSize: CGSize, scale: CGFloat) {
		let posX = calcPosX(screenSize: screenSize, scale: scale)
		let posY = calcPosY(screenSize: screenSize, scale: scale)
		let _radius = radius * scale
		let _lineWidth = lineWidth * scale
		
		if filled {
			context.fillEllipse(in: CGRect(x: posX - _radius, y: posY - _radius, width: 2 * _radius, height: 2 * _radius))
		} else {
			context.setLineWidth(_lineWidth)
			context.strokeEllipse(in: CGRect(x: posX - _radius, y: posY - _radius, width: 2 * _radius, height: 2 * _radius))
		}
	}
}
