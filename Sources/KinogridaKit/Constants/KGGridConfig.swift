import AppKit

final class KGGridConfig {
    var nbrColumns: Int     = 10
    var nbrRows: Int        = 10
    var cellSize: CGFloat   = 1
    var gridMargin: CGFloat = 50
    var offsetX: CGFloat    = 0
    var offsetY: CGFloat    = 0
    var width: CGFloat      = 0
    var height: CGFloat     = 0
    var lineWidth: CGFloat  = 1
    var speed: CGFloat      = 10000
    var colors: [NSColor]   = []

    // ── Debug ─────────────────────────────────────────────────
    var showGrid: Bool        = false
    var showStats: Bool       = false
    var showLockedCells: Bool = false
    var showPath: Bool        = false
    var showPosition: Bool    = false

    static func defaultConfig() -> KGGridConfig {
        let c    = KGGridConfig()
        c.colors = KGColors.randomPalette()
        return c
    }

    // Recompute cellSize, offsets, lineWidth from canvas bounds
    func updateForCanvasSize(_ size: CGSize) {
        let availW  = size.width  - 2 * gridMargin
        let availH  = size.height - 2 * gridMargin
        cellSize    = floor(min(availW / CGFloat(nbrColumns), availH / CGFloat(nbrRows)))
        width       = CGFloat(nbrColumns) * cellSize
        height      = CGFloat(nbrRows)    * cellSize
        offsetX     = (size.width  - width)  / 2
        offsetY     = (size.height - height) / 2
        lineWidth   = max(1, floor(cellSize * 0.1))
    }
}
