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
                contentRect: NSRect(x: 0, y: 0, width: 400, height: 320),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "Settings"
            window.contentView = hostingView
            window.center()
            window.isReleasedWhenClosed = false
            
            settingsWindow = window
        }
        
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }
}

@main
struct ZaiSubscriptionWidgetApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var viewModel = UsageViewModel.shared
    
    var body: some Scene {
        MenuBarExtra("Z.AI", systemImage: "gauge") {
            MenuBarView(viewModel: viewModel, onOpenSettings: {
                appDelegate.showSettingsWindow()
            })
        }
        .menuBarExtraStyle(.window)
    }
}
