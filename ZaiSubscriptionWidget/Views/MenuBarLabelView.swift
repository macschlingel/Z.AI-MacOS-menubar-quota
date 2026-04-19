import SwiftUI

struct MenuBarLabelView: View {
    @ObservedObject var viewModel: UsageViewModel
    @Environment(\.displayScale) var displayScale
    
    var body: some View {
        if viewModel.showMenuBarCharts {
            if let nsImage = renderImage() {
                Image(nsImage: nsImage)
            } else {
                fallbackView
            }
        } else {
            fallbackView
        }
    }
    
    private var fallbackView: some View {
        Text("\(viewModel.currentCostWindow.multiplier)x")
            .font(.system(size: 12, weight: .bold, design: .monospaced))
    }
    
    @MainActor
    private func renderImage() -> NSImage? {
        let contentView = MenuBarLabelContentView(viewModel: viewModel)
        let renderer = ImageRenderer(content: contentView)
        renderer.scale = displayScale
        // Provide clear background rendering
        renderer.isOpaque = false
        return renderer.nsImage
    }
}

struct MenuBarLabelContentView: View {
    @ObservedObject var viewModel: UsageViewModel

    var body: some View {
        HStack(spacing: 6) {
            // 1. Mini-Balken für jeden sichtbaren Account
            let visibleAccounts = viewModel.accounts.filter { $0.showInMenuBar }
            if !visibleAccounts.isEmpty {
                HStack(spacing: 4) {
                    ForEach(visibleAccounts) { account in
                        let limits = viewModel.accountQuotaLimits[account.id] ?? []
                        HStack(alignment: .bottom, spacing: 2) {
                            barComponent(label: "5", limit: limits.first { $0.isToken5HourLimit })
                            barComponent(label: "w", limit: limits.first { $0.isTokenWeeklyLimit })
                            barComponent(label: "m", limit: limits.first { $0.isTimeLimit })
                        }
                    }
                }
            } else {
                // Fallback to active account if no specific account is configured
                HStack(alignment: .bottom, spacing: 2) {
                    barComponent(label: "5", limit: viewModel.quotaLimits.first { $0.isToken5HourLimit })
                    barComponent(label: "w", limit: viewModel.quotaLimits.first { $0.isTokenWeeklyLimit })
                    barComponent(label: "m", limit: viewModel.quotaLimits.first { $0.isTimeLimit })
                }
            }

            // 2. LIMIT Anzeige (nur wenn erreicht, aus allen geladenen Quoten)
            let allLimits = viewModel.accountQuotaLimits.values.flatMap { $0 } + viewModel.quotaLimits
            if let reachedLimit = allLimits.first(where: { $0.isReached && ($0.isToken5HourLimit || $0.isTokenWeeklyLimit || $0.isTimeLimit) }) {
                VStack(alignment: .leading, spacing: -2) {
                    Text("LIMIT")
                        .font(.system(size: 7, weight: .black))
                        .foregroundColor(.red)
                    if let time = reachedLimit.formattedResetTime {
                        Text(time)
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(.red)
                    }
                }
            }

            // 3. GLM-5 Status (if enabled)
            if viewModel.showGLMMultiplier {
                VStack(alignment: .center, spacing: -2) {
                    Text("GLM-5")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundColor(.primary)
                    Text("\(viewModel.currentCostWindow.multiplier)x")
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .foregroundColor(viewModel.currentCostWindow == .peak ? .orange : .primary)
                }
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
    }
    
    private func barComponent(label: String, limit: QuotaLimitItem?) -> some View {
        VStack(spacing: 1) {
            ZStack(alignment: .bottom) {
                Rectangle()
                    .fill(Color.primary.opacity(0.2))
                    .frame(width: 3, height: 11)
                
                if let limit = limit {
                    Rectangle()
                        .fill(progressColor(for: limit.percentageValue))
                        .frame(width: 3, height: 11 * min(limit.percentageValue / 100, 1))
                }
            }
            Text(label)
                .font(.system(size: 6, weight: .heavy))
                .foregroundColor(.primary)
        }
    }
    
    private func progressColor(for percentage: Double) -> Color {
        if percentage >= 90 { return .red }
        if percentage >= 70 { return .orange }
        return .green
    }
}
