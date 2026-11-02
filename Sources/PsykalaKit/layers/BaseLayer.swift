import AppKit

// Port of the web BaseLayer (Psykala/src/classes/Layers/BaseLayer.ts).
//
// Coordinate convention: layers are drawn in the web canvas space. The scene
// renderer flips the CTM (origin top-left, y pointing down) before drawing, so
// every shape uses the web formulas verbatim: positive angles turn clockwise
// on screen and position.y > 0 is below the center, exactly like the canvas.
// Consequence for paths: canvas `arc(..., anticlockwise)` maps to
// CG `addArc(..., clockwise: anticlockwise)` in this flipped space.

enum PulseEasing {
   case sine, linear, easeIn, easeOut, easeInOut

   init(_ name: String?) {
      switch name {
      case "linear": self = .linear
      case "easeIn": self = .easeIn
      case "easeOut": self = .easeOut
      case "easeInOut": self = .easeInOut
      default: self = .sine
      }
   }
}

enum GridAngleMode {
   case diagonal, radial, row

   init(_ name: String?) {
      switch name {
      case "radial": self = .radial
      case "row": self = .row
      default: self = .diagonal
      }
   }
}

/// Defaults of the per-type web constructors (BaseLayer values + subclass defaults).
struct LayerDefaults {
   var radius: CGFloat = 100
   var color: String = "#FFFFFF"
   var filled: Bool = false
   var lineWidth: CGFloat = 2
   var nbrChilds: CGFloat = 1
   var childSize: CGFloat = 0
}

/// CLAYER_EFFECTS_DEFAULTS
enum LayerEffectsDefaults {
   static let dashLength: CGFloat = 0
   static let dashGap: CGFloat = 10
   static let dashSpeed: CGFloat = 0
   static let pulseAmount: CGFloat = 0
   static let pulseSpeed: CGFloat = 0.5
   static let gridCols: CGFloat = 1
   static let gridRows: CGFloat = 1
   static let gridSpacingX: CGFloat = 200
   static let gridSpacingY: CGFloat = 200
   static let gridAngleStep: CGFloat = 0
}

/// Canvas globalCompositeOperation -> CoreGraphics blend mode.
func cgBlendMode(fromCanvas name: String?) -> CGBlendMode {
   switch name {
   case "screen": return .screen
   case "lighter": return .plusLighter
   case "multiply": return .multiply
   case "difference": return .difference
   case "exclusion": return .exclusion
   case "overlay": return .overlay
   case "xor": return .xor
   case "destination-out": return .destinationOut
   // Not offered by the editor UI, but valid canvas operations
   case "darken": return .darken
   case "lighten": return .lighten
   case "color-dodge": return .colorDodge
   case "color-burn": return .colorBurn
   case "hard-light": return .hardLight
   case "soft-light": return .softLight
   case "hue": return .hue
   case "saturation": return .saturation
   case "color": return .color
   case "luminosity": return .luminosity
   case "source-in": return .sourceIn
   case "source-out": return .sourceOut
   case "source-atop": return .sourceAtop
   case "destination-over": return .destinationOver
   case "destination-in": return .destinationIn
   case "destination-atop": return .destinationAtop
   case "copy": return .copy
   default: return .normal // "source-over" and unknown values (ignored by canvas)
   }
}

private let maxGridCellsPerAxis: CGFloat = 50

struct GridCell {
   // Offset from the layer position, in layer units (multiplied by scale when drawn)
   var dx: CGFloat
   var dy: CGFloat
   // Degrees added to the layer angle for this cell
   var angleOffset: CGFloat
}

/// JS Math.round (halves round toward +infinity)
@inline(__always) func jsRound(_ v: CGFloat) -> CGFloat { (v + 0.5).rounded(.down) }

class BaseLayer {
   let id: String
   let type: LayerType
   let name: String
   var radius: CGFloat = 100
   var rotation: CGFloat = 0
   var rotationSpeed: CGFloat = 0
   var angle: CGFloat = 0
   var color: CGColor = CGColor(red: 1, green: 1, blue: 1, alpha: 1)
   var filled: Bool = false
   var lineWidth: CGFloat = 2
   var nbrChilds: CGFloat = 1
   var childSize: CGFloat = 0
   var childAngle: CGFloat = 0
   var childRotation: CGFloat = 0
   var childRotationSpeed: CGFloat = 0
   var offset = LayerPoint(x: 0, y: 0)
   var stretch = LayerPoint(x: 1, y: 1)
   var hasMask: Bool = false
   var maskRadius: CGFloat = 100
   var maskX: CGFloat = 0
   var maskY: CGFloat = 0

   // Cross-cutting effects
   var blendMode: CGBlendMode = .normal
   var dashLength: CGFloat = LayerEffectsDefaults.dashLength
   var dashGap: CGFloat = LayerEffectsDefaults.dashGap
   var dashSpeed: CGFloat = LayerEffectsDefaults.dashSpeed
   var roundCap: Bool = false
   var pulseAmount: CGFloat = LayerEffectsDefaults.pulseAmount
   var pulseSpeed: CGFloat = LayerEffectsDefaults.pulseSpeed
   var pulseEasing: PulseEasing = .sine
   private(set) var gridCells: [GridCell] = [GridCell(dx: 0, dy: 0, angleOffset: 0)]

   // Runtime-only animation state (never persisted)
   private var dashOffset: CGFloat = 0 // px travelled by the dashes along the path
   private var pulsePhase: CGFloat = 0 // radians
   // Temporary angle (degrees) added while drawing a grid cell
   private var angleOffset: CGFloat = 0

   class var defaults: LayerDefaults { LayerDefaults() }

   required init(data: LayerData) {
      id = data.id
      type = data.type
      name = data.name
      let def = Swift.type(of: self).defaults

      radius = data.radius ?? def.radius
      rotation = data.rotation ?? 0
      rotationSpeed = data.rotationSpeed ?? 0
      angle = data.angle ?? 0
      color = CGColor.fromHex(data.color ?? def.color)
      filled = data.filled ?? def.filled
      lineWidth = data.lineWidth ?? def.lineWidth
      nbrChilds = data.nbrChilds ?? def.nbrChilds
      childSize = data.childSize ?? def.childSize
      childAngle = data.childAngle ?? 0
      childRotation = data.childRotation ?? 0
      childRotationSpeed = data.childRotationSpeed ?? 0
      offset = data.offset ?? LayerPoint(x: 0, y: 0)
      stretch = data.stretch ?? LayerPoint(x: 1, y: 1)
      hasMask = data.hasMask ?? false
      maskRadius = data.maskRadius ?? 100
      maskX = data.maskX ?? 0
      maskY = data.maskY ?? 0

      blendMode = cgBlendMode(fromCanvas: data.blendMode)
      dashLength = data.dashLength ?? LayerEffectsDefaults.dashLength
      dashGap = data.dashGap ?? LayerEffectsDefaults.dashGap
      dashSpeed = data.dashSpeed ?? LayerEffectsDefaults.dashSpeed
      roundCap = data.roundCap == true
      pulseAmount = data.pulseAmount ?? LayerEffectsDefaults.pulseAmount
      pulseSpeed = data.pulseSpeed ?? LayerEffectsDefaults.pulseSpeed
      pulseEasing = PulseEasing(data.pulseEasing)
      gridCells = BaseLayer.makeGridCells(
         cols: data.gridCols ?? LayerEffectsDefaults.gridCols,
         rows: data.gridRows ?? LayerEffectsDefaults.gridRows,
         spacingX: data.gridSpacingX ?? LayerEffectsDefaults.gridSpacingX,
         spacingY: data.gridSpacingY ?? LayerEffectsDefaults.gridSpacingY,
         angleStep: data.gridAngleStep ?? LayerEffectsDefaults.gridAngleStep,
         mode: GridAngleMode(data.gridAngleMode))
   }

   /// Builds the layer for a decoded entry; nil when hidden (`visible: false`).
   static func make(from data: LayerData) -> BaseLayer? {
      // The web BackgroundLayer constructor drops `visible`: always drawn
      if data.visible == false && data.type != .background { return nil }
      let cls: BaseLayer.Type
      switch data.type {
      case .circle: cls = CircleLayer.self
      case .rosace: cls = RosaceLayer.self
      case .line: cls = LineLayer.self
      case .arc: cls = ArcLayer.self
      case .polygon: cls = PolygonLayer.self
      case .star: cls = StarLayer.self
      case .rect: cls = RectLayer.self
      case .spirograph: cls = SpirographLayer.self
      case .background: cls = BackgroundLayer.self
      }
      return cls.init(data: data)
   }

   // MARK: - Geometry helpers (web canvas space)

   func calcPosX(screenSize: CGSize, scale: CGFloat, posX: CGFloat? = nil) -> CGFloat {
      return screenSize.width / 2 + (posX ?? offset.x) * scale
   }

   func calcPosY(screenSize: CGSize, scale: CGFloat, posY: CGFloat? = nil) -> CGFloat {
      return screenSize.height / 2 + (posY ?? offset.y) * scale
   }

   func calcStretchX() -> CGFloat { return stretch.x }
   func calcStretchY() -> CGFloat { return stretch.y }

   /// Radians, web convention (canvas space is y-down, see the header comment).
   public func getCurrentAngle() -> CGFloat {
      return (rotation + angle + angleOffset) * .pi / 180
   }

   public func getChildAngle() -> CGFloat {
      return (childRotation + childAngle) * .pi / 180
   }

   // MARK: - Animation

   public func update(dt: CFTimeInterval) {
      let d = CGFloat(dt)
      rotation += rotationSpeed * d
      childRotation += childRotationSpeed * d
      advanceEffects(d)
   }

   // Advances the runtime state of the animated effects (dashes, pulse).
   private func advanceEffects(_ dt: CGFloat) {
      if dashSpeed != 0 {
         dashOffset += dashSpeed * dt
         if let dash = getDash() {
            let period = dash.dash + dash.gap
            if period > 0 { dashOffset = dashOffset.truncatingRemainder(dividingBy: period) }
         }
      }
      if pulseSpeed != 0 {
         pulsePhase = (pulsePhase + 2 * .pi * pulseSpeed * dt)
            .truncatingRemainder(dividingBy: 2 * .pi)
      }
   }

   // MARK: - Effects

   static func makeGridCells(cols: CGFloat, rows: CGFloat, spacingX: CGFloat, spacingY: CGFloat,
                             angleStep: CGFloat, mode: GridAngleMode) -> [GridCell] {
      func clampCount(_ v: CGFloat) -> Int {
         guard v.isFinite else { return 1 }
         return Int(min(maxGridCellsPerAxis, max(1, jsRound(v))))
      }
      let nCols = clampCount(cols)
      let nRows = clampCount(rows)
      if nCols == 1 && nRows == 1 { return [GridCell(dx: 0, dy: 0, angleOffset: 0)] }

      let meanSpacing = (abs(spacingX) + abs(spacingY)) / 2
      let ci = CGFloat(nCols - 1) / 2
      let cj = CGFloat(nRows - 1) / 2
      var cells: [GridCell] = []
      cells.reserveCapacity(nCols * nRows)
      for j in 0..<nRows {
         for i in 0..<nCols {
            let fi = CGFloat(i), fj = CGFloat(j)
            let dx = (fi - ci) * spacingX
            let dy = (fj - cj) * spacingY
            let factor: CGFloat
            switch mode {
            case .radial:
               factor = meanSpacing > 0 ? hypot(dx, dy) / meanSpacing : hypot(fi - ci, fj - cj)
            case .row:
               factor = fj
            case .diagonal:
               factor = fi + fj
            }
            cells.append(GridCell(dx: dx, dy: dy, angleOffset: angleStep * factor))
         }
      }
      return cells
   }

   /// Current scale factor of the pulse effect (1 = no pulse).
   func getPulseFactor() -> CGFloat {
      let amount = min(1, max(0, pulseAmount))
      if amount == 0 { return 1 }
      if pulseEasing == .sine { return 1 + amount * sin(pulsePhase) }

      // Other easings: 0 -> 1 -> 0 triangle over one cycle, eased
      let u = ((pulsePhase / (2 * .pi)).truncatingRemainder(dividingBy: 1) + 1)
         .truncatingRemainder(dividingBy: 1)
      let x = u < 0.5 ? 2 * u : 2 - 2 * u
      var v = x
      switch pulseEasing {
      case .easeIn: v = x * x * x
      case .easeOut: v = 1 - pow(1 - x, 3)
      case .easeInOut: v = x < 0.5 ? 4 * x * x * x : 1 - pow(-2 * x + 2, 3) / 2
      default: break
      }
      return 1 + amount * (2 * v - 1)
   }

   private func getDash() -> (dash: CGFloat, gap: CGFloat)? {
      guard dashLength > 0 else { return nil }
      return (dashLength, max(0, dashGap))
   }

   // Blend mode / dashes / caps: effects that only change the context state.
   private var hasStyleEffects: Bool {
      return blendMode != .normal || roundCap || getDash() != nil
   }

   /// True for Porter-Duff modes that erase / depend on destination alpha.
   var needsTransparentBackdrop: Bool {
      switch blendMode {
      case .xor, .destinationOut, .clear, .sourceIn, .sourceOut, .destinationIn,
           .destinationAtop, .copy, .sourceAtop, .destinationOver:
         return true
      default:
         return false
      }
   }

   private func applyStyleEffects(in context: CGContext, scale: CGFloat) {
      if blendMode != .normal { context.setBlendMode(blendMode) }

      if let dash = getDash() {
         let lengths = [dash.dash * scale, dash.gap * scale]
         // canvas lineDashOffset = -dashOffset (positive speed moves dashes forward);
         // CG phase has the same meaning, normalised into [0, period)
         let period = lengths[0] + lengths[1]
         var phase = -dashOffset * scale
         if period > 0 {
            phase = phase.truncatingRemainder(dividingBy: period)
            if phase < 0 { phase += period }
         }
         context.setLineDash(phase: phase, lengths: lengths)
      }

      if roundCap {
         context.setLineCap(.round)
         context.setLineJoin(.round)
      }
   }

   // MARK: - Drawing

   public func draw(in context: CGContext, screenSize: CGSize, scale: CGFloat) {
      let pulse = getPulseFactor()

      // Fast path: no effect enabled, behaves exactly as a plain layer
      if gridCells.count == 1 && pulse == 1 && !hasStyleEffects {
         drawCell(in: context, screenSize: screenSize, scale: scale)
         return
      }

      // A zero pulse collapses the shape (canvas draws nothing)
      if abs(pulse) < 1e-6 { return }

      context.saveGState()
      applyStyleEffects(in: context, scale: scale)
      for cell in gridCells {
         context.saveGState()
         if cell.dx != 0 || cell.dy != 0 {
            context.translateBy(x: cell.dx * scale, y: cell.dy * scale)
         }
         if pulse != 1 {
            // Scale around the layer center (in the current cell space)
            let cx = calcPosX(screenSize: screenSize, scale: scale)
            let cy = calcPosY(screenSize: screenSize, scale: scale)
            context.translateBy(x: cx, y: cy)
            context.scaleBy(x: pulse, y: pulse)
            context.translateBy(x: -cx, y: -cy)
         }
         angleOffset = cell.angleOffset
         drawCell(in: context, screenSize: screenSize, scale: scale)
         context.restoreGState()
      }
      angleOffset = 0
      context.restoreGState()
   }

   // Draws one instance of the layer (mask clip + shape).
   private func drawCell(in context: CGContext, screenSize: CGSize, scale: CGFloat) {
      setColor(in: context)
      guard hasMask else {
         drawShape(in: context, screenSize: screenSize, scale: scale)
         return
      }
      let mx = calcPosX(screenSize: screenSize, scale: scale, posX: maskX)
      let my = calcPosY(screenSize: screenSize, scale: scale, posY: maskY)
      let mr = max(0, maskRadius * scale)
      context.saveGState()
      context.beginPath()
      context.addArc(center: CGPoint(x: mx, y: my), radius: mr, startAngle: 0, endAngle: 2 * .pi, clockwise: false)
      context.closePath()
      context.clip()
      drawShape(in: context, screenSize: screenSize, scale: scale)
      context.restoreGState()
   }

   /// Default shape: a circle of `radius` (web BaseLayer.drawShape).
   func drawShape(in context: CGContext, screenSize: CGSize, scale: CGFloat) {
      let r = radius * scale
      guard r >= 0 else { return } // canvas arc() rejects negative radii
      context.beginPath()
      context.addArc(center: CGPoint(x: calcPosX(screenSize: screenSize, scale: scale),
                                     y: calcPosY(screenSize: screenSize, scale: scale)),
                     radius: r, startAngle: 0, endAngle: 2 * .pi, clockwise: false)
      context.closePath()
      drawPath(in: context, scale: scale)
   }

   /// Fills or strokes the current path (web BaseLayer.drawPath).
   func drawPath(in context: CGContext, scale: CGFloat) {
      if filled {
         context.fillPath()
      } else {
         context.setLineWidth(lineWidth * scale)
         context.strokePath()
      }
   }

   public func setColor(in context: CGContext) {
      context.setStrokeColor(color)
      context.setFillColor(color)
   }
}
