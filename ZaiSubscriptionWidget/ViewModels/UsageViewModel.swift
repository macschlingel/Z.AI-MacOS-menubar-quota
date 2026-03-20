import Foundation
import Combine

@MainActor
class UsageViewModel: ObservableObject {
    static let shared = UsageViewModel()
    
    // MARK: - Account Management
    @Published var accounts: [Account] = []
    @Published var activeAccount: Account? {
        didSet {
            if let account = activeAccount {
                try? KeychainService.shared.saveActiveAccountId(account.id)
            }
        }
    }
    
    // MARK: - Usage Data
    @Published var modelUsage: [ModelUsageItem] = []
    @Published var toolUsage: [ToolUsageItem] = []
    @Published var quotaLimits: [QuotaLimitItem] = []
    
    @Published var isLoading = false
    @Published var error: String?
    @Published var lastRefresh: Date?
    
    /// Legacy property - kept for backward compatibility
    @Published var apiKey: String = "" {
        didSet {
            // No longer auto-saves to keychain - use account management instead
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
        activeAccount != nil && !activeAccount!.apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
        // Load accounts from keychain
        accounts = KeychainService.shared.loadAccounts()
        
        // Load active account ID
        if let activeId = KeychainService.shared.loadActiveAccountId() {
            activeAccount = accounts.first { $0.id == activeId }
        }
        
        // If no active account but accounts exist, use first one
        if activeAccount == nil && !accounts.isEmpty {
            activeAccount = accounts.first
        }
        
        // Migration: if old apiKey exists but no accounts, create default account
        if accounts.isEmpty, let legacyKey = KeychainService.shared.loadAPIKey(), !legacyKey.isEmpty {
            let defaultAccount = Account(name: "Default", apiKey: legacyKey)
            try? KeychainService.shared.saveAccount(defaultAccount)
            accounts = [defaultAccount]
            activeAccount = defaultAccount
            // Set apiKey for backward compatibility
            apiKey = legacyKey
        } else if let activeAccount = activeAccount {
            // Set apiKey for backward compatibility
            apiKey = activeAccount.apiKey
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
        guard hasAPIKey, let currentKey = activeAccount?.apiKey else {
            error = "No account configured"
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            self.quotaLimits = try await apiService.fetchQuotaLimit(apiKey: currentKey)
            self.lastRefresh = Date()
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Account Management Methods
    
    func addAccount(name: String, apiKey: String) {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else { return }
        
        let account = Account(name: name.trimmingCharacters(in: .whitespacesAndNewlines), apiKey: trimmedKey)
        
        do {
            try KeychainService.shared.saveAccount(account)
            accounts.append(account)
            
            // If this is the first account, make it active
            if accounts.count == 1 {
                activeAccount = account
                self.apiKey = trimmedKey
                updateTimer()
            }
        } catch {
            self.error = "Failed to save account: \(error.localizedDescription)"
        }
    }
    
    func removeAccount(_ account: Account) {
        do {
            try KeychainService.shared.deleteAccount(id: account.id)
            accounts.removeAll { $0.id == account.id }
            
            // If removed account was active, switch to another
            if activeAccount?.id == account.id {
                activeAccount = accounts.first
                if let newActive = activeAccount {
                    apiKey = newActive.apiKey
                } else {
                    apiKey = ""
                }
                updateTimer()
            }
        } catch {
            self.error = "Failed to delete account: \(error.localizedDescription)"
        }
    }
    
    func switchToAccount(_ account: Account) {
        guard accounts.contains(where: { $0.id == account.id }) else { return }
        
        activeAccount = account
        apiKey = account.apiKey
        updateTimer()
        
        // Refresh data for new account
        Task { await refresh() }
    }
    
    func updateAccount(_ account: Account) {
        do {
            try KeychainService.shared.updateAccount(account)
            
            if let index = accounts.firstIndex(where: { $0.id == account.id }) {
                accounts[index] = account
                
                // Update active account if it's the one being edited
                if activeAccount?.id == account.id {
                    activeAccount = account
                    apiKey = account.apiKey
                }
            }
        } catch {
            self.error = "Failed to update account: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Legacy Methods
    
    func saveAPIKey(_ key: String) {
        // Legacy method - creates/updates a default account
        let trimmedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else { return }
        
        if let existingAccount = accounts.first {
            // Update existing account's API key
            var updated = existingAccount
            updated.apiKey = trimmedKey
            updateAccount(updated)
        } else {
            // Create new default account
            addAccount(name: "Default", apiKey: trimmedKey)
        }
    }
}
