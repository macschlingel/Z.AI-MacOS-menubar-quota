import SwiftUI

struct MenuBarLabelView: View {
    @ObservedObject var viewModel: UsageViewModel
    
    var body: some View {
        HStack(spacing: 6) {
            // Vertical Progress Bars
            HStack(alignment: .bottom, spacing: 1.5) {
                ForEach(["5", "w", "m"], id: \.self) { label in
                    VStack(spacing: 1) {
                        miniProgressBar(limit: getLimit(for: label))
                        Text(label)
                            .font(.system(size: 6, weight: .bold))
                            .foregroundColor(.primary)
                    }
                }
            }
            .padding(.trailing, 2)
            
            // LIMIT Section
            if let reachedLimit = viewModel.quotaLimits.first(where: { $0.isReached && ($0.isToken5HourLimit || $0.isTokenWeeklyLimit || $0.isTimeLimit) }) {
                VStack(alignment: .leading, spacing: -2) {
                    Text("LIMIT")
                        .font(.system(size: 7, weight: .black))
                        .foregroundColor(.red)
                    
                    if let resetTime = reachedLimit.formattedResetTime {
                        let parts = resetTime.components(separatedBy: " ")
                        HStack(spacing: 2) {
                            ForEach(parts, id: \.self) { part in
                                let value = part.filter { "0123456789".contains($0) }
                                let unit = part.filter { !"0123456789".contains($0) }
                                HStack(alignment: .bottom, spacing: 0) {
                                    Text(value)
                                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    Text(unit)
                                        .font(.system(size: 6, weight: .bold))
                                }
                                .foregroundColor(.red)
                            }
                        }
                    }
                }
            }
            
            // GLM-5 Section
            VStack(alignment: .center, spacing: -2) {
                Text("GLM-5")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundColor(.secondary)
                
                Text("\(viewModel.currentCostWindow.multiplier)x")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundColor(viewModel.currentCostWindow == .peak ? .orange : .primary)
            }
        }
        .padding(.horizontal, 4)
    }
    
    private func getLimit(for label: String) -> QuotaLimitItem? {
        switch label {
        case "5": return viewModel.quotaLimits.first { $0.isToken5HourLimit }
        case "w": return viewModel.quotaLimits.first { $0.isTokenWeeklyLimit }
        case "m": return viewModel.quotaLimits.first { $0.isTimeLimit }
        default: return nil
        }
    }
    
    private func miniProgressBar(limit: QuotaLimitItem?) -> some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 0.5)
                .fill(Color.primary.opacity(0.15))
                .frame(width: 3.5, height: 12)
            
            if let limit = limit {
                RoundedRectangle(cornerRadius: 0.5)
                    .fill(progressColor(for: limit.percentageValue))
                    .frame(width: 3.5, height: 12 * min(limit.percentageValue / 100, 1))
            }
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
