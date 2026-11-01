import AppKit

// Mirrors web Polygon (PolygonLayer.tsx): regular polygon of `sides` vertices
// (first vertex up at angle 0) with optional rounded corners, sharp corners
// kept sharp with a dynamic miter limit. The rounded-polygon helpers are
// shared with Star and Rect.

private let EPSILON: CGFloat = 1e-6

struct RoundedCorner {
	var p: CGPoint
	// Tangent points on the incoming / outgoing edges (only when r > 0)
	var from: CGPoint
	var to: CGPoint
	var r: CGFloat
}

/// For each vertex of a closed polygon, the circular arc rounding it with the
/// given radius (same geometry as canvas arcTo), clamped so two neighbouring
/// corners never overlap on a shared edge.
func computeRoundedCorners(_ points: [CGPoint], cornerRadius: CGFloat) -> [RoundedCorner] {
	let n = points.count
	return points.enumerated().map { (i, p) in
		let flat = RoundedCorner(p: p, from: p, to: p, r: 0)
		if cornerRadius <= 0 { return flat }
		let a = points[(i - 1 + n) % n]
		let b = points[(i + 1) % n]
		let v1x = a.x - p.x, v1y = a.y - p.y
		let v2x = b.x - p.x, v2y = b.y - p.y
		let l1 = hypot(v1x, v1y), l2 = hypot(v2x, v2y)
		if l1 < EPSILON || l2 < EPSILON { return flat }

		let c = min(1, max(-1, (v1x * v2x + v1y * v2y) / (l1 * l2)))
		let halfAngle = acos(c) / 2
		let tanHalf = tan(halfAngle)
		// Spike (angle ~0) or straight line (angle ~PI): nothing to round
		if tanHalf < EPSILON || halfAngle > .pi / 2 - EPSILON { return flat }

		let t = min(cornerRadius / tanHalf, min(l1, l2) / 2)
		return RoundedCorner(
			p: p,
			from: CGPoint(x: p.x + (v1x / l1) * t, y: p.y + (v1y / l1) * t),
			to: CGPoint(x: p.x + (v2x / l2) * t, y: p.y + (v2y / l2) * t),
			r: t * tanHalf)
	}
}

/// Port of traceRoundedPolygon (canvas space: arc(anticlockwise) -> clockwise).
func roundedPolygonPath(_ points: [CGPoint], cornerRadius: CGFloat) -> CGPath {
	let path = CGMutablePath()
	for (i, c) in computeRoundedCorners(points, cornerRadius: cornerRadius).enumerated() {
		if c.r <= 0 {
			if i == 0 { path.move(to: c.p) } else { path.addLine(to: c.p) }
			continue
		}
		// Explicit arc from its center (never adds a zero-length segment)
		let bx = (c.from.x - c.p.x + c.to.x - c.p.x) / 2
		let by = (c.from.y - c.p.y + c.to.y - c.p.y) / 2
		let bl = hypot(bx, by)
		let toFrom = hypot(c.from.x - c.p.x, c.from.y - c.p.y)
		let dist = hypot(toFrom, c.r)
		let cx = c.p.x + (bx / bl) * dist
		let cy = c.p.y + (by / bl) * dist
		let start = atan2(c.from.y - cy, c.from.x - cx)
		let end = atan2(c.to.y - cy, c.to.x - cx)
		var delta = end - start
		while delta <= -.pi { delta += 2 * .pi }
		while delta > .pi { delta -= 2 * .pi }
		if i == 0 { path.move(to: c.from) }
		// addArc joins the previous point with a straight line itself
		path.addArc(center: CGPoint(x: cx, y: cy), radius: c.r,
		            startAngle: start, endAngle: end, clockwise: delta < 0)
	}
	path.closeSubpath()
	return path
}

/// Miter limit large enough for the sharpest corner, so corners always stay
/// sharp instead of switching to a bevel past the default limit (10).
func miterLimitFor(_ points: [CGPoint]) -> CGFloat {
	let n = points.count
	var limit: CGFloat = 10
	for (i, p) in points.enumerated() {
		let a = points[(i - 1 + n) % n]
		let b = points[(i + 1) % n]
		let v1x = a.x - p.x, v1y = a.y - p.y
		let v2x = b.x - p.x, v2y = b.y - p.y
		let l = hypot(v1x, v1y) * hypot(v2x, v2y)
		if l < EPSILON { continue }
		let angle = acos(min(1, max(-1, (v1x * v2x + v1y * v2y) / l)))
		let half = sin(angle / 2)
		if half > EPSILON { limit = max(limit, 1 / half + 1) }
	}
	return limit
}

extension BaseLayer {
	/// Fills / strokes a closed (optionally rounded) polygon with sharp miters.
	func drawPolygon(_ points: [CGPoint], cornerRadius: CGFloat, in context: CGContext, scale: CGFloat) {
		guard points.count >= 2 else { return }
		context.beginPath()
		context.addPath(roundedPolygonPath(points, cornerRadius: cornerRadius))
		context.saveGState()
		context.setMiterLimit(miterLimitFor(points))
		drawPath(in: context, scale: scale)
		context.restoreGState()
	}
}

final class PolygonLayer: BaseLayer {
	var sides: CGFloat = 6
	var cornerRadius: CGFloat = 0

	override class var defaults: LayerDefaults {
		LayerDefaults(radius: 100, color: "#FFFFFF", filled: false, lineWidth: 5)
	}

	required init(data: LayerData) {
		sides = data.sides ?? 6
		cornerRadius = data.cornerRadius ?? 0
		super.init(data: data)
	}

	private func getPoints(posX: CGFloat, posY: CGFloat, scale: CGFloat) -> [CGPoint] {
		let count = Int(min(24, max(3, jsRound(sides.isFinite ? sides : 6))))
		let r = radius * scale
		let stretchX = calcStretchX()
		let stretchY = calcStretchY()
		// First vertex points up when angle = 0
		let base = getCurrentAngle() - .pi / 2
		let step = 2 * CGFloat.pi / CGFloat(count)
		return (0..<count).map { i in
			let a = base + CGFloat(i) * step
			return CGPoint(x: posX + r * stretchX * cos(a), y: posY + r * stretchY * sin(a))
		}
	}

	override func drawShape(in context: CGContext, screenSize: CGSize, scale: CGFloat) {
		let points = getPoints(posX: calcPosX(screenSize: screenSize, scale: scale),
		                       posY: calcPosY(screenSize: screenSize, scale: scale),
		                       scale: scale)
		drawPolygon(points, cornerRadius: max(0, cornerRadius) * scale, in: context, scale: scale)
	}
}
