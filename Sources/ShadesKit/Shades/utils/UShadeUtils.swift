import AppKit

func getRandColors() -> [ShadeColor] {
    var tryCount = 0
    var colors = [
        ALL_COLORS[randInt(0, ALL_COLORS.count - 1)],
        ALL_COLORS[randInt(0, ALL_COLORS.count - 1)],
    ]
    while colors[0].hex == colors[1].hex && tryCount < 10 {
        colors[1] = ALL_COLORS[randInt(0, ALL_COLORS.count - 1)]
        tryCount += 1
    }
    return colors
}

func getRandFilter() -> (ShadeColor, ShadeColor) -> Bool {
    RANDOM_FILTERS[randInt(0, RANDOM_FILTERS.count - 1)]
}

func getRandLineCap() -> CGLineCap {
    LINE_CAP_TYPES[randInt(0, LINE_CAP_TYPES.count - 1)]
}

func getRandColor() -> ShadeColor {
    let colors = getRandColors()
    return colors[randInt(0, colors.count - 1)]
}
