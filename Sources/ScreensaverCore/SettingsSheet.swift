import AppKit

/// Options sheet built in code from `SettingsSection`s: one tab per section,
/// Reset (current tab) / Cancel / OK. Values are only written on OK.
@MainActor
final class SettingsSheet: NSObject {
    let window: NSWindow

    private let store: SettingsStore
    private let onSave: () -> Void
    private var tabView: NSTabView?
    private var bindings: [[Binding]] = []
    private var targets: [ClosureTarget] = []

    private struct Binding {
        let setting: Setting
        let read: () -> Any
        let write: (Any) -> Void
    }

    init(sections: [SettingsSection], store: SettingsStore, footer: String?, onSave: @escaping () -> Void) {
        self.store = store
        self.onSave = onSave
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 400),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        super.init()
        buildContent(sections: sections, footer: footer)
    }

    // MARK: - Layout

    // legacyScreenSaver turns unsatisfiable constraints into a fatal module
    // exception (AppKit would normally just break one). Every constraint that
    // ties our content to a view sized by someone else (tab containers,
    // window content view) is therefore optional (999).

    private func buildContent(sections: [SettingsSection], footer: String?) {
        let grids = sections.map { section -> NSView in
            var sectionBindings: [Binding] = []
            let grid = makeGrid(for: section.settings, bindings: &sectionBindings)
            bindings.append(sectionBindings)
            return grid
        }

        let body: NSView
        if grids.count == 1 {
            body = grids[0]
        } else {
            let tabs = NSTabView()
            tabs.translatesAutoresizingMaskIntoConstraints = false
            let maxHeight = grids.map { $0.fittingSize.height }.max() ?? 0
            let maxWidth = grids.map { $0.fittingSize.width }.max() ?? 0
            for (section, grid) in zip(sections, grids) {
                let item = NSTabViewItem(identifier: section.title)
                item.label = section.title
                let container = NSView(frame: NSRect(x: 0, y: 0, width: maxWidth + 40, height: maxHeight + 32))
                container.addSubview(grid)
                NSLayoutConstraint.activate([
                    grid.topAnchor.constraint(equalTo: container.topAnchor, constant: 16).optional,
                    grid.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20).optional,
                    grid.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -20).optional,
                ])
                item.view = container
                tabs.addTabViewItem(item)
            }
            NSLayoutConstraint.activate([
                tabs.heightAnchor.constraint(equalToConstant: maxHeight + 70),
                tabs.widthAnchor.constraint(equalToConstant: max(480, maxWidth + 60)),
            ])
            tabView = tabs
            body = tabs
        }

        let reset = NSButton(title: "Reset", target: self, action: #selector(resetTapped))
        let cancel = NSButton(title: "Cancel", target: self, action: #selector(cancelTapped))
        cancel.keyEquivalent = "\u{1b}"
        let ok = NSButton(title: "OK", target: self, action: #selector(okTapped))
        ok.keyEquivalent = "\r"
        let spacer = NSView()
        spacer.setContentHuggingPriority(.init(1), for: .horizontal)
        let buttons = NSStackView(views: [reset, spacer, cancel, ok])
        buttons.orientation = .horizontal

        var rows: [NSView] = [body, buttons]
        if let footer {
            let label = NSTextField(labelWithString: footer)
            label.textColor = .secondaryLabelColor
            label.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
            rows.append(label)
        }

        let stack = NSStackView(views: rows)
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 12
        stack.edgeInsets = NSEdgeInsets(top: 16, left: 20, bottom: 16, right: 20)
        stack.translatesAutoresizingMaskIntoConstraints = false
        buttons.widthAnchor.constraint(equalTo: body.widthAnchor).isActive = true

        let content = NSView()
        content.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: content.topAnchor).optional,
            stack.bottomAnchor.constraint(equalTo: content.bottomAnchor).optional,
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor).optional,
            stack.trailingAnchor.constraint(equalTo: content.trailingAnchor).optional,
        ])
        window.contentView = content
        window.setContentSize(content.fittingSize)
    }

    private func makeGrid(for settings: [Setting], bindings: inout [Binding]) -> NSView {
        var rows: [[NSView]] = []

        for setting in settings {
            let label = NSTextField(labelWithString: setting.title + ":")
            label.alignment = .right
            let current = store.value(setting)

            switch setting.kind {
            case .toggle:
                let box = NSButton(checkboxWithTitle: "", target: nil, action: nil)
                box.state = (current as? Bool ?? false) ? .on : .off
                bindings.append(Binding(
                    setting: setting,
                    read: { box.state == .on },
                    write: { box.state = ($0 as? Bool ?? false) ? .on : .off }
                ))
                rows.append([label, box, NSGridCell.emptyContentView])

            case .slider(_, let range, let step, _):
                let slider = NSSlider(
                    value: current as? Double ?? range.lowerBound,
                    minValue: range.lowerBound,
                    maxValue: range.upperBound,
                    target: nil, action: nil
                )
                slider.isContinuous = true
                slider.widthAnchor.constraint(equalToConstant: 220).isActive = true
                let valueLabel = NSTextField(labelWithString: setting.format(slider.doubleValue))
                valueLabel.font = .monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
                valueLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 90).isActive = true

                let snap: (Double) -> Double = { step > 0 ? ($0 / step).rounded() * step : $0 }
                let target = ClosureTarget { [weak slider, weak valueLabel] in
                    guard let slider else { return }
                    slider.doubleValue = snap(slider.doubleValue)
                    valueLabel?.stringValue = setting.format(slider.doubleValue)
                }
                slider.target = target
                slider.action = #selector(ClosureTarget.fire)
                targets.append(target)

                bindings.append(Binding(
                    setting: setting,
                    read: { snap(slider.doubleValue) },
                    write: {
                        slider.doubleValue = $0 as? Double ?? range.lowerBound
                        valueLabel.stringValue = setting.format(slider.doubleValue)
                    }
                ))
                rows.append([label, slider, valueLabel])

            case .choice(_, let options):
                let popup = NSPopUpButton(frame: .zero, pullsDown: false)
                popup.addItems(withTitles: options)
                popup.selectItem(at: current as? Int ?? 0)
                bindings.append(Binding(
                    setting: setting,
                    read: { popup.indexOfSelectedItem },
                    write: { popup.selectItem(at: $0 as? Int ?? 0) }
                ))
                rows.append([label, popup, NSGridCell.emptyContentView])
            }
        }

        let grid = NSGridView(views: rows)
        grid.translatesAutoresizingMaskIntoConstraints = false
        grid.rowSpacing = 10
        grid.columnSpacing = 10
        grid.rowAlignment = .firstBaseline
        grid.column(at: 0).xPlacement = .trailing
        return grid
    }

    // MARK: - Actions

    @objc private func resetTapped() {
        let index = tabView.flatMap { tabs in tabs.selectedTabViewItem.map { tabs.indexOfTabViewItem($0) } } ?? 0
        guard bindings.indices.contains(index) else { return }
        for binding in bindings[index] {
            binding.write(binding.setting.defaultValue)
        }
    }

    @objc private func cancelTapped() {
        close()
    }

    @objc private func okTapped() {
        for binding in bindings.joined() {
            store.set(binding.read(), for: binding.setting)
        }
        store.defaults.synchronize()
        close()
        onSave()
    }

    private func close() {
        // `NSApp.endSheet` does nothing under legacyScreenSaver: the sheet
        // must be ended on the window it is attached to.
        if let parent = window.sheetParent {
            parent.endSheet(window)
        } else {
            window.close()
        }
    }
}

/// Lets AppKit target/action call a Swift closure.
@MainActor
private final class ClosureTarget: NSObject {
    private let action: () -> Void

    init(_ action: @escaping () -> Void) {
        self.action = action
    }

    @objc func fire() {
        action()
    }
}

private extension NSLayoutConstraint {
    /// Same constraint at priority 999: AppKit may break it instead of failing.
    var optional: NSLayoutConstraint {
        priority = .init(999)
        return self
    }
}
