import AppKit
import Carbon.HIToolbox
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let store = NoteStore()
    private let popover = NSPopover()
    private var statusItem: NSStatusItem?
    private var hotKey: HotKey?

    func applicationDidFinishLaunching(_ notification: Notification) {
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 940, height: 560)
        popover.contentViewController = NSHostingController(rootView: ContentView(store: store))

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = BrandMark.statusItemImage(size: 18)
        item.button?.imagePosition = .imageOnly
        item.button?.target = self
        item.button?.action = #selector(statusItemClicked)
        item.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        statusItem = item

        hotKey = HotKey(keyCode: UInt32(kVK_ANSI_N), modifiers: UInt32(cmdKey | shiftKey)) { [weak self] in
            self?.togglePopover()
        }
    }

    @objc private func statusItemClicked() {
        if NSApp.currentEvent?.type == .rightMouseUp {
            showMenu()
        } else {
            togglePopover()
        }
    }

    private func togglePopover() {
        guard let button = statusItem?.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
            NSApp.activate()
        }
    }

    private func showMenu() {
        guard let button = statusItem?.button else { return }
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "About MenuBarNotes", action: #selector(showAbout), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit MenuBarNotes", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.height + 2), in: button)
    }

    @objc private func showAbout() {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev"
        NSApp.orderFrontStandardAboutPanel(options: [
            .applicationName: "MenuBarNotes",
            .applicationVersion: version,
            .version: "",
            .applicationIcon: BrandMark.appIconImage(size: 256),
            .credits: NSAttributedString(string: "Menu bar markdown notes, stored as plain files you own."),
        ])
        NSApp.activate()
    }
}
