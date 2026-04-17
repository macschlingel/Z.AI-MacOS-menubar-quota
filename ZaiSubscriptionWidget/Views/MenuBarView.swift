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
            Image(systemName: "person.badge.plus")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            
            Text("Add an Account")
                .font(.headline)
            
            Text("Add your Z.AI account in Settings to view usage.")
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
            // Account picker header
            accountPickerView
            
            Divider()
            quotaSection
            
            Divider()
            glmInfoSection
            
            if !viewModel.modelUsage.isEmpty {
                Divider()
                modelUsageSection
            }
            
            if !viewModel.toolUsage.isEmpty {
                Divider()
                toolUsageSection
            }
            
            if let error = viewModel.error {
                Divider()
                errorView(error)
            }
            
            Divider()
            footerView
        }
    }
    
    private var accountPickerView: some View {
        Group {
            if viewModel.accounts.count > 1 {
                // Show picker when multiple accounts exist
                Picker("", selection: Binding(
                    get: { viewModel.activeAccount ?? Account(name: "", apiKey: "") },
                    set: { viewModel.switchToAccount($0) }
                )) {
                    ForEach(viewModel.accounts) { account in
                        Text(account.name).tag(account)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity)
            } else if let account = viewModel.activeAccount {
                // Show single account name when only one exists
                HStack {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.secondary)
                    Text(account.name)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
    }
    
    private var quotaSection: some View {
        VStack(alignment: .leading, spacing: 12) {
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
                    
                    if limit.isReached {
                        Text("Reset in \(limit.formattedResetTime ?? "a few minutes")")
                            .font(.caption2)
                            .foregroundColor(.red)
                    }
                }
            }
        }
    }
    
    private var glmInfoSection: some View {
        let costWindow = viewModel.currentCostWindow
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("GLM-5 Usage Info")
                    .font(.headline)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: costWindow == .peak ? "flame.fill" : "leaf.fill")
                    Text("\(costWindow.multiplier)x")
                        .fontWeight(.bold)
                }
                .foregroundColor(costWindow == .peak ? .orange : .green)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Peak Hours:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("14:00 – 18:00 (UTC+8)")
                        .font(.subheadline)
                }
                
                Text(costWindow == .peak ? "Currently in peak hours (3x usage)." : "Currently off-peak (\(costWindow.multiplier)x usage).")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var modelUsageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Model Usage")
                .font(.headline)
            
            ForEach(viewModel.modelUsage) { item in
                HStack {
                    Text(item.displayName)
                        .font(.subheadline)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(item.formatNumber(item.totalTokens)) tokens")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("In: \(item.formatNumber(item.inputTokens)) · Out: \(item.formatNumber(item.outputTokens))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    private var toolUsageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tool Usage")
                .font(.headline)
            
            ForEach(viewModel.toolUsage) { item in
                HStack {
                    Text(item.displayName)
                        .font(.subheadline)
                    Spacer()
                    Text(item.formattedCallCount)
                        .font(.subheadline)
                        .fontWeight(.medium)
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
