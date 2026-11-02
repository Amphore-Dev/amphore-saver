import AppKit

final class KGSquareShape: KGBaseShape {

    var radiusPercent: CGFloat // 0 = square corners, 1 = fully rounded

    init(grid: KGGrid, x: Int, y: Int, color: NSColor, radiusPercent: CGFloat) {
        self.radiusPercent = radiusPercent
        super.init(grid: grid, x: x, y: y, color: color)
    }

    // ── Line cells (horizontal or vertical only) ──────────────

    override func getLineCells(from: GridPoint, to: GridPoint) -> [GridPoint] {
        var cells = [GridPoint]()
        if from.row == to.row {
            for col in min(from.col, to.col)...max(from.col, to.col) {
                cells.append(GridPoint(col: col, row: from.row))
            }
        } else if from.col == to.col {
            for row in min(from.row, to.row)...max(from.row, to.row) {
                cells.append(GridPoint(col: from.col, row: row))
            }
        }
        return cells
    }

    // ── Calculate new target ──────────────────────────────────

    override func calculateNewTarget(grid: KGGrid, config: KGGridConfig) {
        let dir = KGRandomInt(1, 4) // 1=up 2=right 3=down 4=left
        var newX = Int(x), newY = Int(y)

        if dir == 1 || dir == 3 {
            let maxDelta = config.nbrRows / 2 - 1
            guard maxDelta >= 1 else { return }
            let delta = KGRandomInt(1, maxDelta) * (dir == 1 ? -1 : 1)
            newY = Int(KGClamp(y + CGFloat(delta), 0, CGFloat(config.nbrRows - 1)))
        } else {
            let maxDelta = config.nbrColumns / 2 - 1
            guard maxDelta >= 1 else { return }
            let delta = KGRandomInt(1, maxDelta) * (dir == 2 ? -1 : 1)
            newX = Int(KGClamp(x + CGFloat(delta), 0, CGFloat(config.nbrColumns - 1)))
        }

        if case .empty = grid[newY, newX], newX != Int(self.x) || newY != Int(self.y) {
            moveTo(grid: grid, config: config, x: newX, y: newY)
        }
    }

    // ── Update position (head + tail) ─────────────────────────

    override func updatePosition(grid: KGGrid) {
        let step = speed * moveDistance

        if hasReachedTarget {
            // Tail catches up to target
            if abs(tailX - targetX) > step { tailX += tailX < targetX ? step : -step }
            else                           { tailX  = targetX }

            if abs(tailY - targetY) > step { tailY += tailY < targetY ? step : -step }
            else                           { tailY  = targetY }

            if tailX == targetX && tailY == targetY {
                onMoveComplete(grid: grid, newX: Int(targetX), newY: Int(targetY))
            }
        } else {
            // Head moves toward target
            if abs(x - targetX) > step { x += x < targetX ? step : -step }
            else                       { x  = targetX }

            if abs(y - targetY) > step { y += y < targetY ? step : -step }
            else                       { y  = targetY }

            if x == targetX && y == targetY { hasReachedTarget = true }
        }
    }

    // ── Draw ──────────────────────────────────────────────────

    override func draw(in ctx: CGContext, config: KGGridConfig) {
        let cs  = config.cellSize
        let ox  = config.offsetX, oy = config.offsetY
        let pad = cs * 0.1

        let origPX = tailX * cs + ox + pad
        let origPY = tailY * cs + oy + pad
        let currPX = x     * cs + ox + pad
        let currPY = y     * cs + oy + pad

        let startX = min(origPX, currPX)
        let startY = min(origPY, currPY)
        let rectW  = max(origPX, currPX) - startX + cs * 0.8
        let rectH  = max(origPY, currPY) - startY + cs * 0.8

        // Cap radius to half the smallest dimension to avoid oval effect
        let targetR = radiusPercent * cs
        let radius  = min(targetR, min(rectW, rectH) / 2)
        let radius2 = min(targetR / 2, min(rectW - cs * 0.4, rectH - cs * 0.4) / 2)
        let lw      = config.lineWidth

        ctx.setLineWidth(lw)

        // Outer rect — shape colour
        ctx.setStrokeColor(color.cgColor)
        let outer = CGPath(roundedRect: CGRect(x: startX, y: startY, width: rectW, height: rectH),
                           cornerWidth: radius, cornerHeight: radius, transform: nil)
        ctx.addPath(outer)
        ctx.strokePath()

        // Inner rect — white
        ctx.setStrokeColor(NSColor.white.cgColor)
        let inner = CGPath(roundedRect: CGRect(x: startX + cs * 0.2, y: startY + cs * 0.2,
                                               width: rectW - cs * 0.4, height: rectH - cs * 0.4),
                           cornerWidth: radius2, cornerHeight: radius2, transform: nil)
        ctx.addPath(inner)
        ctx.strokePath()
    }
}
