import AppKit

// Web Circle: the BaseLayer default shape (circle of `radius`, no stretch).
final class CircleLayer: BaseLayer {
	override class var defaults: LayerDefaults {
		LayerDefaults(radius: 250, color: "#FFFF00", filled: false, lineWidth: 2)
	}
}
