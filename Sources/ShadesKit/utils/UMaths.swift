import Foundation

func randInt(_ min: Int, _ max: Int) -> Int {
    guard max > min else { return min }
    return Int.random(in: min...max)
}

func randFloat(_ min: CGFloat, _ max: CGFloat) -> CGFloat {
    CGFloat.random(in: min...max)
}

func degToRad(_ degrees: CGFloat) -> CGFloat {
    degrees * .pi / 180
}
