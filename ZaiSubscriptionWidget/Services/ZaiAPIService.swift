import Foundation

enum APIError: Error, LocalizedError {
    case noAPIKey
    case invalidURL
    case invalidResponse
    case httpError(Int, Data?)
    case decodingError(Error)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "API key not configured. Please add your API key in Settings."
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code, _):
            return "HTTP error: \(code)"
        case .decodingError(let error):
            return "Failed to parse response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

actor ZaiAPIService {
    static let shared = ZaiAPIService()
    
    private let baseURL = "https://api.z.ai/api/monitor/usage"
    private let session: URLSession
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }
    
    func fetchModelUsage(apiKey: String) async throws -> [ModelUsageItem] {
        let endpoint = "\(baseURL)/model-usage"
        let data = try await fetch(endpoint: endpoint, apiKey: apiKey, withTimeWindow: true)
        
        do {
            let response = try JSONDecoder().decode(ModelUsageResponse.self, from: data)
            return response.data
        } catch {
            throw APIError.decodingError(error)
        }
    }
    
    func fetchToolUsage(apiKey: String) async throws -> [ToolUsageItem] {
        let endpoint = "\(baseURL)/tool-usage"
        let data = try await fetch(endpoint: endpoint, apiKey: apiKey, withTimeWindow: true)
        
        do {
            let response = try JSONDecoder().decode(ToolUsageResponse.self, from: data)
            return response.data
        } catch {
            throw APIError.decodingError(error)
        }
    }
    
    func fetchQuotaLimit(apiKey: String) async throws -> [QuotaLimitItem] {
        let endpoint = "\(baseURL)/quota/limit"
        let data = try await fetch(endpoint: endpoint, apiKey: apiKey, withTimeWindow: false)
        
        do {
            let response = try JSONDecoder().decode(QuotaLimitResponse.self, from: data)
            return response.data.limits
        } catch {
            throw APIError.decodingError(error)
        }
    }
    
    private func fetch(endpoint: String, apiKey: String, withTimeWindow: Bool) async throws -> Data {
        var urlComponents = URLComponents(string: endpoint)!
        
        if withTimeWindow {
            let (startTime, endTime) = getTimeWindow()
            urlComponents.queryItems = [
                URLQueryItem(name: "startTime", value: startTime),
                URLQueryItem(name: "endTime", value: endTime)
            ]
        }
        
        guard let url = urlComponents.url else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("en-US,en", forHTTPHeaderField: "Accept-Language")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                throw APIError.httpError(httpResponse.statusCode, data)
            }
            
            return data
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }
    
    private func getTimeWindow() -> (String, String) {
        let now = Date()
        let calendar = Calendar.current
        
        guard let startDate = calendar.date(byAdding: .day, value: -1, to: now) else {
            return ("", "")
        }
        
        let startComponents = calendar.dateComponents([.year, .month, .day, .hour], from: startDate)
        let startOfWindow = calendar.date(from: DateComponents(
            year: startComponents.year,
            month: startComponents.month,
            day: startComponents.day,
            hour: startComponents.hour,
            minute: 0,
            second: 0
        ))!
        
        let endOfWindow = calendar.date(from: DateComponents(
            year: calendar.component(.year, from: now),
            month: calendar.component(.month, from: now),
            day: calendar.component(.day, from: now),
            hour: calendar.component(.hour, from: now),
            minute: 59,
            second: 59
        ))!
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        return (formatter.string(from: startOfWindow), formatter.string(from: endOfWindow))
    }
}
