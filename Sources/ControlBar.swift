import AppKit

// Fare pencerenin üzerine gelince alttan beliren ayar çubuğu:
// arka plan rengi + saydamlık, yazı rengi + boyutu, hız, başlat ve dosya aç.

@MainActor
final class ControlBar: NSVisualEffectView {
    struct Values {
        let backgroundColor: NSColor
        let opacity: CGFloat
        let textColor: NSColor
        let fontSize: CGFloat
        let speed: CGFloat
        let isPlaying: Bool
    }

    var onBackgroundColor: ((NSColor) -> Void)?
    var onOpacity: ((CGFloat) -> Void)?
    var onTextColor: ((NSColor) -> Void)?
    var onFontSize: ((CGFloat) -> Void)?
    var onSpeed: ((CGFloat) -> Void)?
    var onPlay: (() -> Void)?
    var onOpen: (() -> Void)?

    private let backgroundWell = NSColorWell()
    private let textWell = NSColorWell()
    private let opacitySlider: NSSlider
    private let fontSlider: NSSlider
    private let speedSlider: NSSlider
    private let playButton = NSButton()
    private let openButton = NSButton()
    private var wantsVisible = false

    /// Renk seçilirken çubuk kaybolmasın.
    private var isPickingColor: Bool {
        backgroundWell.isActive || textWell.isActive || NSColorPanel.shared.isVisible
    }

    init(fontRange: ClosedRange<CGFloat>, speedRange: ClosedRange<CGFloat>, opacityRange: ClosedRange<CGFloat>) {
        opacitySlider = Self.makeSlider(opacityRange)
        fontSlider = Self.makeSlider(fontRange)
        speedSlider = Self.makeSlider(speedRange)
        super.init(frame: .zero)
        material = .hudWindow
        blendingMode = .withinWindow
        state = .active
        appearance = NSAppearance(named: .vibrantDark)
        wantsLayer = true
        layer?.cornerRadius = 10
        translatesAutoresizingMaskIntoConstraints = false
        alphaValue = 0
        isHidden = true
        configureControls()
        layoutControls()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) kullanılmıyor") }

    func update(_ values: Values) {
        backgroundWell.color = values.backgroundColor
        textWell.color = values.textColor
        opacitySlider.doubleValue = Double(values.opacity)
        fontSlider.doubleValue = Double(values.fontSize)
        speedSlider.doubleValue = Double(values.speed)
        playButton.image = Self.symbol(values.isPlaying ? "pause.fill" : "play.fill")
    }

    func setVisible(_ visible: Bool) {
        if !visible && isPickingColor { return }
        wantsVisible = visible
        if visible { isHidden = false }
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.18
            animator().alphaValue = visible ? 1 : 0
        }, completionHandler: { [weak self] in
            MainActor.assumeIsolated {
                guard let self, !self.wantsVisible else { return }
                self.isHidden = true
            }
        })
    }

    // MARK: - Kurulum

    private static func makeSlider(_ range: ClosedRange<CGFloat>) -> NSSlider {
        let slider = NSSlider(value: Double(range.lowerBound), minValue: Double(range.lowerBound),
                              maxValue: Double(range.upperBound), target: nil, action: nil)
        slider.isContinuous = true
        slider.controlSize = .small
        slider.widthAnchor.constraint(greaterThanOrEqualToConstant: 50).isActive = true
        let preferred = slider.widthAnchor.constraint(equalToConstant: 90)
        preferred.priority = .defaultLow
        preferred.isActive = true
        return slider
    }

    private static func symbol(_ name: String) -> NSImage? {
        NSImage(systemSymbolName: name, accessibilityDescription: nil)
    }

    private static func label(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = .systemFont(ofSize: 11, weight: .medium)
        label.textColor = .secondaryLabelColor
        return label
    }

    private func configureControls() {
        NSColorPanel.shared.showsAlpha = false
        connect(backgroundWell, #selector(backgroundChanged), tip: "Arka plan rengi")
        connect(textWell, #selector(textColorChanged), tip: "Yazı rengi")
        connect(opacitySlider, #selector(opacityChanged), tip: "Arka plan saydamlığı")
        connect(fontSlider, #selector(fontChanged), tip: "Yazı boyutu")
        connect(speedSlider, #selector(speedChanged), tip: "Kaydırma hızı")
        for (button, name, tip, action) in [
            (playButton, "play.fill", "Başlat / durdur", #selector(playPressed)),
            (openButton, "doc.text", "Metin dosyası aç", #selector(openPressed)),
        ] {
            button.image = Self.symbol(name)
            button.isBordered = false
            button.contentTintColor = .white
            connect(button, action, tip: tip)
        }
    }

    private func connect(_ control: NSControl, _ action: Selector, tip: String) {
        control.target = self
        control.action = action
        control.toolTip = tip
    }

    private func layoutControls() {
        let stack = NSStackView(views: [
            Self.label("Arka plan"), backgroundWell, opacitySlider,
            Self.label("Yazı"), textWell, fontSlider,
            Self.label("Hız"), speedSlider,
            playButton, openButton,
        ])
        stack.orientation = .horizontal
        stack.alignment = .centerY
        stack.spacing = 6
        stack.edgeInsets = NSEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        [opacitySlider, fontSlider, speedSlider].forEach { stack.setCustomSpacing(16, after: $0) }
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    // MARK: - Eylemler

    @objc private func backgroundChanged() { onBackgroundColor?(backgroundWell.color) }
    @objc private func textColorChanged() { onTextColor?(textWell.color) }
    @objc private func opacityChanged() { onOpacity?(CGFloat(opacitySlider.doubleValue)) }
    @objc private func fontChanged() { onFontSize?(CGFloat(fontSlider.doubleValue.rounded())) }
    @objc private func speedChanged() { onSpeed?(CGFloat(speedSlider.doubleValue.rounded())) }
    @objc private func playPressed() { onPlay?() }
    @objc private func openPressed() { onOpen?() }
}

/// Fare pencereye girince / çıkınca haber veren kök görünüm.
final class HoverView: NSView {
    var onHoverChange: ((Bool) -> Void)?

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach(removeTrackingArea)
        addTrackingArea(NSTrackingArea(rect: .zero,
                                       options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
                                       owner: self, userInfo: nil))
    }

    override func mouseEntered(with event: NSEvent) { onHoverChange?(true) }
    override func mouseExited(with event: NSEvent) { onHoverChange?(false) }
}
