import AppKit

/// A self-contained animation that can be hosted by any screensaver view.
///
/// Scenes are created through their `SceneDescriptor`, receive absolute
/// timestamps (`CACurrentMediaTime()`) and draw into a y-up CoreGraphics
/// context covering `bounds`. They paint their own background.
@MainActor
public protocol ScreensaverScene: AnyObject {
    /// First appearance.
    func start(now: CFTimeInterval)
    /// Back on screen after being paused (hosts keep scenes alive between
    /// appearances). Should reset time baselines and show something fresh.
    func resume(now: CFTimeInterval)
    func update(now: CFTimeInterval)
    func draw(in ctx: CGContext)
    func resize(to bounds: CGRect)
}

/// What a scene gets when it is created.
@MainActor
public struct SceneContext {
    public let bounds: CGRect
    public let isPreview: Bool
    public let settings: SettingsStore

    public init(bounds: CGRect, isPreview: Bool, settings: SettingsStore) {
        self.bounds = bounds
        self.isPreview = isPreview
        self.settings = settings
    }
}

/// Static description of a scene: identity, user settings and factory.
public struct SceneDescriptor: Sendable {
    public let id: String
    public let name: String
    public let settings: [Setting]
    public let make: @MainActor @Sendable (SceneContext) -> any ScreensaverScene

    public init(
        id: String,
        name: String,
        settings: [Setting],
        make: @escaping @MainActor @Sendable (SceneContext) -> any ScreensaverScene
    ) {
        self.id = id
        self.name = name
        self.settings = settings
        self.make = make
    }

    public var settingsSection: SettingsSection {
        SettingsSection(title: name, settings: settings)
    }
}

public enum ResourceBundle {
    /// SwiftPM's `Bundle.module` resolves against the host app
    /// (legacyScreenSaver) once a package is linked into a `.saver`, and
    /// traps when the bundle isn't found there. Look the package resource
    /// bundle up inside the bundle whose binary contains `anchor` instead.
    public static func named(_ name: String, containing anchor: AnyClass) -> Bundle? {
        let host = Bundle(for: anchor)
        let candidates = [host.resourceURL, host.bundleURL, host.bundleURL.deletingLastPathComponent()]
        for base in candidates.compactMap({ $0 }) {
            let url = base.appendingPathComponent("\(name).bundle")
            if let bundle = Bundle(url: url) { return bundle }
        }
        return nil
    }
}
