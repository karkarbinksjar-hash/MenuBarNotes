import AppKit
import Carbon.HIToolbox
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    private let store = NoteStore()
    private let popover = NSPopover()
    private var statusItem: NSStatusItem?
    private var hotKey: HotKey?
    private var quickCaptureHotKey: HotKey?

    func applicationDidFinishLaunching(_ notification: Notification) {
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 940, height: 560)
        popover.delegate = self

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
        quickCaptureHotKey = HotKey(keyCode: UInt32(kVK_ANSI_N), modifiers: UInt32(optionKey | cmdKey)) { [weak self] in
            self?.quickCapture()
        }
    }

    @objc private func statusItemClicked() {
        if NSApp.currentEvent?.type == .rightMouseUp {
            showMenu()
        } else {
            togglePopover()
        }
    }

    /// The SwiftUI hierarchy is created on first open and released on close, so a
    /// hidden popover does no layout, animation, or redraw work.
    private func makeContentViewIfNeeded() {
        guard popover.contentViewController == nil else { return }
        popover.contentViewController = NSHostingController(rootView: ContentView(store: store))
    }

    private func showPopover() {
        guard let button = statusItem?.button else { return }
        guard !popover.isShown else { return }
        makeContentViewIfNeeded()
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
        NSApp.activate()
    }

    private func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            showPopover()
        }
    }

    /// ⌥⌘N: open the popover and start a fresh note from anywhere.
    private func quickCapture() {
        showPopover()
        store.newNote()
    }

    // MARK: - NSPopoverDelegate

    func popoverDidClose(_ notification: Notification) {
        store.flushSave()
        popover.contentViewController = nil
    }

    private func showMenu() {
        guard let button = statusItem?.button else { return }
        let menu = NSMenu()
        menu.addItem(menuItem("New Note (⌥⌘N)", #selector(newNoteFromMenu)))
        menu.addItem(menuItem("Open Notes Folder", #selector(openNotesFolder)))
        menu.addItem(.separator())
        menu.addItem(menuItem("About MenuBarNotes", #selector(showAbout)))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit MenuBarNotes", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.height + 2), in: button)
    }

    private func menuItem(_ title: String, _ action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        return item
    }

    @objc private func newNoteFromMenu() {
        showPopover()
        store.newNote()
    }

    @objc private func openNotesFolder() {
        NSWorkspace.shared.open(store.directory)
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
