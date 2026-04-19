import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var settingsWindow: NSWindow?
    
    @MainActor
    func showSettingsWindow() {
        if settingsWindow == nil {
            let viewModel = UsageViewModel.shared
            let settingsView = SettingsView(viewModel: viewModel)
            
            let hostingView = NSHostingView(rootView: settingsView)
            
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 450, height: 400),
                styleMask: [.titled, .closable, .resizable],
                backing: .buffered,
                defer: false
            )
            window.title = "Settings"
            window.contentView = hostingView
            window.center()
            window.isReleasedWhenClosed = false
            
            settingsWindow = window
        }
        
        if UsageViewModel.shared.showDockIcon {
            NSApp.setActivationPolicy(.regular)
        } else {
            NSApp.setActivationPolicy(.accessory)
        }
        
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }
}

@main
struct ZaiSubscriptionWidgetApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var viewModel = UsageViewModel.shared
    
    var body: some Scene {
        MenuBarExtra {
            MenuBarView(viewModel: viewModel, onOpenSettings: {
                appDelegate.showSettingsWindow()
            })
        } label: {
            MenuBarLabelView(viewModel: viewModel)
        }
        .menuBarExtraStyle(.window)
    }
}
