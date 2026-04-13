import SwiftUI

struct MenuBarView: View {
    @ObservedObject var viewModel: UsageViewModel
    let onOpenSettings: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerView
            
            Divider()
            
            if let error = viewModel.lastError {
                errorView(error)
            } else if viewModel.quotaLimits.isEmpty {
                if viewModel.isLoading {
                    HStack {
                        Spacer()
                        ProgressView("Loading quota...")
                            .scaleEffect(0.8)
                        Spacer()
                    }
                } else {
                    Text("No quota information available.")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            } else {
                quotaSection
            }
            
            Divider()
            
            footerView
        }
        .padding()
        .frame(width: 300)
    }
    
    private var headerView: some View {
        HStack {
            Image("MenuBarIcon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Z.AI Subscription")
                    .font(.headline)
                
                if let account = viewModel.currentAccount {
                    HStack(spacing: 4) {
                        Text(account.email)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if viewModel.accounts.count > 1 {
                            Menu {
                                ForEach(viewModel.accounts) { acc in
                                    Button(acc.email) {
                                        viewModel.switchAccount(acc)
                                    }
                                }
                            } label: {
                                Image(systemName: "chevron.up.down")
                                    .font(.system(size: 8))
                                    .foregroundColor(.secondary)
                            }
                            .menuStyle(.borderlessButton)
                            .fixedSize()
                        }
                    }
                }
            }
            
            Spacer()
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
            
            // Reached limits reset indicators
            let reachedLimits = viewModel.quotaLimits.filter { ($0.isToken5HourLimit || $0.isTokenWeeklyLimit || $0.isTimeLimit) && $0.isReached }
            if !reachedLimits.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(reachedLimits) { limit in
                        HStack(spacing: 6) {
                            Image(systemName: "clock.badge.exclamationmark")
                                .foregroundColor(.red)
                                .font(.caption)
                            
                            Text("\(limit.displayType.replacingOccurrences(of: " Usage", with: "")) reset in \(limit.formattedResetTime ?? "a few minutes")")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.top, 4)
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
