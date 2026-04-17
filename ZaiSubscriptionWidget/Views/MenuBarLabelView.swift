import SwiftUI

struct MenuBarLabelView: View {
    @ObservedObject var viewModel: UsageViewModel
    
    var body: some View {
        HStack(spacing: 7) {
            // 1. Progress Bars Group
            HStack(alignment: .bottom, spacing: 2) {
                barGroup(label: "5", limit: viewModel.quotaLimits.first { $0.isToken5HourLimit })
                barGroup(label: "w", limit: viewModel.quotaLimits.first { $0.isTokenWeeklyLimit })
                barGroup(label: "m", limit: viewModel.quotaLimits.first { $0.isTimeLimit })
            }
            
            // 2. LIMIT Section (Only if reached)
            if let reachedLimit = viewModel.quotaLimits.first(where: { $0.isReached && ($0.isToken5HourLimit || $0.isTokenWeeklyLimit || $0.isTimeLimit) }) {
                VStack(alignment: .leading, spacing: -1) {
                    Text("LIMIT")
                        .font(.system(size: 7, weight: .black))
                        .foregroundColor(.red)
                    
                    if let resetTime = reachedLimit.formattedResetTime {
                        Text(resetTime)
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(.red)
                    }
                }
            }
            
            // 3. GLM-5 Section
            VStack(alignment: .center, spacing: -1) {
                Text("GLM-5")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundColor(.secondary)
                
                Text("\(viewModel.currentCostWindow.multiplier)x")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundColor(viewModel.currentCostWindow == .peak ? .orange : .primary)
            }
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(Color.primary.opacity(0.08))
        .cornerRadius(4)
        // Ensure macOS treats the whole thing as a single renderable unit
        .compositingGroup()
    }
    
    private func barGroup(label: String, limit: QuotaLimitItem?) -> some View {
        VStack(spacing: 1) {
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 0.5)
                    .fill(Color.primary.opacity(0.2))
                    .frame(width: 3.5, height: 11)
                
                if let limit = limit {
                    RoundedRectangle(cornerRadius: 0.5)
                        .fill(progressColor(for: limit.percentageValue))
                        .frame(width: 3.5, height: 11 * min(limit.percentageValue / 100, 1))
                }
            }
            
            Text(label)
                .font(.system(size: 6, weight: .heavy))
                .foregroundColor(.primary)
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
