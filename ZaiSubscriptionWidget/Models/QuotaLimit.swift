import Foundation

struct QuotaLimitItem: Codable, Identifiable {
    var id: String { "\(type)-\(unit ?? 0)" }
    
    let type: String
    let unit: Int?
    let number: Int?
    let usage: Int?
    let currentValue: Int?
    let remaining: Int?
    let percentage: Double?
    let nextResetTime: Int64?
    let usageDetails: [UsageDetail]?
    
    var isToken5HourLimit: Bool {
        type == "TOKENS_LIMIT" && unit == 3
    }
    
    var isTokenWeeklyLimit: Bool {
        type == "TOKENS_LIMIT" && unit == 6
    }
    
    var isTimeLimit: Bool {
        type == "TIME_LIMIT"
    }
    
    var displayType: String {
        if isTimeLimit {
            return "MCP Usage (Monthly)"
        }
        if isToken5HourLimit {
            return "Token Usage (5 Hour)"
        }
        if isTokenWeeklyLimit {
            return "Token Usage (Weekly)"
        }
        return type
    }
    
    var percentageValue: Double {
        percentage ?? 0
    }
    
    var formattedPercentage: String {
        String(format: "%.1f%%", percentageValue)
    }
}

struct UsageDetail: Codable {
    let modelCode: String
    let usage: Int
    
    var displayName: String {
        modelCode.replacingOccurrences(of: "-", with: " ").capitalized
    }
}

struct QuotaLimitsData: Codable {
    let limits: [QuotaLimitItem]
    let level: String?
}

struct QuotaLimitResponse: Codable {
    let code: Int
    let msg: String
    let data: QuotaLimitsData
    let success: Bool
}
