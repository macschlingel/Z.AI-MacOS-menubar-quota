import Foundation

struct ToolUsageItem: Codable {
    let tool: String
    let callCount: Int
    
    enum CodingKeys: String, CodingKey {
        case tool
        case callCount = "call_count"
    }
    
    var displayName: String {
        tool.replacingOccurrences(of: "_", with: " ").capitalized
    }
    
    var formattedCallCount: String {
        if callCount >= 1_000_000 {
            return String(format: "%.1fM", Double(callCount) / 1_000_000)
        } else if callCount >= 1_000 {
            return String(format: "%.1fK", Double(callCount) / 1_000)
        } else {
            return "\(callCount)"
        }
    }
}

struct ToolUsageResponse: Codable {
    let data: [ToolUsageItem]
}
