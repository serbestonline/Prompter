#!/bin/zsh
# Prompter.app'i derler ve simgesini üretir.
#   ./build.sh            → build/Prompter.app
#   ./build.sh --install  → ayrıca ~/Applications altına kurar
set -euo pipefail
cd "$(dirname "$0")"

APP="build/Prompter.app"
ICONSET="build/AppIcon.iconset"
ICON_PNG="build/AppIcon-1024.png"

rm -rf "$APP" "$ICONSET"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$ICONSET"

swiftc -O Sources/*.swift -o "$APP/Contents/MacOS/Prompter"

# Simge: 1024'lük PNG'den tüm boyutları üretip .icns'e çevir.
swift scripts/make_icon.swift "$ICON_PNG"
for size in 16 32 128 256 512; do
    sips -z $size $size "$ICON_PNG" --out "$ICONSET/icon_${size}x${size}.png" >/dev/null
    sips -z $((size * 2)) $((size * 2)) "$ICON_PNG" --out "$ICONSET/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>Prompter</string>
    <key>CFBundleDisplayName</key><string>Prompter</string>
    <key>CFBundleIdentifier</key><string>com.serbest.prompter</string>
    <key>CFBundleExecutable</key><string>Prompter</string>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>1.1</string>
    <key>CFBundleVersion</key><string>2</string>
    <key>LSMinimumSystemVersion</key><string>13.0</string>
    <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST

codesign --force --sign - "$APP"
echo "Derlendi: $APP"

if [[ "${1:-}" == "--install" ]]; then
    rm -rf ~/Applications/Prompter.app
    cp -R "$APP" ~/Applications/
    touch ~/Applications/Prompter.app   # Finder simgeyi yenilesin
    echo "Kuruldu: ~/Applications/Prompter.app"
fi
