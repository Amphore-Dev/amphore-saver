import Foundation
import CoreGraphics

// ── Position ──────────────────────────────────────────────────
struct KGPosition {
    var x: Int
    var y: Int
}

// ── Grid point (col = x, row = y) ────────────────────────────
struct GridPoint: Hashable {
    let col: Int
    let row: Int
}

// ── Cell content ──────────────────────────────────────────────
// Replaces the ObjC NSMutableArray cell sentinel scheme:
//   [NSNull null]  → .empty
//   KGCellLocked   → .locked
//   KGBaseShape *  → .shape(KGBaseShape)
enum KGCellContent {
    case empty
    case locked
    case shape(KGBaseShape)
}

// ── Grid ──────────────────────────────────────────────────────
final class KGGrid {
    private var cells: [[KGCellContent]]
    let rows: Int
    let cols: Int

    init(rows: Int, cols: Int) {
        self.rows  = rows
        self.cols  = cols
        self.cells = Array(repeating: Array(repeating: .empty, count: cols), count: rows)
    }

    subscript(row: Int, col: Int) -> KGCellContent {
        get { cells[row][col] }
        set { cells[row][col] = newValue }
    }

    func isValid(row: Int, col: Int) -> Bool {
        row >= 0 && row < rows && col >= 0 && col < cols
    }
}

// ── Math helpers ──────────────────────────────────────────────
func KGRandom(_ min: CGFloat, _ max: CGFloat) -> CGFloat {
    min + CGFloat.random(in: 0...1) * (max - min)
}

func KGRandomInt(_ min: Int, _ max: Int) -> Int {
    Int.random(in: min...max)
}

func KGClamp(_ value: CGFloat, _ min: CGFloat, _ max: CGFloat) -> CGFloat {
    Swift.max(min, Swift.min(max, value))
}
