import SwiftUI

struct MenuBarLabelView: View {
    @ObservedObject var viewModel: UsageViewModel
    
    var body: some View {
        HStack(spacing: 4) {
            // App Icon or Mini Bars
            HStack(spacing: 2) {
                miniProgressBar(limit: viewModel.quotaLimits.first { $0.isToken5HourLimit })
                miniProgressBar(limit: viewModel.quotaLimits.first { $0.isTokenWeeklyLimit })
                miniProgressBar(limit: viewModel.quotaLimits.first { $0.isTimeLimit })
            }
            .frame(height: 16)
            
            Text("\(viewModel.currentCostWindow.multiplier)x")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(viewModel.currentCostWindow == .peak ? .orange : .primary)
        }
    }
    
    private func miniProgressBar(limit: QuotaLimitItem?) -> some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 1)
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 3, height: 16)
            
            if let limit = limit {
                RoundedRectangle(cornerRadius: 1)
                    .fill(progressColor(for: limit.percentageValue))
                    .frame(width: 3, height: 16 * min(limit.percentageValue / 100, 1))
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
