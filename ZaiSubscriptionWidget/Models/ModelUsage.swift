import Foundation

struct ModelUsageItem: Codable {
    let model: String
    let inputTokens: Int
    let outputTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case model
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
    }
    
    var totalTokens: Int {
        inputTokens + outputTokens
    }
    
    var displayName: String {
        model.uppercased()
    }
    
    var formattedInputTokens: String {
        formatNumber(inputTokens)
    }
    
    var formattedOutputTokens: String {
        formatNumber(outputTokens)
    }
    
    var formattedTotalTokens: String {
        formatNumber(totalTokens)
    }
    
    private func formatNumber(_ value: Int) -> String {
        if value >= 1_000_000 {
            return String(format: "%.1fM", Double(value) / 1_000_000)
        } else if value >= 1_000 {
            return String(format: "%.1fK", Double(value) / 1_000)
        } else {
            return "\(value)"
        }
    }
}

struct ModelUsageResponse: Codable {
    let data: [ModelUsageItem]
}
