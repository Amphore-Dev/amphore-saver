import AppKit

// Mirrors web Arc.drawShape(): `nbrChilds` arcs of `arcLength` degrees evenly
// spread around the circle, starting at the current angle. Filled = pie slice.
// The path is built under translate · scale(stretch) · rotate(start) and
// stroked with the plain CTM so the stretch does not distort the line width.
final class ArcLayer: BaseLayer {
	var arcLength: CGFloat = 180

	override class var defaults: LayerDefaults {
		LayerDefaults(radius: 100, color: "#FFFFFF", filled: false, lineWidth: 10, nbrChilds: 1)
	}

	required init(data: LayerData) {
		arcLength = data.arcLength ?? 180
		super.init(data: data)
	}

	override func drawShape(in context: CGContext, screenSize: CGSize, scale: CGFloat) {
		let posX = calcPosX(screenSize: screenSize, scale: scale)
		let posY = calcPosY(screenSize: screenSize, scale: scale)
		let r = abs(radius * scale)
		// A zero scale makes the transform non-invertible (path ignored)
		let sx = max(1e-4, abs(calcStretchX()))
		let sy = max(1e-4, abs(calcStretchY()))

		// (capped: Int() traps on huge values)
		let count = Int(min(10_000, max(1, jsRound(nbrChilds.isFinite ? nbrChilds : 1))))
		let sweep = min(360, max(0, arcLength)) * .pi / 180
		let step = 2 * CGFloat.pi / CGFloat(count)
		let base = getCurrentAngle()

		for i in 0..<count {
			let start = base + CGFloat(i) * step
			let t = CGAffineTransform(translationX: posX, y: posY)
				.scaledBy(x: sx, y: sy)
				.rotated(by: start)
			let path = CGMutablePath()
			if filled { path.move(to: .zero, transform: t) }
			path.addArc(center: .zero, radius: r, startAngle: 0, endAngle: sweep,
			            clockwise: false, transform: t)
			if filled { path.closeSubpath() }
			context.beginPath()
			context.addPath(path)
			drawPath(in: context, scale: scale)
		}
	}
}
