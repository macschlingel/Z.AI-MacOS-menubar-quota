import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: UsageViewModel
    @State private var tempAPIKey: String = ""
    @State private var showingSaveConfirmation = false
    
    var body: some View {
        TabView {
            generalTab
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
            
            aboutTab
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 400, height: 320)
        .onAppear {
            tempAPIKey = viewModel.apiKey
        }
    }
    
    private var generalTab: some View {
        Form {
            Section("API Configuration") {
                HStack {
                    SecureField("API Key", text: $tempAPIKey)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            saveAPIKey()
                        }
                    
                    Button("Save") {
                        saveAPIKey()
                    }
                    .disabled(tempAPIKey.isEmpty)
                }
                
                Text("Get your API key from z.ai/manage-apikey/apikey-list")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section("Refresh Settings") {
                Toggle("Auto Refresh", isOn: $viewModel.autoRefreshEnabled)
                
                Picker("Refresh Interval", selection: $viewModel.refreshInterval) {
                    ForEach(UsageViewModel.RefreshInterval.allCases, id: \.self) { interval in
                        Text(interval.displayName).tag(interval)
                    }
                }
                .disabled(!viewModel.autoRefreshEnabled)
            }
            
            if showingSaveConfirmation {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("API key saved successfully")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
    
    private var aboutTab: some View {
        VStack(spacing: 20) {
            Image(systemName: "gauge")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
            
            Text("Z.AI Subscription Widget")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Version 1.0")
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("Monitor your Z.AI Coding Plan usage")
                    .foregroundColor(.secondary)
                
                Link("Visit Z.AI", destination: URL(string: "https://z.ai")!)
                    .font(.callout)
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func saveAPIKey() {
        let trimmedKey = tempAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else { return }
        
        viewModel.saveAPIKey(trimmedKey)
        showingSaveConfirmation = true
        
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run {
                showingSaveConfirmation = false
            }
        }
    }
}
