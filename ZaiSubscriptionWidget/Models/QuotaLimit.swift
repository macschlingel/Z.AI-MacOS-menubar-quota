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
    
    var isReached: Bool {
        percentageValue >= 100 || (remaining ?? 1) == 0
    }
    
    var resetTimeRemaining: TimeInterval? {
        guard let resetTime = nextResetTime else { return nil }
        let date = Date(timeIntervalSince1970: Double(resetTime) / 1000.0)
        let diff = date.timeIntervalSince(Date())
        return diff > 0 ? diff : nil
    }
    
    var formattedResetTime: String? {
        guard let diff = resetTimeRemaining else { return nil }
        
        let hours = Int(diff) / 3600
        let minutes = (Int(diff) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
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
