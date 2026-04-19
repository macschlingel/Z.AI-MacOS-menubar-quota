import Foundation

struct Account: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var apiKey: String
    var showInMenuBar: Bool = true
    
    init(id: UUID = UUID(), name: String, apiKey: String, showInMenuBar: Bool = true) {
        self.id = id
        self.name = name
        self.apiKey = apiKey
        self.showInMenuBar = showInMenuBar
    }
    
    /// Returns the API key with only the last 4 characters visible
    var obfuscatedKey: String {
        guard apiKey.count > 4 else {
            return String(repeating: "•", count: apiKey.count)
        }
        let lastFour = String(apiKey.suffix(4))
        let dots = String(repeating: "•", count: 8)
        return dots + lastFour
    }
    
    // MARK: - Hashable
    static func == (lhs: Account, rhs: Account) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
