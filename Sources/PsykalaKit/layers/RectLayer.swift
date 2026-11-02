import AppKit

// Mirrors web Rect: `width` x `height` (times stretch) rectangle centered on
// the layer position, rotated by the current angle, optional rounded corners
// (clamped to half the smallest side).
final class RectLayer: BaseLayer {
	var width: CGFloat = 200
	var height: CGFloat = 60
	var cornerRadius: CGFloat = 0

	override class var defaults: LayerDefaults {
		LayerDefaults(radius: 100, color: "#FFFFFF", filled: true, lineWidth: 5)
	}

	required init(data: LayerData) {
		width = data.width ?? 200
		height = data.height ?? 60
		cornerRadius = data.cornerRadius ?? 0
		super.init(data: data)
	}

	override func drawShape(in context: CGContext, screenSize: CGSize, scale: CGFloat) {
		let w = abs(width * scale * calcStretchX())
		let h = abs(height * scale * calcStretchY())
		let r = min(max(0, cornerRadius) * scale, min(w, h) / 2)

		let posX = calcPosX(screenSize: screenSize, scale: scale)
		let posY = calcPosY(screenSize: screenSize, scale: scale)
		let a = getCurrentAngle()
		let c = cos(a), s = sin(a)
		let corners: [(CGFloat, CGFloat)] = [(-w / 2, -h / 2), (w / 2, -h / 2), (w / 2, h / 2), (-w / 2, h / 2)]
		let points = corners.map { (x, y) in
			CGPoint(x: posX + x * c - y * s, y: posY + x * s + y * c)
		}
		drawPolygon(points, cornerRadius: r, in: context, scale: scale)
	}
}
