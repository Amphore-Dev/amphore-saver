import AppKit
import ScreensaverCore

public final class PsykalaScene: ScreensaverScene {

    // MARK: - Settings

    public static let artworkDuration = Setting.slider(
        "psykala.artworkDuration", "Artwork duration", default: 30, range: 5...300, step: 5, unit: .seconds
    )
    public static let offlineOnly = Setting.toggle(
        "psykala.offlineOnly", "Offline only (bundled artworks)", default: false
    )
    public static let fade = Setting.slider(
        "psykala.fade", "Artwork fade", default: 0.8, range: 0.1...3, step: 0.1, unit: .seconds
    )

    public static let descriptor = SceneDescriptor(
        id: "psykala",
        name: "Psykala",
        settings: [artworkDuration, offlineOnly, fade],
        make: { PsykalaScene(context: $0) }
    )

    private var bounds: CGRect
    private let offline: Bool

    private var layers: [BaseLayer] = []
    private var time: CFTimeInterval = 0
    private var prevTime: CFTimeInterval = 0

    // Fade state
    private var fadeOpacity: CGFloat = 0
    private var fadeTarget: CGFloat = 1
    private var fadeStartOpacity: CGFloat = 0
    private var fadeStartTime: CFTimeInterval = 0
    private var isFading = false
    private let fadeDuration: CFTimeInterval
    private var pendingRegeneration = false

    // Scene cycling
    private var regenTimer: CFTimeInterval = 0
    private let regenInterval: CFTimeInterval

    // Artwork queue
    private var apiQueue: [ArtworkData] = []
    private var isFetching = false

    // MARK: - Init

    public init(context: SceneContext) {
        let s = context.settings
        bounds = context.bounds
        offline = s.bool(Self.offlineOnly)
        regenInterval = s.double(Self.artworkDuration)
        fadeDuration = s.double(Self.fade)
    }

    // MARK: - Lifecycle

    public func start(now: CFTimeInterval) {
        time = now
        prevTime = time
        regenTimer = time
        if apiQueue.isEmpty {
            fetchArtworks()
        } else {
            loadNextArtwork()
        }
    }

    /// Keeps the artwork queue: no new API call when coming back.
    public func resume(now: CFTimeInterval) {
        time = now
        prevTime = now
        regenTimer = now
        pendingRegeneration = false
        loadNextArtwork()
    }

    public func update(now: CFTimeInterval) {
        prevTime = time
        time = now
        let dt = time - prevTime

        for layer in layers {
            layer.update(dt: dt)
        }

        updateFade()

        if !layers.isEmpty && time - regenTimer > regenInterval && !isFading {
            triggerRegeneration()
        }
    }

    public func resize(to bounds: CGRect) {
        self.bounds = bounds
    }

    public func draw(in ctx: CGContext) {
        ctx.setFillColor(NSColor.black.cgColor)
        ctx.fill(bounds)

        let scale = min(bounds.width, bounds.height) / 1280
        let screenSize = bounds.size

        SceneRenderer.draw(layers, in: ctx, size: screenSize, scale: scale)

        let overlayAlpha = 1 - fadeOpacity
        if overlayAlpha > 0.001 {
            ctx.setFillColor(NSColor.black.withAlphaComponent(overlayAlpha).cgColor)
            ctx.fill(bounds)
        }
    }

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
        // Hidden layers (`visible: false`) are skipped by the factory
        layers = artwork.layers.compactMap { BaseLayer.make(from: $0) }

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

    /// Refills the queue from the API, falling back to the bundled
    /// artworks when offline (or when the offline-only setting is on).
    private func fetchArtworks() {
        guard !offline else {
            enqueue(ArtworkService.bundled())
            return
        }
        guard !isFetching else { return }
        isFetching = true
        ArtworkService.fetchRandom { [weak self] artworks in
            guard let self else { return }
            self.isFetching = false
            self.enqueue(artworks.isEmpty ? ArtworkService.bundled() : artworks)
        }
    }

    private func enqueue(_ artworks: [ArtworkData]) {
        guard !artworks.isEmpty else { return }
        apiQueue = artworks.shuffled()
        loadNextArtwork()
    }
}
