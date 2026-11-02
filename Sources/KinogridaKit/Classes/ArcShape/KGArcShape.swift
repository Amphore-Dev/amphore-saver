import AppKit

// ── Geometry bundle ───────────────────────────────────────────
private struct ArcGeometry {
    var centerX, centerY:     CGFloat
    var endAngle, initAngle:  CGFloat
    var startAngle, tailAngle: CGFloat
    var arcRadius:            CGFloat
    var arcCenterX, arcCenterY: CGFloat
    var cellSize, lineWidth:  CGFloat
    var rotationDirection:    CGFloat
    var offsetX, offsetY:     CGFloat
}

final class KGArcShape: KGBaseShape {

    var angleOffset: CGFloat    // radians
    var arc: CGFloat            // arc radius multiplier (in cells)
    var clockwise: Bool
    var rotationAmount: CGFloat // 0.25=quarter, 0.5=half, 0.75=three-quarter

    override init(grid: KGGrid, x: Int, y: Int, color: NSColor) {
        self.angleOffset    = KGArcShape.randomAngleOffset()
        self.arc            = 2
        self.clockwise      = true
        self.rotationAmount = 0.25
        super.init(grid: grid, x: x, y: y, color: color)
    }

    // ── Helpers ───────────────────────────────────────────────

    private static func randomAngleOffset() -> CGFloat {
        let angles: [CGFloat] = [0, 0.25, 0.5, 0.75]
        return angles[KGRandomInt(0, 3)] * .pi * 2
    }

    private func geometry(config: KGGridConfig, angleOffset: CGFloat, arc: CGFloat) -> ArcGeometry {
        let cs = config.cellSize
        let ox = config.offsetX, oy = config.offsetY
        let lw = config.lineWidth

        let centerX    = ox + x * cs + cs / 2
        let centerY    = oy + y * cs + cs / 2

        let endAngle   = angleOffset
        let initAngle  = endAngle - .pi

        let rotDir     = clockwise ? CGFloat(1) : -1
        let rotAngle   = 2 * CGFloat.pi * rotationAmount

        let startAngle = initAngle + rotAngle * progress     * rotDir
        let tailAngle  = initAngle + rotAngle * tailProgress * rotDir

        let arcRadius  = cs * arc
        let arcCenterX = centerX + cs * arc * cos(endAngle)
        let arcCenterY = centerY + cs * arc * sin(endAngle)

        return ArcGeometry(
            centerX: centerX,       centerY: centerY,
            endAngle: endAngle,     initAngle: initAngle,
            startAngle: startAngle, tailAngle: tailAngle,
            arcRadius: arcRadius,
            arcCenterX: arcCenterX, arcCenterY: arcCenterY,
            cellSize: cs,           lineWidth: lw,
            rotationDirection: rotDir,
            offsetX: ox,            offsetY: oy
        )
    }

    private func geometry(config: KGGridConfig) -> ArcGeometry {
        geometry(config: config, angleOffset: angleOffset, arc: arc)
    }

    // ── Draw arc elements (outer arc, inner arc, caps) ────────

    private func drawArcElements(ctx: CGContext, geo: ArcGeometry, color: NSColor, width: CGFloat) {
        let halfW = width / 2

        let rotAngle      = 2 * CGFloat.pi * rotationAmount
        let arcStartAngle = geo.initAngle + rotAngle * tailProgress * geo.rotationDirection
        let arcEndAngle   = geo.initAngle + rotAngle * progress     * geo.rotationDirection

        let startX = geo.arcCenterX + geo.arcRadius * cos(geo.startAngle)
        let startY = geo.arcCenterY + geo.arcRadius * sin(geo.startAngle)
        let endX   = geo.arcCenterX + geo.arcRadius * cos(geo.tailAngle)
        let endY   = geo.arcCenterY + geo.arcRadius * sin(geo.tailAngle)

        ctx.setLineWidth(geo.lineWidth)
        ctx.setStrokeColor(color.cgColor)

        // Start cap
        ctx.beginPath()
        ctx.addArc(center: CGPoint(x: startX, y: startY),
                   radius: max(0, halfW),
                   startAngle: clockwise ? geo.startAngle         : geo.startAngle - .pi,
                   endAngle:   clockwise ? geo.startAngle + .pi   : geo.startAngle,
                   clockwise: false)
        ctx.strokePath()

        // End cap
        ctx.beginPath()
        ctx.addArc(center: CGPoint(x: endX, y: endY),
                   radius: max(0, halfW),
                   startAngle: clockwise ? geo.tailAngle - .pi    : geo.tailAngle,
                   endAngle:   clockwise ? geo.tailAngle          : geo.tailAngle - .pi,
                   clockwise: false)
        ctx.strokePath()

        // Outer arc
        // Canvas uses counterclockwise = !self.clockwise. After Y-flip:
        // canvas CW (ccw=false) ↔ CGContext clockwise=false → !clockwise in Swift Bool
        ctx.beginPath()
        ctx.addArc(center: CGPoint(x: geo.arcCenterX, y: geo.arcCenterY),
                   radius: geo.arcRadius + halfW,
                   startAngle: arcStartAngle, endAngle: arcEndAngle,
                   clockwise: !clockwise)
        ctx.strokePath()

        // Inner arc
        ctx.beginPath()
        ctx.addArc(center: CGPoint(x: geo.arcCenterX, y: geo.arcCenterY),
                   radius: max(0.001, geo.arcRadius - halfW),
                   startAngle: arcStartAngle, endAngle: arcEndAngle,
                   clockwise: !clockwise)
        ctx.strokePath()
    }

    // ── Draw ──────────────────────────────────────────────────

    override func draw(in ctx: CGContext, config: KGGridConfig) {
        let geo      = geometry(config: config)
        let baseSize = config.cellSize * 0.8
        ctx.setLineCap(.round)
        drawArcElements(ctx: ctx, geo: geo, color: color, width: baseSize)
        drawArcElements(ctx: ctx, geo: geo, color: .white, width: baseSize - geo.lineWidth * 4)
    }

    // ── Update position (animation progress) ──────────────────
    // Progress update only — geometry finalization in updateProgress(config:grid:)

    override func updatePosition(grid: KGGrid) {
        guard isMoving else { return }

        if progress < 1 {
            progress = min(1, progress + speed)
            if progress >= 1 { hasReachedTarget = true }
        } else if tailProgress < 1 {
            tailProgress = min(1, tailProgress + speed)
        }
    }

    // Called by the engine after updateWithGrid to finalize arc grid position
    func updateProgress(config: KGGridConfig, grid: KGGrid) {
        guard isMoving, tailProgress >= 1 else { return }

        let geo        = geometry(config: config)
        let rotAngle   = 2 * CGFloat.pi * rotationAmount
        let finalAngle = geo.endAngle - .pi + rotAngle * geo.rotationDirection

        let newX = Int(floor((geo.arcCenterX + geo.arcRadius * cos(finalAngle) - geo.offsetX) / geo.cellSize))
        let newY = Int(floor((geo.arcCenterY + geo.arcRadius * sin(finalAngle) - geo.offsetY) / geo.cellSize))

        onMoveComplete(grid: grid, newX: newX, newY: newY)
        progress     = 0
        tailProgress = 0
    }

    // ── Calculate new target ──────────────────────────────────

    override func calculateNewTarget(grid: KGGrid, config: KGGridConfig) {
        guard !isMoving else { return }

        let maxArc = min(config.nbrColumns, config.nbrRows) / 2 - 1
        guard maxArc >= 1 else { return }

        let newOffset    = KGArcShape.randomAngleOffset()
        let newArc       = CGFloat(KGRandomInt(1, maxArc))
        let newClockwise = Bool.random()
        let rotAmounts: [CGFloat] = [0.25, 0.5, 0.75]
        let newRot       = rotAmounts[KGRandomInt(0, 2)]

        // Save current params
        let savedOffset = angleOffset, savedArc = arc
        let savedCW     = clockwise,   savedRot = rotationAmount

        // Temporarily apply candidate params to calculate endpoint
        angleOffset    = newOffset
        arc            = newArc
        clockwise      = newClockwise
        rotationAmount = newRot

        let geo        = geometry(config: config)
        let rotAngle   = 2 * CGFloat.pi * newRot
        let finalAngle = geo.endAngle - .pi + rotAngle * (newClockwise ? 1 : -1)

        let endX = Int(floor((geo.arcCenterX + geo.arcRadius * cos(finalAngle) - geo.offsetX) / geo.cellSize))
        let endY = Int(floor((geo.arcCenterY + geo.arcRadius * sin(finalAngle) - geo.offsetY) / geo.cellSize))

        let cellEmpty: Bool
        if endX >= 0 && endX < config.nbrColumns && endY >= 0 && endY < config.nbrRows {
            if case .empty = grid[endY, endX] { cellEmpty = true } else { cellEmpty = false }
        } else {
            cellEmpty = false
        }

        let valid = cellEmpty && (endX != Int(self.x) || endY != Int(self.y))

        guard valid else {
            angleOffset    = savedOffset
            arc            = savedArc
            clockwise      = savedCW
            rotationAmount = savedRot
            return
        }

        moveTo(grid: grid, config: config, x: endX, y: endY)
    }

    // ── Debug path ────────────────────────────────────────────

    func drawDebugPath(in ctx: CGContext, config: KGGridConfig) {
        guard isMoving else { return }

        let geo      = geometry(config: config)
        let steps    = max(10, Int(arc * arc * (rotationAmount * 8)))
        let halfW    = config.cellSize * 0.5 - config.lineWidth * 0.51
        let rotAngle = 2 * CGFloat.pi * rotationAmount

        var centerPts = [CGPoint]()
        var innerPts  = [CGPoint]()
        var outerPts  = [CGPoint]()

        for i in 0...steps {
            let t     = CGFloat(i) / CGFloat(steps)
            let angle = geo.endAngle - .pi + rotAngle * t * geo.rotationDirection
            let innerR = max(0.001, geo.arcRadius - halfW)

            centerPts.append(CGPoint(x: geo.arcCenterX + geo.arcRadius * cos(angle),
                                     y: geo.arcCenterY + geo.arcRadius * sin(angle)))
            innerPts.append(CGPoint(x: geo.arcCenterX + innerR * cos(angle),
                                    y: geo.arcCenterY + innerR * sin(angle)))
            outerPts.append(CGPoint(x: geo.arcCenterX + (geo.arcRadius + halfW) * cos(angle),
                                    y: geo.arcCenterY + (geo.arcRadius + halfW) * sin(angle)))
        }

        func drawPolyline(_ pts: [CGPoint], r: CGFloat, g: CGFloat, b: CGFloat) {
            ctx.setStrokeColor(red: r, green: g, blue: b, alpha: 1)
            ctx.setLineWidth(1)
            ctx.beginPath()
            for (i, p) in pts.enumerated() {
                if i == 0 { ctx.move(to: p) } else { ctx.addLine(to: p) }
                ctx.addArc(center: p, radius: 2, startAngle: 0, endAngle: .pi * 2, clockwise: false)
                ctx.move(to: p)
            }
            ctx.strokePath()
        }

        drawPolyline(centerPts, r: 1, g: 0, b: 0) // red
        drawPolyline(innerPts,  r: 0, g: 0, b: 1) // blue
        drawPolyline(outerPts,  r: 0, g: 1, b: 0) // green
    }

    // ── Lock path (arc cells) ─────────────────────────────────

    override func genLockPath(grid: KGGrid, config: KGGridConfig, targetX: Int, targetY: Int) -> [GridPoint]? {
        let geo      = geometry(config: config)
        let steps    = max(10, Int(arc * arc * (rotationAmount * 8)))
        let halfW    = config.cellSize * 0.5 - config.lineWidth * 0.51
        let rotAngle = 2 * CGFloat.pi * rotationAmount

        var path = [GridPoint]()
        var seen = Set<GridPoint>()

        for i in 0...steps {
            let t     = CGFloat(i) / CGFloat(steps)
            let angle = geo.endAngle - .pi + rotAngle * t * geo.rotationDirection

            let cx     = geo.arcCenterX + geo.arcRadius * cos(angle)
            let cy     = geo.arcCenterY + geo.arcRadius * sin(angle)
            let innerR = max(0.001, geo.arcRadius - halfW)
            let ix     = geo.arcCenterX + innerR * cos(angle)
            let iy     = geo.arcCenterY + innerR * sin(angle)
            let ox2    = geo.arcCenterX + (geo.arcRadius + halfW) * cos(angle)
            let oy2    = geo.arcCenterY + (geo.arcRadius + halfW) * sin(angle)

            for (wx, wy) in [(cx, cy), (ix, iy), (ox2, oy2)] {
                let gc = Int(floor((wx - geo.offsetX) / geo.cellSize))
                let gr = Int(floor((wy - geo.offsetY) / geo.cellSize))

                guard grid.isValid(row: gr, col: gc) else { return nil }

                let pt = GridPoint(col: gc, row: gr)
                if seen.insert(pt).inserted {
                    path.append(pt)
                }
            }
        }
        return path
    }
}
