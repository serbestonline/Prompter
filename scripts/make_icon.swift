import AppKit

// Prompter simgesini 1024×1024 PNG olarak çizer: koyu karo, üstte kamera merceği,
// ortada vurgulu okuma satırı ve yukarı-aşağı soluklaşan metin çizgileri.
// Kullanım: swift scripts/make_icon.swift <çıktı.png>

private enum Icon {
    static let canvas: CGFloat = 1024
    static let tile = NSRect(x: 100, y: 100, width: 824, height: 824)
    static let cornerRadius: CGFloat = 185
    static let top = NSColor(srgbRed: 0.13, green: 0.15, blue: 0.29, alpha: 1)
    static let bottom = NSColor(srgbRed: 0.04, green: 0.05, blue: 0.09, alpha: 1)
    static let accent = NSColor(srgbRed: 1.0, green: 0.79, blue: 0.30, alpha: 1)
    static let lineHeight: CGFloat = 44
    /// (merkez y, genişlik, opaklık); ortadaki satır vurgulu okuma satırı.
    static let lines: [(y: CGFloat, width: CGFloat, alpha: CGFloat)] = [
        (690, 500, 0.30), (600, 600, 0.55), (510, 640, 1.0), (420, 560, 0.55), (330, 420, 0.30),
    ]
    static let readingLineIndex = 2
}

private func drawTile() {
    let shape = NSBezierPath(roundedRect: Icon.tile, xRadius: Icon.cornerRadius, yRadius: Icon.cornerRadius)
    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.35)
    shadow.shadowBlurRadius = 28
    shadow.shadowOffset = NSSize(width: 0, height: -12)
    shadow.set()
    Icon.bottom.setFill()
    shape.fill()
    NSGraphicsContext.restoreGraphicsState()
    NSGradient(starting: Icon.top, ending: Icon.bottom)?.draw(in: shape, angle: -90)
}

private func drawCamera() {
    let center = NSPoint(x: Icon.canvas / 2, y: 822)
    let lens = NSBezierPath(ovalIn: NSRect(x: center.x - 26, y: center.y - 26, width: 52, height: 52))
    NSColor(srgbRed: 0.02, green: 0.02, blue: 0.04, alpha: 1).setFill()
    lens.fill()
    NSColor(srgbRed: 0.25, green: 0.28, blue: 0.42, alpha: 1).setStroke()
    lens.lineWidth = 6
    lens.stroke()
    NSColor(srgbRed: 0.45, green: 0.65, blue: 1.0, alpha: 0.75).setFill()
    NSBezierPath(ovalIn: NSRect(x: center.x + 2, y: center.y + 4, width: 14, height: 14)).fill()
}

private func drawLines() {
    let reading = Icon.lines[Icon.readingLineIndex]
    let band = NSRect(x: 160, y: reading.y - 52, width: Icon.canvas - 320, height: 104)
    NSColor.white.withAlphaComponent(0.07).setFill()
    NSBezierPath(roundedRect: band, xRadius: 28, yRadius: 28).fill()

    for (index, line) in Icon.lines.enumerated() {
        let rect = NSRect(x: (Icon.canvas - line.width) / 2, y: line.y - Icon.lineHeight / 2,
                          width: line.width, height: Icon.lineHeight)
        let color = index == Icon.readingLineIndex ? Icon.accent : NSColor.white.withAlphaComponent(line.alpha)
        color.setFill()
        NSBezierPath(roundedRect: rect, xRadius: Icon.lineHeight / 2, yRadius: Icon.lineHeight / 2).fill()
    }
}

guard CommandLine.arguments.count == 2 else {
    FileHandle.standardError.write("Kullanım: swift scripts/make_icon.swift <çıktı.png>\n".data(using: .utf8)!)
    exit(1)
}

let pixels = Int(Icon.canvas)
guard let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
                                 bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                                 colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0),
      let context = NSGraphicsContext(bitmapImageRep: rep) else {
    FileHandle.standardError.write("Görüntü tamponu oluşturulamadı\n".data(using: .utf8)!)
    exit(1)
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = context
drawTile()
drawCamera()
drawLines()
NSGraphicsContext.restoreGraphicsState()

guard let png = rep.representation(using: .png, properties: [:]) else {
    FileHandle.standardError.write("PNG üretilemedi\n".data(using: .utf8)!)
    exit(1)
}
do {
    try png.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
} catch {
    FileHandle.standardError.write("Yazılamadı: \(error.localizedDescription)\n".data(using: .utf8)!)
    exit(1)
}
