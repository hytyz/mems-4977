import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// URLSession-based REST client for the Municipal Elections API.
/// Async/await throughout; attaches "Authorization: Bearer <token>"
/// automatically whenever a token has been set (via AuthManager).
final class ApiService {
    static let shared = ApiService()

    private let session: URLSession
    private let lock = NSLock()
    private var storedToken: String?

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - Token

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

    // MARK: - Auth

    func register(_ request: RegisterRequest) async throws -> AuthResponse {
        try await post("api/auth/register", body: request, expecting: AuthResponse.self)
    }

    func login(_ request: LoginRequest) async throws -> AuthResponse {
        try await post("api/auth/login", body: request, expecting: AuthResponse.self)
    }

    // MARK: - Municipalities & Positions

    func municipalities() async throws -> [Municipality] {
        try await get("api/municipalities")
    }

    func municipality(id: Int) async throws -> Municipality {
        try await get("api/municipalities/\(id)")
    }

    func positions() async throws -> [Position] {
        try await get("api/positions")
    }

    func position(id: Int) async throws -> Position {
        try await get("api/positions/\(id)")
    }

    // MARK: - Candidates

    func candidates() async throws -> [Candidate] {
        try await get("api/candidates")
    }

    func candidate(id: Int) async throws -> Candidate {
        try await get("api/candidates/\(id)")
    }

    func searchCandidates(name: String) async throws -> [Candidate] {
        let raw = AppConfig.sanitizedBaseURL + "/api/candidates/search"
        guard var components = URLComponents(string: raw) else {
            throw ApiError.invalidURL
        }
        components.queryItems = [URLQueryItem(name: "name", value: name)]
        guard let url = components.url else { throw ApiError.invalidURL }
        let request = makeRequest(url: url, method: "GET", body: nil)
        return try await run(request)
    }

    // MARK: - Voting Guide

    func savedCandidates() async throws -> [SavedCandidate] {
        try await get("api/savedcandidates")
    }

    func saveCandidate(candidateId: Int) async throws -> SavedCandidateCreated {
        try await post(
            "api/savedcandidates",
            body: SaveCandidateRequest(candidateId: candidateId),
            expecting: SavedCandidateCreated.self
        )
    }

    func deleteSavedCandidate(id: Int) async throws {
        let request = try makeRequest(path: "api/savedcandidates/\(id)", method: "DELETE", body: nil)
        try await runNoContent(request)
    }

    // MARK: - Internals

    private func get<T: Decodable>(_ path: String) async throws -> T {
        let request = try makeRequest(path: path, method: "GET", body: nil)
        return try await run(request)
    }

    private func post<B: Encodable, T: Decodable>(
        _ path: String,
        body: B,
        expecting type: T.Type
    ) async throws -> T {
        let payload: Data
        do {
            payload = try JSONCoding.encoder.encode(body)
        } catch {
            throw ApiError.encoding(underlying: error)
        }
        let request = try makeRequest(path: path, method: "POST", body: payload)
        return try await run(request)
    }

    private func makeRequest(path: String, method: String, body: Data?) throws -> URLRequest {
        guard let url = URL(string: AppConfig.sanitizedBaseURL + "/" + path) else {
            throw ApiError.invalidURL
        }
        return makeRequest(url: url, method: method, body: body)
    }

    private func makeRequest(url: URL, method: String, body: Data?) -> URLRequest {
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
        do {
            return try JSONCoding.decoder.decode(T.self, from: data)
        } catch {
            throw ApiError.decoding(underlying: error)
        }
    }

    private func runNoContent(_ request: URLRequest) async throws {
        _ = try await perform(request)
    }

    @discardableResult
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
