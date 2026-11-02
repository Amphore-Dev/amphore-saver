import Foundation

/// A single user-tunable value, described once and used both to build the
/// options sheet and to read the value back.
public struct Setting: Sendable {
    public enum Unit: Sendable {
        case none, seconds, percent, pixels
    }

    public enum Kind: Sendable {
        case toggle(default: Bool)
        case slider(default: Double, range: ClosedRange<Double>, step: Double, unit: Unit)
        case choice(default: Int, options: [String])
    }

    public let key: String
    public let title: String
    public let kind: Kind

    public init(key: String, title: String, kind: Kind) {
        self.key = key
        self.title = title
        self.kind = kind
    }

    public static func toggle(_ key: String, _ title: String, default value: Bool) -> Setting {
        Setting(key: key, title: title, kind: .toggle(default: value))
    }

    public static func slider(
        _ key: String, _ title: String, default value: Double,
        range: ClosedRange<Double>, step: Double, unit: Unit = .none
    ) -> Setting {
        Setting(key: key, title: title, kind: .slider(default: value, range: range, step: step, unit: unit))
    }

    public static func choice(_ key: String, _ title: String, default value: Int, options: [String]) -> Setting {
        Setting(key: key, title: title, kind: .choice(default: value, options: options))
    }

    public var defaultValue: Any {
        switch kind {
        case .toggle(let value): return value
        case .slider(let value, _, _, _): return value
        case .choice(let value, _): return value
        }
    }

    /// Clamps / snaps a raw value to what this setting accepts.
    func sanitize(_ raw: Any?) -> Any {
        switch kind {
        case .toggle(let fallback):
            return (raw as? Bool) ?? fallback
        case .slider(let fallback, let range, let step, _):
            guard let value = (raw as? NSNumber)?.doubleValue, value.isFinite else { return fallback }
            let snapped = step > 0 ? (value / step).rounded() * step : value
            return min(max(snapped, range.lowerBound), range.upperBound)
        case .choice(let fallback, let options):
            guard let value = (raw as? NSNumber)?.intValue, options.indices.contains(value) else { return fallback }
            return value
        }
    }

    public func format(_ value: Double) -> String {
        guard case .slider(_, _, let step, let unit) = kind else { return "" }
        let decimals = step < 1 ? 1 : 0
        switch unit {
        case .none:
            return String(format: "%.\(decimals)f", value)
        case .percent:
            return String(format: "%.0f %%", value)
        case .pixels:
            return String(format: "%.0f px", value)
        case .seconds:
            if value >= 60 {
                let minutes = Int(value) / 60
                let seconds = Int(value) % 60
                return seconds == 0 ? "\(minutes) min" : "\(minutes) min \(seconds) s"
            }
            return String(format: "%.\(decimals)f s", value)
        }
    }
}

/// A tab of the options sheet.
public struct SettingsSection: Sendable {
    public let title: String
    public let settings: [Setting]

    public init(title: String, settings: [Setting]) {
        self.title = title
        self.settings = settings
    }
}

/// Typed access to settings stored in a defaults domain.
@MainActor
public struct SettingsStore {
    public let defaults: UserDefaults

    public init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    public func bool(_ setting: Setting) -> Bool {
        setting.sanitize(defaults.object(forKey: setting.key)) as? Bool ?? false
    }

    public func double(_ setting: Setting) -> Double {
        setting.sanitize(defaults.object(forKey: setting.key)) as? Double ?? 0
    }

    public func int(_ setting: Setting) -> Int {
        setting.sanitize(defaults.object(forKey: setting.key)) as? Int ?? 0
    }

    func value(_ setting: Setting) -> Any {
        setting.sanitize(defaults.object(forKey: setting.key))
    }

    func set(_ value: Any, for setting: Setting) {
        defaults.set(setting.sanitize(value), forKey: setting.key)
    }
}
