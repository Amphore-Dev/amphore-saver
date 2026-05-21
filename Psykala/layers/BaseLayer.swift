import AppKit

class BaseLayer {
   var id: String
   var type: LayerType
   var name: String
   var radius: CGFloat = 100
   var rotation: CGFloat = 0
   var rotationSpeed: CGFloat = 0
   var angle: CGFloat = 0
   var color: String = "#FFFFFF"
   var filled: Bool = false
   var lineWidth: CGFloat = 1
   var nbrChilds: Int = 1
   var childSize: CGFloat = 1
   var childAngle: CGFloat = 0
   var childRotation: CGFloat = 0
   var childRotationSpeed: CGFloat = 0
   var offset: LayerPoint = LayerPoint(x: 0, y: 0)
   var layerScale: CGFloat = 1
   var stretch: LayerPoint = LayerPoint(x: 1, y: 1)
   var hasMask: Bool = false
   var maskRadius: CGFloat = 100
   var maskX: CGFloat = 0
   var maskY: CGFloat = 0

   init(id: String, type: LayerType, name: String, radius: CGFloat,
        rotation: CGFloat = 0, rotationSpeed: CGFloat = 0, angle: CGFloat = 0,
        color: String, filled: Bool = false, lineWidth: CGFloat = 1,
        nbrChilds: Int = 1, childSize: CGFloat = 1,
        childAngle: CGFloat = 0, childRotationSpeed: CGFloat = 0,
        offset: LayerPoint = LayerPoint(x: 0, y: 0), layerScale: CGFloat = 1,
        stretch: LayerPoint = LayerPoint(x: 1, y: 1),
        hasMask: Bool = false, maskRadius: CGFloat = 100,
        maskX: CGFloat = 0, maskY: CGFloat = 0) {
      self.id = id
      self.type = type
      self.name = name
      self.radius = radius
      self.rotation = rotation
      self.rotationSpeed = rotationSpeed
      self.angle = angle
      self.color = color
      self.filled = filled
      self.lineWidth = lineWidth
      self.nbrChilds = nbrChilds
      self.childSize = childSize
      self.childAngle = childAngle
      self.childRotationSpeed = childRotationSpeed
      self.offset = offset
      self.layerScale = layerScale
      self.stretch = stretch
      self.hasMask = hasMask
      self.maskRadius = maskRadius
      self.maskX = maskX
      self.maskY = maskY
   }

   func calcPosX(screenSize: CGSize, scale: CGFloat) -> CGFloat {
      return screenSize.width / 2 + offset.x * scale
   }

   func calcPosY(screenSize: CGSize, scale: CGFloat) -> CGFloat {
      return screenSize.height / 2 + offset.y * scale
   }

   func calcStretchX() -> CGFloat { return stretch.x }
   func calcStretchY() -> CGFloat { return stretch.y }

   public func getCurrentAngle() -> CGFloat {
      return -(rotation + angle) / (180 / .pi)
   }

   public func getChildAngle() -> CGFloat {
      return -(childRotation + childAngle) / (180 / .pi)
   }

   public func update(dt: CFTimeInterval) {
      rotation += rotationSpeed * CGFloat(dt)
      childRotation += childRotationSpeed * CGFloat(dt)
   }

   public func draw(in context: CGContext, screenSize: CGSize, scale: CGFloat) {
      setColor(in: context)
      if hasMask {
         let mx = screenSize.width / 2 + maskX * scale
         let my = screenSize.height / 2 + maskY * scale
         let mr = maskRadius * scale
         context.saveGState()
         context.beginPath()
         context.addEllipse(in: CGRect(x: mx - mr, y: my - mr, width: 2 * mr, height: 2 * mr))
         context.clip()
         drawContent(in: context, screenSize: screenSize, scale: scale)
         context.restoreGState()
      } else {
         drawContent(in: context, screenSize: screenSize, scale: scale)
      }
   }

   func drawContent(in context: CGContext, screenSize: CGSize, scale: CGFloat) {}

   public func setColor(in context: CGContext) {
      let cgColor = CGColor.fromHex(self.color)
      context.setStrokeColor(cgColor)
      context.setFillColor(cgColor)
   }

   static func make(from data: LayerData) -> BaseLayer {
      let offset = data.offset ?? LayerPoint(x: 0, y: 0)
      let stretch = data.stretch ?? LayerPoint(x: 1, y: 1)
      let layer: BaseLayer
      switch data.type {
      case .circle:
         layer = CircleLayer(id: data.id, type: data.type, name: data.name, radius: data.radius,
            rotation: data.rotation ?? 0, rotationSpeed: data.rotationSpeed ?? 0,
            angle: data.angle ?? 0, color: data.color, filled: data.filled ?? false,
            lineWidth: data.lineWidth ?? 1, nbrChilds: data.nbrChilds ?? 1,
            childSize: data.childSize ?? 1, offset: offset, layerScale: data.layerScale ?? 1,
            stretch: stretch, hasMask: data.hasMask ?? false,
            maskRadius: data.maskRadius ?? 100, maskX: data.maskX ?? 0, maskY: data.maskY ?? 0)
      case .rosace:
         layer = RosaceLayer(id: data.id, type: data.type, name: data.name, radius: data.radius,
            rotation: data.rotation ?? 0, rotationSpeed: data.rotationSpeed ?? 0,
            angle: data.angle ?? 0, color: data.color, filled: data.filled ?? false,
            lineWidth: data.lineWidth ?? 1, nbrChilds: data.nbrChilds ?? 6,
            childSize: data.childSize ?? data.radius, offset: offset, layerScale: data.layerScale ?? 1,
            stretch: stretch, hasMask: data.hasMask ?? false,
            maskRadius: data.maskRadius ?? 100, maskX: data.maskX ?? 0, maskY: data.maskY ?? 0)
      case .line:
         layer = LineLayer(id: data.id, type: data.type, name: data.name, radius: data.radius,
            rotation: data.rotation ?? 0, rotationSpeed: data.rotationSpeed ?? 0,
            angle: data.angle ?? 0, color: data.color, filled: data.filled ?? false,
            lineWidth: data.lineWidth ?? 1, nbrChilds: data.nbrChilds ?? 6,
            childSize: data.childSize ?? data.radius * 0.5,
            childAngle: data.childAngle ?? 0, childRotationSpeed: data.childRotationSpeed ?? 0,
            offset: offset, layerScale: data.layerScale ?? 1, stretch: stretch,
            hasMask: data.hasMask ?? false, maskRadius: data.maskRadius ?? 100,
            maskX: data.maskX ?? 0, maskY: data.maskY ?? 0)
      case .background:
         layer = BackgroundLayer(id: data.id, type: data.type, name: data.name, radius: data.radius,
            rotation: 0, rotationSpeed: 0, angle: 0, color: data.color, filled: true,
            lineWidth: 1, nbrChilds: 1, childSize: 1, offset: offset, layerScale: 1,
            stretch: LayerPoint(x: 1, y: 1))
      }
      return layer
   }
}
