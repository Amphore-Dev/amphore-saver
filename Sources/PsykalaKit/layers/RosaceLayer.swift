import AppKit

// Mirrors web Rosace.drawShape():
// - whole nbrChilds: exactly one circle per child (the legacy loop drew each twice)
// - fractional nbrChilds: ceil(2·n) distinct circles (legacy look over two turns)
// - spacing 2π / nbrChilds, circle centers on the (stretched) radius,
//   circle radius = childSize || radius (circles themselves are not stretched)
final class RosaceLayer: BaseLayer {
	override class var defaults: LayerDefaults {
		LayerDefaults(radius: 100, color: "#FFFFFF", filled: false, lineWidth: 5,
		              nbrChilds: 6, childSize: 100)
	}

	private func getChildCount() -> Int {
		let n = nbrChilds
		guard n.isFinite else { return 1 }
		// Capped: Int() traps on huge values
		if n == n.rounded() { return Int(min(10_000, max(1, n))) }
		return Int(min(10_000, max(1, (2 * n - 1e-9).rounded(.up))))
	}

	override func drawShape(in context: CGContext, screenSize: CGSize, scale: CGFloat) {
		let posX = calcPosX(screenSize: screenSize, scale: scale)
		let posY = calcPosY(screenSize: screenSize, scale: scale)
		let _radius = radius * scale
		let size = (childSize != 0 ? childSize : radius) * scale
		guard size >= 0 else { return } // canvas arc() rejects negative radii
		let count = getChildCount()
		let spacing = 2 * CGFloat.pi / nbrChilds
		let stretchX = calcStretchX()
		let stretchY = calcStretchY()
		var childAngle = getCurrentAngle()

		for _ in 0..<count {
			let center = CGPoint(x: posX + _radius * stretchX * cos(childAngle),
			                     y: posY + _radius * stretchY * sin(childAngle))
			context.beginPath()
			context.addArc(center: center, radius: size, startAngle: 0, endAngle: 2 * .pi, clockwise: false)
			drawPath(in: context, scale: scale)
			childAngle += spacing
		}
	}
}
