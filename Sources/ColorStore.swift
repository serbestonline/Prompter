import AppKit

// Seçilen renkleri UserDefaults'a sRGB bileşenleri olarak yazar ve geri okur.

enum ColorStore {
    static func save(_ color: NSColor, forKey key: String, in store: UserDefaults) {
        guard let rgb = color.usingColorSpace(.sRGB) else { return }
        let parts = [rgb.redComponent, rgb.greenComponent, rgb.blueComponent].map(Double.init)
        store.set(parts, forKey: key)
    }

    static func load(forKey key: String, from store: UserDefaults) -> NSColor? {
        guard let parts = store.array(forKey: key) as? [Double], parts.count == 3 else { return nil }
        return NSColor(srgbRed: parts[0], green: parts[1], blue: parts[2], alpha: 1)
    }
}
