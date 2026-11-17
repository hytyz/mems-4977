import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

final class ApiService {
    static let shared = ApiService()

    private let session: URLSession
    private let lock = NSLock()
    private var storedToken: String?

    init(session: URLSession = .shared) {
        self.session = session
    }

    func setToken(_ token: String?) {
        lock.lock()
        defer { lock.unlock() }
        storedToken = token
    }

    private var token: String? {
        lock.lock()
        defer { lock.unlock() }
        return storedToken
    }

    func register(_ request: RegisterRequest) async throws -> AuthResponse {
        try await post("api/auth/register", body: request)
    }

    func login(_ request: LoginRequest) async throws -> AuthResponse {
        try await post("api/auth/login", body: request)
    }

    func firebaseToken() async throws -> FirebaseTokenResponse {
        try await get("api/auth/firebase-token")
    }

    func municipalities() async throws -> [Municipality] {
        try await get("api/municipalities")
    }

    func election(city: String) async throws -> Municipality {
        let elections: [Municipality] = try await get("api/elections", city: city)
        guard let election = elections.first else { throw ApiError.noElection(in: city) }
        return election
    }

    func positions(city: String) async throws -> [Position] {
        try await get("api/offices", city: city)
    }

    func position(id: Int, city: String) async throws -> Position {
        try await get("api/offices/\(id)", city: city)
    }

    func candidates(city: String, name: String = "") async throws -> [Candidate] {
        let query = name.trimmed
        if query.isEmpty {
            return try await get("api/candidates", city: city)
        }
        return try await get(
            "api/candidates/search",
            city: city,
            query: [URLQueryItem(name: "name", value: query)]
        )
    }

    func candidate(id: Int, city: String) async throws -> Candidate {
        try await get("api/candidates/\(id)", city: city)
    }

    private func get<T: Decodable>(
        _ path: String,
        city: String? = nil,
        query: [URLQueryItem] = []
    ) async throws -> T {
        var items = query
        if let city {
            items.append(URLQueryItem(name: "city", value: city))
        }
        let request = try makeRequest(path: path, query: items, method: "GET", body: nil)
        return try await run(request)
    }

    private func post<B: Encodable, T: Decodable>(_ path: String, body: B) async throws -> T {
        let payload: Data
        do {
            payload = try JSONCoding.encoder.encode(body)
        } catch {
            throw ApiError.encoding(underlying: error)
        }
        let request = try makeRequest(path: path, query: [], method: "POST", body: payload)
        return try await run(request)
    }

    private func makeRequest(
        path: String,
        query: [URLQueryItem],
        method: String,
        body: Data?
    ) throws -> URLRequest {
        guard var components = URLComponents(string: AppConfig.sanitizedBaseURL + "/" + path) else {
            throw ApiError.invalidURL
        }
        if !query.isEmpty {
            components.queryItems = query
        }
        guard let url = components.url else { throw ApiError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    private func run<T: Decodable>(_ request: URLRequest) async throws -> T {
        let data = try await perform(request)
        return try JSONCoding.decoder.decode(T.self, from: data)
    }

    private func perform(_ request: URLRequest) async throws -> Data {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw ApiError.transport(underlying: error)
        }
        guard let http = response as? HTTPURLResponse else {
            throw ApiError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw ApiError.http(statusCode: http.statusCode, message: ApiError.serverMessage(from: data))
        }
        return data
    }
}
