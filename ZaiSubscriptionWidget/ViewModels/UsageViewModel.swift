import Foundation
import Combine

@MainActor
class UsageViewModel: ObservableObject {
    static let shared = UsageViewModel()
    
    @Published var modelUsage: [ModelUsageItem] = []
    @Published var toolUsage: [ToolUsageItem] = []
    @Published var quotaLimits: [QuotaLimitItem] = []
    
    @Published var isLoading = false
    @Published var error: String?
    @Published var lastRefresh: Date?
    
    @Published var apiKey: String = "" {
        didSet {
            if !apiKey.isEmpty {
                try? KeychainService.shared.saveAPIKey(apiKey)
            }
        }
    }
    
    @Published var autoRefreshEnabled = true {
        didSet {
            UserDefaults.standard.set(autoRefreshEnabled, forKey: "autoRefreshEnabled")
            updateTimer()
        }
    }
    
    @Published var refreshInterval: RefreshInterval = .fiveMinutes {
        didSet {
            UserDefaults.standard.set(refreshInterval.rawValue, forKey: "refreshInterval")
            updateTimer()
        }
    }
    
    private var refreshTimer: Timer?
    private let apiService = ZaiAPIService.shared
    
    var tokenQuotaPercentage: Double {
        quotaLimits.first { $0.isToken5HourLimit }?.percentageValue ?? 0
    }
    
    var mcpQuotaPercentage: Double {
        quotaLimits.first { $0.isTimeLimit }?.percentage ?? 0
    }
    
    var hasAPIKey: Bool {
        !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var formattedLastRefresh: String {
        guard let lastRefresh else { return "Never" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastRefresh, relativeTo: Date())
    }
    
    enum RefreshInterval: Int, CaseIterable {
        case oneMinute = 1
        case fiveMinutes = 5
        case tenMinutes = 10
        case thirtyMinutes = 30
        
        var displayName: String {
            switch self {
            case .oneMinute: return "1 minute"
            case .fiveMinutes: return "5 minutes"
            case .tenMinutes: return "10 minutes"
            case .thirtyMinutes: return "30 minutes"
            }
        }
        
        var seconds: TimeInterval {
            Double(rawValue * 60)
        }
    }
    
    private init() {
        loadSavedSettings()
        updateTimer()
    }
    
    private func loadSavedSettings() {
        if let savedKey = KeychainService.shared.loadAPIKey() {
            apiKey = savedKey
        }
        
        autoRefreshEnabled = UserDefaults.standard.bool(forKey: "autoRefreshEnabled")
        if !UserDefaults.standard.bool(forKey: "autoRefreshEnabledSet") {
            autoRefreshEnabled = true
            UserDefaults.standard.set(true, forKey: "autoRefreshEnabledSet")
        }
        
        if let intervalRaw = UserDefaults.standard.object(forKey: "refreshInterval") as? Int,
           let interval = RefreshInterval(rawValue: intervalRaw) {
            refreshInterval = interval
        }
    }
    
    private func updateTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        
        guard autoRefreshEnabled && hasAPIKey else { return }
        
        refreshTimer = Timer.scheduledTimer(withTimeInterval: refreshInterval.seconds, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.refresh()
            }
        }
    }
    
    func refresh() async {
        guard hasAPIKey else {
            error = "API key not configured"
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            self.quotaLimits = try await apiService.fetchQuotaLimit(apiKey: apiKey)
            self.lastRefresh = Date()
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func saveAPIKey(_ key: String) {
        apiKey = key
        updateTimer()
    }
}
