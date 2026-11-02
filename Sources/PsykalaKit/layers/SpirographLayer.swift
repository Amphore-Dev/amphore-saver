import AppKit

// Mirrors web Spirograph: hypotrochoid with friendly parameters
// - lobes L: number of loops around the curve
// - windings q: turns of the rolling circle before closing (coprime with L,
//   < L); rolling radius r = R·q / L
// - depth: pen distance d = depth·r (0 = circle, 1 = cusps, > 1 = loops)
// The curve is rescaled so its outer extent equals the layer radius.
private let MAX_POINTS = 2000

private func gcd(_ a: Int, _ b: Int) -> Int { b == 0 ? a : gcd(b, a % b) }

final class SpirographLayer: BaseLayer {
	var lobes: CGFloat = 5
	var windings: CGFloat = 1
	var depth: CGFloat = 0.8

	override class var defaults: LayerDefaults {
		LayerDefaults(radius: 200, color: "#FFFFFF", filled: false, lineWidth: 2)
	}

	required init(data: LayerData) {
		lobes = data.lobes ?? 5
		windings = data.windings ?? 1
		depth = data.depth ?? 0.8
		super.init(data: data)
	}

	private func getPoints(scale: CGFloat) -> [CGPoint] {
		let R = max(0.001, radius)
		let L = max(3, Int(min(1_000_000, jsRound(lobes.isFinite ? lobes : 5))))
		var q = min(L - 1, max(1, Int(min(1_000_000, jsRound(windings.isFinite ? windings : 1)))))
		while gcd(L, q) != 1 { q += 1 }
		let d = max(0, depth.isFinite ? depth : 0.8)

		let lobesF = CGFloat(L), qF = CGFloat(q)
		let r = R * qF / lobesF
		let penOffset = d * r
		let diff = R - r
		let fit = R / max(0.001, abs(diff) + penOffset)
		let freq = diff / r
		let range = 2 * CGFloat.pi * qF
		let approxLength = range * (abs(diff) + abs(penOffset * freq)) * fit * scale
		let count = min(MAX_POINTS, max(16, Int(max(approxLength / 3, qF * (abs(freq) + 1) * 24).rounded(.up))))

		let base = getCurrentAngle()
		let c = cos(base), s = sin(base)
		let stretchX = calcStretchX()
		let stretchY = calcStretchY()

		return (0..<count).map { i in
			let theta = range * CGFloat(i) / CGFloat(count)
			let x = (diff * cos(theta) + penOffset * cos(freq * theta)) * fit * scale
			let y = (diff * sin(theta) - penOffset * sin(freq * theta)) * fit * scale
			return CGPoint(x: (x * c - y * s) * stretchX, y: (x * s + y * c) * stretchY)
		}
	}

	override func drawShape(in context: CGContext, screenSize: CGSize, scale: CGFloat) {
		let posX = calcPosX(screenSize: screenSize, scale: scale)
		let posY = calcPosY(screenSize: screenSize, scale: scale)
		let pts = getPoints(scale: scale)
		guard let first = pts.first else { return }
		let path = CGMutablePath()
		path.move(to: CGPoint(x: posX + first.x, y: posY + first.y))
		for p in pts.dropFirst() { path.addLine(to: CGPoint(x: posX + p.x, y: posY + p.y)) }
		path.closeSubpath()
		context.beginPath()
		context.addPath(path)
		drawPath(in: context, scale: scale)
	}
}
