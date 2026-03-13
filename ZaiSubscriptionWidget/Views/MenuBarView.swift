import SwiftUI

struct MenuBarView: View {
    @ObservedObject var viewModel: UsageViewModel
    var onOpenSettings: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !viewModel.hasAPIKey {
                noAPIKeyView
            } else if viewModel.isLoading && viewModel.quotaLimits.isEmpty {
                loadingView
            } else {
                contentView
            }
        }
        .padding()
        .frame(width: 320)
        .onAppear {
            if viewModel.hasAPIKey && viewModel.quotaLimits.isEmpty {
                Task { await viewModel.refresh() }
            }
        }
    }
    
    private var noAPIKeyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "key.fill")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            
            Text("API Key Required")
                .font(.headline)
            
            Text("Add your Z.AI API key in Settings to view usage.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Open Settings") {
                onOpenSettings()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading usage data...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    private var contentView: some View {
        VStack(alignment: .leading, spacing: 16) {
            quotaSection
            
            if let error = viewModel.error {
                Divider()
                errorView(error)
            }
            
            Divider()
            footerView
        }
    }
    
    private var quotaSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Quota Usage")
                .font(.headline)
            
            ForEach(viewModel.quotaLimits.filter { $0.isToken5HourLimit || $0.isTokenWeeklyLimit || $0.isTimeLimit }) { limit in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(limit.displayType)
                            .font(.subheadline)
                        Spacer()
                        Text(limit.formattedPercentage)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.secondary.opacity(0.2))
                                .frame(height: 8)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(progressColor(for: limit.percentageValue))
                                .frame(width: geometry.size.width * min(limit.percentageValue / 100, 1), height: 8)
                        }
                    }
                    .frame(height: 8)
                }
            }
        }
    }
    
    private func errorView(_ errorMessage: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            
            Text(errorMessage)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var footerView: some View {
        HStack {
            Text("Updated: \(viewModel.formattedLastRefresh)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button(action: {
                Task { await viewModel.refresh() }
            }) {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.6)
                        .frame(width: 16, height: 16)
                } else {
                    Image(systemName: "arrow.clockwise")
                }
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isLoading)
            .help("Refresh")
            
            Button(action: {
                onOpenSettings()
            }) {
                Image(systemName: "gearshape")
            }
            .buttonStyle(.plain)
            .help("Settings")
            
            Button(action: {
                NSApp.terminate(nil)
            }) {
                Image(systemName: "power")
            }
            .buttonStyle(.plain)
            .help("Quit")
        }
    }
    
    private func progressColor(for percentage: Double) -> Color {
        if percentage >= 90 {
            return .red
        } else if percentage >= 70 {
            return .orange
        } else {
            return .green
        }
    }
}
