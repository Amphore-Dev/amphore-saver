import AppKit

final class BackgroundLayer: BaseLayer {
    override func draw(in context: CGContext, screenSize: CGSize, scale: CGFloat) {
        let cgColor = CGColor.fromHex(self.color)
        context.setFillColor(cgColor)
        context.fill(CGRect(origin: .zero, size: screenSize))
    }
}
