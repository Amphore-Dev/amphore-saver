import AppKit

struct LayerPoint {
	var x: CGFloat
	var y: CGFloat
}

enum LayerType: CaseIterable {
    case circle, rosace, line, background
}


struct LayerData {
	var id: String
	var type: LayerType
	var name: String
	var radius: CGFloat
	var rotation: CGFloat?
	var rotationSpeed: CGFloat?
	var angle: CGFloat?
	var color: String
	var filled: Bool?
	var lineWidth: CGFloat?
	var nbrChilds: Int?
	var childSize: CGFloat?
	var childAngle: CGFloat?
	var childRotation: CGFloat?
	var childRotationSpeed: CGFloat?
	var hasMask: Bool?
	var maskRadius: CGFloat?
	var maskX: CGFloat?
	var maskY: CGFloat?
	var offset: LayerPoint?
	var layerScale: CGFloat?
	var stretch: LayerPoint?
}
