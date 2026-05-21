import ScreenSaver

@objc(Psykala_screensaverView)
final class PsykalaView: ScreenSaverView {

    private var layers: [BaseLayer] = []
    private var time: CFTimeInterval = 0
    private var prevTime: CFTimeInterval = 0

    // Fade state
    private var fadeOpacity: CGFloat = 0
    private var fadeTarget: CGFloat = 1
    private var fadeStartOpacity: CGFloat = 0
    private var fadeStartTime: CFTimeInterval = 0
    private var isFading = false
    private let fadeDuration: CFTimeInterval = 0.8
    private var pendingRegeneration = false

    // Scene cycling
    private var regenTimer: CFTimeInterval = 0
    private let regenInterval: CFTimeInterval = 30

    // Artwork queue
    private var apiQueue: [ArtworkData] = []

    // MARK: - Init

    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        animationTimeInterval = 1.0 / 60.0
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: - Lifecycle

    override func startAnimation() {
        super.startAnimation()
        time = CACurrentMediaTime()
        prevTime = time
        regenTimer = time
        if apiQueue.isEmpty {
            fetchArtworks()
        } else {
            loadNextArtwork()
        }
    }

    override func stopAnimation() {
        super.stopAnimation()
        layers.removeAll()
    }

    override func animateOneFrame() {
        prevTime = time
        time = CACurrentMediaTime()
        let dt = time - prevTime

        for layer in layers {
            layer.update(dt: dt)
        }

        updateFade()

        if !layers.isEmpty && time - regenTimer > regenInterval && !isFading {
            triggerRegeneration()
        }

        setNeedsDisplay(bounds)
    }

    override func draw(_ rect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }

        ctx.setFillColor(NSColor.black.cgColor)
        ctx.fill(bounds)

        let scale = min(bounds.width, bounds.height) / 1280
        let screenSize = bounds.size

        for layer in layers.reversed() {
            layer.draw(in: ctx, screenSize: screenSize, scale: scale)
        }

        let overlayAlpha = 1 - fadeOpacity
        if overlayAlpha > 0.001 {
            ctx.setFillColor(NSColor.black.withAlphaComponent(overlayAlpha).cgColor)
            ctx.fill(bounds)
        }
    }

    override var hasConfigureSheet: Bool { false }
    override var configureSheet: NSWindow? { nil }

    // MARK: - Artwork loading

    private func loadNextArtwork() {
        guard !apiQueue.isEmpty else {
            fetchArtworks()
            return
        }
        let artwork = apiQueue.removeFirst()
        applyArtwork(artwork)
    }

    private func applyArtwork(_ artwork: ArtworkData) {
        layers = artwork.layers.map { BaseLayer.make(from: $0) }

        fadeStartTime = time
        fadeStartOpacity = 0
        fadeOpacity = 0
        fadeTarget = 1
        isFading = true
        regenTimer = time
    }

    private func triggerRegeneration() {
        fadeStartTime = time
        fadeStartOpacity = fadeOpacity
        fadeTarget = 0
        isFading = true
        pendingRegeneration = true
    }

    // MARK: - Fade

    private func updateFade() {
        guard isFading else { return }

        let elapsed = time - fadeStartTime
        let progress = min(CGFloat(elapsed / fadeDuration), 1)
        fadeOpacity = fadeStartOpacity + (fadeTarget - fadeStartOpacity) * progress

        if progress >= 1 {
            fadeOpacity = fadeTarget
            isFading = false

            if pendingRegeneration && fadeTarget == 0 {
                pendingRegeneration = false
                loadNextArtwork()
            }
        }
    }

    // MARK: - API

    private func fetchArtworks() {
        ArtworkService.fetchRandom { [weak self] artworks in
            guard let self = self, !artworks.isEmpty else { return }
            self.apiQueue = artworks.shuffled()
            self.loadNextArtwork()
        }
    }
}
