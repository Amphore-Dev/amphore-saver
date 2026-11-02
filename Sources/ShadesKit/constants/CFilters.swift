import AppKit

let LINE_CAP_TYPES: [CGLineCap] = [.butt, .round, .square]

func sameColorFilter(_ mainColor: ShadeColor, _ itemColor: ShadeColor) -> Bool {
    itemColor.hex == mainColor.hex
}

func noFilter(_ mainColor: ShadeColor, _ itemColor: ShadeColor) -> Bool {
    true
}

func randomFilter(_ mainColor: ShadeColor, _ itemColor: ShadeColor) -> Bool {
    false
}

func random50Filter(_ mainColor: ShadeColor, _ itemColor: ShadeColor) -> Bool {
    Int.random(in: 0...1) == 1
}

nonisolated(unsafe) let RANDOM_FILTERS: [(ShadeColor, ShadeColor) -> Bool] = [
    sameColorFilter, noFilter, randomFilter, random50Filter,
]
