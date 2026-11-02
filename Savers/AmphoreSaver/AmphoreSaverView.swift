import ScreenSaver
import ScreensaverCore
import KinogridaKit
import ShadesKit
import PsykalaKit

/// Mixes every scene: a random scene per time slot, a different one on
/// each screen, all screens switching together through a fade to black.
@objc(AmphoreSaverView)
final class AmphoreSaverView: SaverHostView {

    // MARK: - Settings

    private static let catalog: [SceneDescriptor] = [
        KinogridaScene.descriptor,
        ShadesScene.descriptor,
        PsykalaScene.descriptor,
    ]

    private static let sceneDuration = Setting.slider(
        "amphore.sceneDuration", "Scene duration", default: 180, range: 30...1800, step: 30, unit: .seconds
    )
    private static let transition = Setting.slider(
        "amphore.transition", "Transition fade", default: 1.5, range: 0.2...5, step: 0.1, unit: .seconds
    )

    private static func enabledSetting(for scene: SceneDescriptor) -> Setting {
        .toggle("amphore.enabled.\(scene.id)", "Show \(scene.name)", default: true)
    }

    override var settingsSections: [SettingsSection] {
        let general = [Self.frameRateSetting, Self.sceneDuration, Self.transition]
            + Self.catalog.map(Self.enabledSetting)
        return [SettingsSection(title: "General", settings: general)]
            + Self.catalog.map(\.settingsSection)
    }

    // MARK: - Shared clock

    /// Every view of the process measures slots from the same origin, so
    /// all screens change scene at the same time.
    private static var anchor: CFTimeInterval = 0
    private static var runningViews = 0

    // MARK: - State

    private var scene: (any ScreensaverScene)?
    /// One instance per scene for the whole session, resumed when picked
    /// again (keeps Shades' clock intro and Psykala's fetch to the first time).
    private var instances: [String: any ScreensaverScene] = [:]
    private var slot = -1
    private var isRunning = false
    private var overlayAlpha: CGFloat = 1

    private var duration: CFTimeInterval {
        let value = settings.double(Self.sceneDuration)
        return isPreview ? min(value, 8) : value
    }

    private var screenIndex: Int {
        guard !isPreview, let screen = window?.screen else { return 0 }
        return NSScreen.screens.firstIndex(of: screen) ?? 0
    }

    // MARK: - Lifecycle

    override func didStart(now: CFTimeInterval) {
        if Self.runningViews == 0 { Self.anchor = now }
        if !isRunning { Self.runningViews += 1 }
        isRunning = true
        slot = -1
        tick(now: now)
    }

    override func didStop() {
        if isRunning { Self.runningViews -= 1 }
        isRunning = false
        scene = nil
        instances.removeAll()
        slot = -1
    }

    override func tick(now: CFTimeInterval) {
        let duration = self.duration
        let elapsed = max(0, now - Self.anchor)
        let current = Int(elapsed / duration)

        if current != slot || scene == nil {
            slot = current
            let descriptor = descriptor(for: current)
            if let paused = instances[descriptor.id] {
                paused.resume(now: now)
                scene = paused
            } else {
                let context = SceneContext(bounds: bounds, isPreview: isPreview, settings: settings)
                let next = descriptor.make(context)
                next.start(now: now)
                instances[descriptor.id] = next
                scene = next
            }
        }
        scene?.update(now: now)

        // Fade in at the start of the slot, out at its end.
        let fade = min(settings.double(Self.transition), duration / 2)
        let t = elapsed - Double(current) * duration
        if t < fade {
            overlayAlpha = CGFloat(1 - t / fade)
        } else if t > duration - fade {
            overlayAlpha = CGFloat((t - (duration - fade)) / fade)
        } else {
            overlayAlpha = 0
        }
    }

    override func render(in ctx: CGContext) {
        if let scene {
            scene.draw(in: ctx)
        } else {
            overlayAlpha = 1
        }
        if overlayAlpha > 0.001 {
            ctx.setFillColor(NSColor.black.withAlphaComponent(min(overlayAlpha, 1)).cgColor)
            ctx.fill(bounds)
        }
    }

    override func boundsDidChange() {
        for instance in instances.values {
            instance.resize(to: bounds)
        }
    }

    override func settingsDidChange() {
        guard isRunning else { return }
        scene = nil
        instances.removeAll()
        tick(now: CACurrentMediaTime())
    }

    // MARK: - Scene choice

    /// Shuffles the enabled scenes with a seed shared by every screen for
    /// this slot, then gives each screen its own entry: screens differ from
    /// each other (as long as there are enough scenes), slots are random.
    private func descriptor(for slot: Int) -> SceneDescriptor {
        let enabled = Self.catalog.filter { settings.bool(Self.enabledSetting(for: $0)) }
        let pool = enabled.isEmpty ? Self.catalog : enabled

        var rng = SplitMix64(seed: UInt64(Int(Self.anchor)) &* 0x9E37_79B9_7F4A_7C15 ^ UInt64(slot))
        let order = pool.shuffled(using: &rng)
        return order[screenIndex % order.count]
    }
}

/// Small seedable generator (the system one can't be seeded).
private struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
