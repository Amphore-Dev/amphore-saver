import ScreenSaver

/// Base `ScreenSaverView` shared by every saver in this repo: frame rate,
/// per-bundle settings, options sheet and the macOS 14+ lifecycle quirks.
/// Subclasses implement the `did*` / `tick` / `render` hooks.
open class SaverHostView: ScreenSaverView {
    public static let frameRateSetting = Setting.choice(
        "general.fps", "Frame rate", default: 0, options: ["60 fps", "30 fps"]
    )

    public private(set) lazy var settings = SettingsStore(defaults: makeDefaults())

    private var sheet: SettingsSheet?
    private var stopObserver: NSObjectProtocol?

    public override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        applyFrameRate()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        applyFrameRate()
    }

    // MARK: - Hooks

    /// Tabs of the options sheet.
    open var settingsSections: [SettingsSection] {
        [SettingsSection(title: "General", settings: [Self.frameRateSetting])]
    }

    open func didStart(now: CFTimeInterval) {}
    open func didStop() {}
    open func tick(now: CFTimeInterval) {}
    open func render(in ctx: CGContext) {}
    open func boundsDidChange() {}
    open func settingsDidChange() {}

    // MARK: - ScreenSaverView

    open override func startAnimation() {
        super.startAnimation()
        observeScreensaverStop()
        didStart(now: CACurrentMediaTime())
    }

    open override func stopAnimation() {
        super.stopAnimation()
        didStop()
    }

    open override func animateOneFrame() {
        tick(now: CACurrentMediaTime())
        needsDisplay = true
    }

    open override func draw(_ rect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        render(in: ctx)
    }

    open override func setFrameSize(_ newSize: NSSize) {
        let changed = newSize != frame.size
        super.setFrameSize(newSize)
        if changed { boundsDidChange() }
    }

    open override var hasConfigureSheet: Bool { true }

    open override var configureSheet: NSWindow? {
        let bundle = Bundle(for: type(of: self))
        let name = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String ?? ""
        let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        let sheet = SettingsSheet(
            sections: settingsSections,
            store: settings,
            footer: "\(name) \(version)"
        ) { [weak self] in
            guard let self else { return }
            self.applyFrameRate()
            self.settingsDidChange()
        }
        self.sheet = sheet
        return sheet.window
    }

    // MARK: - Private

    private func makeDefaults() -> UserDefaults {
        let identifier = Bundle(for: type(of: self)).bundleIdentifier ?? "com.amphore-dev.amphore-saver"
        return ScreenSaverDefaults(forModuleWithName: identifier) ?? .standard
    }

    private func applyFrameRate() {
        animationTimeInterval = settings.int(Self.frameRateSetting) == 1 ? 1.0 / 30.0 : 1.0 / 60.0
    }

    /// Since macOS 14, legacyScreenSaver keeps running (and animating) old
    /// views after the screensaver is dismissed. Quit the host process when
    /// the system says the screensaver stops; it is relaunched on demand.
    private func observeScreensaverStop() {
        guard !isPreview, stopObserver == nil else { return }
        guard #available(macOS 14, *) else { return }
        stopObserver = DistributedNotificationCenter.default().addObserver(
            forName: Notification.Name("com.apple.screensaver.willstop"),
            object: nil,
            queue: .main
        ) { _ in
            exit(0)
        }
    }
}

/// Hosts a single scene: the base of the per-scene `.saver` wrappers.
open class SingleSceneSaverView: SaverHostView {
    /// Subclasses return the scene they display.
    open class var descriptor: SceneDescriptor {
        fatalError("\(self) must override `descriptor`")
    }

    private var scene: (any ScreensaverScene)?

    open override var settingsSections: [SettingsSection] {
        super.settingsSections + [type(of: self).descriptor.settingsSection]
    }

    open override func didStart(now: CFTimeInterval) {
        makeScene(now: now)
    }

    open override func didStop() {
        scene = nil
    }

    open override func tick(now: CFTimeInterval) {
        scene?.update(now: now)
    }

    open override func render(in ctx: CGContext) {
        if let scene {
            scene.draw(in: ctx)
        } else {
            ctx.setFillColor(NSColor.black.cgColor)
            ctx.fill(bounds)
        }
    }

    open override func boundsDidChange() {
        scene?.resize(to: bounds)
    }

    open override func settingsDidChange() {
        guard scene != nil else { return }
        makeScene(now: CACurrentMediaTime())
    }

    private func makeScene(now: CFTimeInterval) {
        let context = SceneContext(bounds: bounds, isPreview: isPreview, settings: settings)
        let scene = type(of: self).descriptor.make(context)
        scene.start(now: now)
        self.scene = scene
    }
}
