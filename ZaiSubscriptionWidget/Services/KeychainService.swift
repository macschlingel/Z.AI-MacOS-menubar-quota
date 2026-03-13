import Foundation
import Security

enum KeychainError: Error {
    case encodingError
    case decodingError
    case itemNotFound
    case unexpectedStatus(OSStatus)
}

class KeychainService {
    static let shared = KeychainService()
    
    private let service = "ai.z.subscription-widget"
    private let apiKeyKey = "zai-api-key"
    
    private init() {}
    
    func saveAPIKey(_ apiKey: String) throws {
        try save(key: apiKeyKey, value: apiKey)
    }
    
    func loadAPIKey() -> String? {
        return load(key: apiKeyKey)
    }
    
    func deleteAPIKey() throws {
        try delete(key: apiKeyKey)
    }
    
    private func save(key: String, value: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.encodingError
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        _ = SecItemDelete(query as CFDictionary)
        
        let addStatus = SecItemAdd(query as CFDictionary, nil)
        
        if addStatus != errSecSuccess {
            throw KeychainError.unexpectedStatus(addStatus)
        }
    }
    
    private func load(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return value
    }
    
    private func delete(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status != errSecSuccess && status != errSecItemNotFound {
            throw KeychainError.unexpectedStatus(status)
        }
    }
}
