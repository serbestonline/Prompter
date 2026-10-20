import AppKit

// Düzenleme modunda ⌘C/⌘V/⌘Z gibi standart kısayolların çalışması için gereken menü.

@MainActor
enum MainMenu {
    static func make() -> NSMenu {
        let menu = NSMenu()
        menu.addItem(submenuItem(appMenu()))
        menu.addItem(submenuItem(editMenu()))
        return menu
    }

    private static func submenuItem(_ submenu: NSMenu) -> NSMenuItem {
        let item = NSMenuItem()
        item.submenu = submenu
        return item
    }

    private static func appMenu() -> NSMenu {
        let menu = NSMenu(title: "Prompter")
        menu.addItem(withTitle: "Prompter'dan Çık", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        return menu
    }

    private static func editMenu() -> NSMenu {
        let menu = NSMenu(title: "Düzen")
        menu.addItem(withTitle: "Geri Al", action: Selector(("undo:")), keyEquivalent: "z")
        let redo = menu.addItem(withTitle: "Yinele", action: Selector(("redo:")), keyEquivalent: "z")
        redo.keyEquivalentModifierMask = [.command, .shift]
        menu.addItem(.separator())
        menu.addItem(withTitle: "Kes", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        menu.addItem(withTitle: "Kopyala", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        menu.addItem(withTitle: "Yapıştır", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        menu.addItem(withTitle: "Tümünü Seç", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        return menu
    }
}
