import AppKit

// Web BackgroundLayer: plain fill of the whole screen, no effect, no mask.
final class BackgroundLayer: BaseLayer {
	override class var defaults: LayerDefaults {
		LayerDefaults(radius: 100, color: "#000000", filled: true, lineWidth: 2)
	}

	required init(data: LayerData) {
		var d = data
		// `values?.color || "#000000"`: an empty color falls back to black
		if d.color?.isEmpty ?? true { d.color = "#000000" }
		super.init(data: d)
	}

	override func draw(in context: CGContext, screenSize: CGSize, scale: CGFloat) {
		context.setFillColor(color)
		context.fill(CGRect(origin: .zero, size: screenSize))
	}
}
