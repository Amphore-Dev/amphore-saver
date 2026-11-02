import AppKit

struct LayerPoint {
	var x: CGFloat
	var y: CGFloat
}

enum LayerType: CaseIterable {
	case circle, rosace, line, arc, polygon, star, rect, spirograph, background

	/// Maps an API / .psk type name. Unknown types return nil (layer skipped).
	init?(apiName: String) {
		switch apiName.trimmingCharacters(in: .whitespaces).lowercased() {
		case "circle": self = .circle
		case "rose", "rosace": self = .rosace
		case "line": self = .line
		case "arc": self = .arc
		case "polygon": self = .polygon
		case "star": self = .star
		case "rect": self = .rect
		case "spirograph": self = .spirograph
		case "background": self = .background
		default: return nil
		}
	}
}

/// Raw layer values as stored by the web app. Every field except id/type is
/// optional: defaults are resolved per layer type in BaseLayer (same defaults
/// as the web constructors and CLAYER_EFFECTS_DEFAULTS).
struct LayerData {
	var id: String
	var type: LayerType
	var name: String = ""
	var visible: Bool? = nil
	var radius: CGFloat? = nil
	var rotation: CGFloat? = nil
	var rotationSpeed: CGFloat? = nil
	var angle: CGFloat? = nil
	var color: String? = nil
	var filled: Bool? = nil
	var lineWidth: CGFloat? = nil
	var nbrChilds: CGFloat? = nil
	var childSize: CGFloat? = nil
	var childAngle: CGFloat? = nil
	var childRotation: CGFloat? = nil
	var childRotationSpeed: CGFloat? = nil
	var hasMask: Bool? = nil
	var maskRadius: CGFloat? = nil
	var maskX: CGFloat? = nil
	var maskY: CGFloat? = nil
	var offset: LayerPoint? = nil
	var layerScale: CGFloat? = nil
	var stretch: LayerPoint? = nil

	// Shape specific
	var arcLength: CGFloat? = nil
	var sides: CGFloat? = nil
	var cornerRadius: CGFloat? = nil
	var points: CGFloat? = nil
	var innerRatio: CGFloat? = nil
	var width: CGFloat? = nil
	var height: CGFloat? = nil
	var lobes: CGFloat? = nil
	var windings: CGFloat? = nil
	var depth: CGFloat? = nil

	// Cross-cutting effects
	var blendMode: String? = nil
	var dashLength: CGFloat? = nil
	var dashGap: CGFloat? = nil
	var dashSpeed: CGFloat? = nil
	var roundCap: Bool? = nil
	var pulseAmount: CGFloat? = nil
	var pulseSpeed: CGFloat? = nil
	var pulseEasing: String? = nil
	var gridCols: CGFloat? = nil
	var gridRows: CGFloat? = nil
	var gridSpacingX: CGFloat? = nil
	var gridSpacingY: CGFloat? = nil
	var gridAngleStep: CGFloat? = nil
	var gridAngleMode: String? = nil
}
