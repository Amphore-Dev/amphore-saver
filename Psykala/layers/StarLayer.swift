import AppKit

// Mirrors web Star: `points` tips alternating outer radius / inner radius
// (outer · innerRatio), first tip up at angle 0, sharp corners.
final class StarLayer: BaseLayer {
	var points: CGFloat = 5
	var innerRatio: CGFloat = 0.45

	override class var defaults: LayerDefaults {
		LayerDefaults(radius: 100, color: "#FFFFFF", filled: true, lineWidth: 5)
	}

	required init(data: LayerData) {
		points = data.points ?? 5
		innerRatio = data.innerRatio ?? 0.45
		super.init(data: data)
	}

	private func getPoints(posX: CGFloat, posY: CGFloat, scale: CGFloat) -> [CGPoint] {
		let count = Int(min(24, max(2, jsRound(points.isFinite ? points : 5))))
		let ratio = min(0.95, max(0.05, innerRatio))
		let outer = radius * scale
		let inner = outer * ratio
		let stretchX = calcStretchX()
		let stretchY = calcStretchY()
		// First tip points up when angle = 0
		let base = getCurrentAngle() - .pi / 2
		let step = CGFloat.pi / CGFloat(count)
		return (0..<(count * 2)).map { i in
			let r = i % 2 == 0 ? outer : inner
			let a = base + CGFloat(i) * step
			return CGPoint(x: posX + r * stretchX * cos(a), y: posY + r * stretchY * sin(a))
		}
	}

	override func drawShape(in context: CGContext, screenSize: CGSize, scale: CGFloat) {
		let pts = getPoints(posX: calcPosX(screenSize: screenSize, scale: scale),
		                    posY: calcPosY(screenSize: screenSize, scale: scale),
		                    scale: scale)
		drawPolygon(pts, cornerRadius: 0, in: context, scale: scale)
	}
}
