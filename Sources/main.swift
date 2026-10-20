import AppKit
import UniformTypeIdentifiers

// Kameranın hemen altında duran, her zaman üstte kalan basit bir prompter.

private enum Config {
    static let fontSize: CGFloat = 34
    static let speed: CGFloat = 40               // nokta / saniye
    static let opacity: CGFloat = 1.0            // arka plan tamamen opak
    static let fontStep: CGFloat = 2
    static let speedStep: CGFloat = 5
    static let fontRange: ClosedRange<CGFloat> = 14...120
    static let speedRange: ClosedRange<CGFloat> = 5...400
    static let opacityRange: ClosedRange<CGFloat> = 0.2...1.0
    static let widthRatio: CGFloat = 0.42        // ekran genişliğine oran
    static let heightRatio: CGFloat = 0.42       // ekran yüksekliğine oran
    static let nudgeLines: CGFloat = 3
    static let frameRate: TimeInterval = 1.0 / 60.0
    static let frameName = "PrompterWindow"
}

private enum StoreKey {
    static let fontSize = "fontSize"
    static let speed = "speed"
    static let text = "text"
    static let backgroundColor = "backgroundColor"
    static let textColor = "textColor"
    static let opacity = "backgroundOpacity"
}

private enum KeyCode {
    static let space: UInt16 = 49
    static let up: UInt16 = 126
    static let down: UInt16 = 125
    static let left: UInt16 = 123
    static let right: UInt16 = 124
    static let escape: UInt16 = 53
}

private let placeholder = """
Metne tıkla ve yaz, ⌘V ile yapıştır ya da ⌘O ile dosya aç.

Fareyi pencereye getir: alttaki çubuktan renk, saydamlık, yazı boyutu ve hız.

Space  başlat / durdur
↑ ↓  hız
+ −  yazı boyutu
← →  biraz geri / ileri
R  başa dön
Esc  düzenlemeyi bitir
"""

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

final class PrompterWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let store = UserDefaults.standard
    private var window: PrompterWindow!
    private var textView: NSTextView!
    private var hud: NSTextField!
    private var controlBar: ControlBar!
    private var clickRecognizer: NSClickGestureRecognizer!
    private var isEditingText = false
    private var timer: Timer?
    private var lastTick: CFTimeInterval = 0
    private var position: CGFloat = 0

    private var fontSize = Config.fontSize {
        didSet { store.set(Double(fontSize), forKey: StoreKey.fontSize) }
    }
    private var speed = Config.speed {
        didSet { store.set(Double(speed), forKey: StoreKey.speed); updateHUD() }
    }
    private var backgroundOpacity = Config.opacity {
        didSet { store.set(Double(backgroundOpacity), forKey: StoreKey.opacity) }
    }
    private var backgroundColor = NSColor.black {
        didSet { ColorStore.save(backgroundColor, forKey: StoreKey.backgroundColor, in: store) }
    }
    private var textColor = NSColor.white {
        didSet { ColorStore.save(textColor, forKey: StoreKey.textColor, in: store) }
    }
    private var isPlaying: Bool { timer != nil }
    private var hasScript: Bool { !(store.string(forKey: StoreKey.text) ?? "").isEmpty }
    private var clipView: NSClipView { textView.enclosingScrollView!.contentView }
    private var maxPosition: CGFloat { max(0, textView.frame.height - clipView.bounds.height) }

    func applicationDidFinishLaunching(_ notification: Notification) {
        loadSettings()
        NSApp.mainMenu = MainMenu.make()
        buildWindow()
        setText(store.string(forKey: StoreKey.text) ?? "")
        installKeyMonitor()
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    func applicationWillTerminate(_ notification: Notification) {
        if isEditingText { finishEditing() }
    }

    // MARK: - Kurulum

    private func loadSettings() {
        if store.object(forKey: StoreKey.fontSize) != nil {
            fontSize = CGFloat(store.double(forKey: StoreKey.fontSize)).clamped(to: Config.fontRange)
        }
        if store.object(forKey: StoreKey.speed) != nil {
            speed = CGFloat(store.double(forKey: StoreKey.speed)).clamped(to: Config.speedRange)
        }
        if store.object(forKey: StoreKey.opacity) != nil {
            backgroundOpacity = CGFloat(store.double(forKey: StoreKey.opacity)).clamped(to: Config.opacityRange)
        }
        if let color = ColorStore.load(forKey: StoreKey.backgroundColor, from: store) {
            backgroundColor = color
        }
        if let color = ColorStore.load(forKey: StoreKey.textColor, from: store) {
            textColor = color
        }
    }

    private func buildWindow() {
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let size = NSSize(width: screen.width * Config.widthRatio, height: screen.height * Config.heightRatio)
        let frame = NSRect(x: screen.midX - size.width / 2, y: screen.maxY - size.height,
                           width: size.width, height: size.height)

        window = PrompterWindow(contentRect: frame,
                                styleMask: [.titled, .resizable, .fullSizeContentView],
                                backing: .buffered, defer: false)
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        [.closeButton, .miniaturizeButton, .zoomButton].forEach { window.standardWindowButton($0)?.isHidden = true }
        window.isMovableByWindowBackground = true
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isOpaque = false
        applyBackground()

        let root = HoverView(frame: NSRect(origin: .zero, size: size))
        window.contentView = root
        if !window.setFrameUsingName(Config.frameName) {
            window.setFrame(frame, display: false)
        }
        window.setFrameAutosaveName(Config.frameName)

        let scrollView = NSTextView.scrollableTextView()
        scrollView.frame = root.bounds
        scrollView.autoresizingMask = [.width, .height]
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = false

        textView = scrollView.documentView as? NSTextView
        textView.drawsBackground = false
        textView.isEditable = false
        textView.isSelectable = false
        textView.isRichText = false
        textView.allowsUndo = true
        textView.textContainerInset = NSSize(width: 32, height: 48)

        clickRecognizer = NSClickGestureRecognizer(target: self, action: #selector(textClicked(_:)))
        textView.addGestureRecognizer(clickRecognizer)

        hud = NSTextField(labelWithString: "")
        hud.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        hud.textColor = NSColor.white.withAlphaComponent(0.45)
        hud.translatesAutoresizingMaskIntoConstraints = false

        controlBar = makeControlBar()
        root.onHoverChange = { [weak self] isInside in self?.setControlsVisible(isInside) }

        root.addSubview(scrollView)
        root.addSubview(hud)
        root.addSubview(controlBar)
        NSLayoutConstraint.activate([
            hud.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -12),
            hud.bottomAnchor.constraint(equalTo: root.bottomAnchor, constant: -8),
            controlBar.centerXAnchor.constraint(equalTo: root.centerXAnchor),
            controlBar.bottomAnchor.constraint(equalTo: root.bottomAnchor, constant: -10),
            controlBar.leadingAnchor.constraint(greaterThanOrEqualTo: root.leadingAnchor, constant: 10),
        ])
        window.makeKeyAndOrderFront(nil)
    }

    private func makeControlBar() -> ControlBar {
        let bar = ControlBar(fontRange: Config.fontRange, speedRange: Config.speedRange,
                             opacityRange: Config.opacityRange)
        bar.onBackgroundColor = { [weak self] color in
            self?.backgroundColor = color
            self?.applyBackground()
        }
        bar.onOpacity = { [weak self] opacity in
            self?.backgroundOpacity = opacity
            self?.applyBackground()
        }
        bar.onTextColor = { [weak self] color in
            self?.textColor = color
            self?.applyStyle()
        }
        bar.onFontSize = { [weak self] size in self?.setFontSize(size) }
        bar.onSpeed = { [weak self] speed in self?.speed = speed }
        bar.onPlay = { [weak self] in self?.togglePlay() }
        bar.onOpen = { [weak self] in self?.openFile() }
        return bar
    }

    private func setControlsVisible(_ visible: Bool) {
        controlBar.setVisible(visible)
        hud.isHidden = visible
    }

    // MARK: - Metin

    private func setText(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        store.set(trimmed, forKey: StoreKey.text)
        pause()
        textView.string = trimmed.isEmpty ? placeholder : trimmed
        applyStyle()
        jump(to: 0)
    }

    private var textAttributes: [NSAttributedString.Key: Any] {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineHeightMultiple = 1.25
        paragraph.paragraphSpacing = fontSize * 0.6
        return [
            .font: NSFont.systemFont(ofSize: fontSize, weight: .semibold),
            .foregroundColor: textColor,
            .paragraphStyle: paragraph,
        ]
    }

    private func applyStyle() {
        let attributes = textAttributes
        let fullRange = NSRange(location: 0, length: textView.string.utf16.count)
        textView.textStorage?.setAttributes(attributes, range: fullRange)
        textView.typingAttributes = attributes
        textView.insertionPointColor = textColor
        if let container = textView.textContainer {
            textView.layoutManager?.ensureLayout(for: container)
        }
        textView.sizeToFit()
        updateHUD()
    }

    private func applyBackground() {
        window.backgroundColor = backgroundColor.withAlphaComponent(backgroundOpacity)
    }

    // MARK: - Düzenleme

    @objc private func textClicked(_ recognizer: NSClickGestureRecognizer) {
        guard !isEditingText else { return }
        beginEditing(at: recognizer.location(in: textView))
    }

    private func beginEditing(at point: NSPoint) {
        let showsPlaceholder = !hasScript
        pause()
        isEditingText = true
        clickRecognizer.isEnabled = false
        if showsPlaceholder { textView.string = "" }
        textView.isSelectable = true
        textView.isEditable = true
        applyStyle()
        window.makeFirstResponder(textView)
        let index = showsPlaceholder ? 0 : textView.characterIndexForInsertion(at: point)
        textView.setSelectedRange(NSRange(location: index, length: 0))
        updateHUD()
    }

    private func finishEditing() {
        let offset = clipView.bounds.origin.y
        isEditingText = false
        textView.isEditable = false
        textView.isSelectable = false
        clickRecognizer.isEnabled = true
        window.makeFirstResponder(nil)
        let trimmed = textView.string.trimmingCharacters(in: .whitespacesAndNewlines)
        store.set(trimmed, forKey: StoreKey.text)
        if trimmed.isEmpty { textView.string = placeholder }
        applyStyle()
        jump(to: offset)
    }

    private func pasteText() {
        guard let text = NSPasteboard.general.string(forType: .string), !text.isEmpty else {
            flash("Panoda metin yok")
            return
        }
        setText(text)
    }

    private func openFile() {
        if isEditingText { finishEditing() }
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.text]
        window.level = .normal
        defer { window.level = .floating }
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            var encoding = String.Encoding.utf8
            setText(try String(contentsOf: url, usedEncoding: &encoding))
        } catch {
            flash("Dosya okunamadı: \(error.localizedDescription)")
        }
    }

    // MARK: - Kaydırma

    private func jump(to y: CGFloat) {
        position = y.clamped(to: 0...maxPosition)
        clipView.scroll(to: NSPoint(x: 0, y: position))
        textView.enclosingScrollView?.reflectScrolledClipView(clipView)
    }

    private func nudge(_ direction: CGFloat) {
        jump(to: clipView.bounds.origin.y + direction * fontSize * Config.nudgeLines)
    }

    private func togglePlay() {
        if isEditingText { finishEditing() }
        isPlaying ? pause() : play()
    }

    private func play() {
        position = clipView.bounds.origin.y
        if position >= maxPosition { jump(to: 0) }
        lastTick = CACurrentMediaTime()
        let newTimer = Timer(timeInterval: Config.frameRate, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        RunLoop.main.add(newTimer, forMode: .common)
        timer = newTimer
        updateHUD()
    }

    private func pause() {
        timer?.invalidate()
        timer = nil
        updateHUD()
    }

    private func tick() {
        let now = CACurrentMediaTime()
        let elapsed = CGFloat(now - lastTick)
        lastTick = now
        let current = clipView.bounds.origin.y
        if abs(current - position) > 2 { position = current }   // elle kaydırıldıysa oradan devam et
        jump(to: position + speed * elapsed)
        if position >= maxPosition { pause() }
    }

    private func setFontSize(_ size: CGFloat) {
        let newSize = size.clamped(to: Config.fontRange)
        guard newSize != fontSize else { return }
        position = clipView.bounds.origin.y
        let ratio = maxPosition > 0 ? position / maxPosition : 0
        fontSize = newSize
        applyStyle()
        jump(to: ratio * maxPosition)
    }

    private func changeSpeed(by delta: CGFloat) {
        speed = (speed + delta).clamped(to: Config.speedRange)
    }

    // MARK: - Klavye

    private func installKeyMonitor() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            let keyCode = event.keyCode
            let chars = event.charactersIgnoringModifiers?.lowercased() ?? ""
            let isCommand = event.modifierFlags.contains(.command)
            let handled = MainActor.assumeIsolated {
                self?.handle(keyCode: keyCode, chars: chars, isCommand: isCommand) ?? false
            }
            return handled ? nil : event
        }
    }

    private func handle(keyCode: UInt16, chars: String, isCommand: Bool) -> Bool {
        if isEditingText {
            // Düzenlerken tuşlar metne gider; yalnızca Esc düzenlemeyi bitirir.
            guard keyCode == KeyCode.escape else { return false }
            finishEditing()
            return true
        }
        if isCommand {
            return handleCommand(chars)
        }
        switch keyCode {
        case KeyCode.space: togglePlay()
        case KeyCode.up: changeSpeed(by: Config.speedStep)
        case KeyCode.down: changeSpeed(by: -Config.speedStep)
        case KeyCode.left: nudge(-1)
        case KeyCode.right: nudge(1)
        case KeyCode.escape: pause()
        default: return handleCharacter(chars)
        }
        return true
    }

    private func handleCommand(_ chars: String) -> Bool {
        switch chars {
        case "v": pasteText()
        case "o": openFile()
        case "+", "=", "*": setFontSize(fontSize + Config.fontStep)
        case "-": setFontSize(fontSize - Config.fontStep)
        default: return false
        }
        return true
    }

    private func handleCharacter(_ chars: String) -> Bool {
        switch chars {
        case "+", "=", "*": setFontSize(fontSize + Config.fontStep)
        case "-", "_": setFontSize(fontSize - Config.fontStep)
        case "r": pause(); jump(to: 0)
        default: return false
        }
        return true
    }

    // MARK: - Durum satırı

    private func updateHUD(_ message: String? = nil) {
        guard hud != nil else { return }
        if let message {
            hud.stringValue = message
        } else if isEditingText {
            hud.stringValue = "düzenleniyor  ·  bitirince Esc"
        } else {
            let state = isPlaying ? "▶" : "❚❚"
            hud.stringValue = "\(state)  hız \(Int(speed))  ·  yazı \(Int(fontSize))"
        }
        controlBar?.update(ControlBar.Values(backgroundColor: backgroundColor, opacity: backgroundOpacity,
                                             textColor: textColor, fontSize: fontSize,
                                             speed: speed, isPlaying: isPlaying))
    }

    private func flash(_ message: String) {
        updateHUD(message)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            MainActor.assumeIsolated { self?.updateHUD() }
        }
    }
}

MainActor.assumeIsolated {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    app.setActivationPolicy(.regular)
    app.run()
}
