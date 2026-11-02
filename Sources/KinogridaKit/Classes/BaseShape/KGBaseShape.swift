import AppKit
import QuartzCore

// grid = KGGrid (class, reference type)
// cell = .empty | .locked | .shape(KGBaseShape)

class KGBaseShape {

    // ── Current position (fractional during movement) ─────────
    var x: CGFloat
    var y: CGFloat

    // ── Animation ─────────────────────────────────────────────
    var speed: CGFloat        = 0
    var moveDistance: CGFloat = 0
    var progress: CGFloat     = 0
    var tailProgress: CGFloat = 0

    // ── Timing ────────────────────────────────────────────────
    var lastMoveTime: CFTimeInterval
    var moveDebounce: CFTimeInterval

    // ── Movement state ────────────────────────────────────────
    var isMoving: Bool         = false
    var hasReachedTarget: Bool = false
    var tailX: CGFloat
    var tailY: CGFloat
    var originalX: CGFloat
    var originalY: CGFloat
    var targetX: CGFloat
    var targetY: CGFloat

    // ── Appearance ────────────────────────────────────────────
    var color: NSColor

    // ── Locked cells ──────────────────────────────────────────
    var lockedCells: [GridPoint] = []

    // ─────────────────────────────────────────────────────────
    init(grid: KGGrid, x: Int, y: Int, color: NSColor) {
        let fx = CGFloat(x), fy = CGFloat(y)
        self.x         = fx;  self.y         = fy
        self.tailX     = fx;  self.tailY     = fy
        self.originalX = fx;  self.originalY = fy
        self.targetX   = fx;  self.targetY   = fy
        self.color     = color
        self.lastMoveTime = CACurrentMediaTime() * 1000
        self.moveDebounce = KGRandom(0, 10) * 1000
    }

    // ── Main update ───────────────────────────────────────────

    func update(grid: KGGrid, config: KGGridConfig, deltaTime: CGFloat) {
        speed = (2.0 * deltaTime) / config.speed
        if isMoving {
            updatePosition(grid: grid)
        } else {
            calculateNewTarget(grid: grid, config: config)
        }
    }

    // ── Abstract – subclasses must override ───────────────────

    func calculateNewTarget(grid: KGGrid, config: KGGridConfig) {}
    func updatePosition(grid: KGGrid) {}
    func draw(in ctx: CGContext, config: KGGridConfig) {}

    // ── Movement ──────────────────────────────────────────────

    func moveTo(grid: KGGrid, config: KGGridConfig, x: Int, y: Int) {
        let now = CACurrentMediaTime() * 1000
        guard !isMoving, (now - lastMoveTime) >= moveDebounce else { return }

        guard let locked = genLockPath(grid: grid, config: config, targetX: x, targetY: y) else { return }
        guard lockCells(grid: grid, cells: locked, apply: false) else { return }
        lockCells(grid: grid, cells: locked, apply: true)

        targetX      = CGFloat(x);   targetY   = CGFloat(y)
        tailX        = self.x;       tailY     = self.y
        originalX    = self.x;       originalY = self.y
        moveDistance = abs(CGFloat(x) - self.x) + abs(CGFloat(y) - self.y)
        isMoving     = true
        lastMoveTime = now
    }

    // Default lock path: straight line (overridden by ArcShape)
    func genLockPath(grid: KGGrid, config: KGGridConfig, targetX: Int, targetY: Int) -> [GridPoint]? {
        getLineCells(from: GridPoint(col: Int(x.rounded()), row: Int(y.rounded())),
                     to:   GridPoint(col: targetX, row: targetY))
    }

    @discardableResult
    func lockCells(grid: KGGrid, cells: [GridPoint], apply: Bool) -> Bool {
        for pt in cells {
            switch grid[pt.row, pt.col] {
            case .empty:
                if apply {
                    grid[pt.row, pt.col] = .locked
                    lockedCells.append(pt)
                }
            default:
                // Non-empty: only allowed at the shape's own starting position
                if pt.row != Int(self.y) || pt.col != Int(self.x) { return false }
            }
        }
        return true
    }

    func unlockCells(grid: KGGrid) {
        for pt in lockedCells {
            if grid.isValid(row: pt.row, col: pt.col) {
                grid[pt.row, pt.col] = .empty
            }
        }
        lockedCells.removeAll()
    }

    func onMoveComplete(grid: KGGrid, newX: Int, newY: Int) {
        let savedX = Int(originalX), savedY = Int(originalY)

        x         = CGFloat(newX);   y         = CGFloat(newY)
        originalX = CGFloat(newX);   originalY = CGFloat(newY)
        isMoving  = false
        lastMoveTime  = CACurrentMediaTime() * 1000
        moveDebounce  = KGRandom(0, 10) * 1000

        unlockCells(grid: grid)
        grid[savedY, savedX] = .empty
        grid[newY,   newX]   = .shape(self)
        hasReachedTarget = false
    }

    // ── Helpers available to subclasses ───────────────────────

    func isValid(col: Int, row: Int, grid: KGGrid) -> Bool {
        grid.isValid(row: row, col: col)
    }

    func getLineCells(from: GridPoint, to: GridPoint) -> [GridPoint] {
        []   // Base returns empty; SquareShape overrides
    }

    // ── Debug ─────────────────────────────────────────────────

    func drawLockedCells(in ctx: CGContext, config: KGGridConfig) {
        let cs = config.cellSize, ox = config.offsetX, oy = config.offsetY

        // Original position — green
        ctx.setFillColor(red: 0, green: 1, blue: 0, alpha: 0.2)
        ctx.fill(CGRect(x: originalX * cs + ox, y: originalY * cs + oy, width: cs, height: cs))

        // Current position — yellow
        ctx.setFillColor(red: 1, green: 1, blue: 0, alpha: 0.2)
        ctx.fill(CGRect(x: x * cs + ox, y: y * cs + oy, width: cs, height: cs))

        // Target position — magenta
        ctx.setFillColor(red: 1, green: 0, blue: 1, alpha: 0.2)
        ctx.fill(CGRect(x: targetX * cs + ox, y: targetY * cs + oy, width: cs, height: cs))

        // Locked path — shape colour with transparency
        ctx.setFillColor(color.withAlphaComponent(0.2).cgColor)
        for pt in lockedCells {
            ctx.fill(CGRect(x: CGFloat(pt.col) * cs + ox,
                            y: CGFloat(pt.row) * cs + oy,
                            width: cs, height: cs))
        }
    }
}
