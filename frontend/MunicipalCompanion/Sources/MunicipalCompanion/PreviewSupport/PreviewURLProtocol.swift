#if DEBUG
import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

final class PreviewURLProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let (status, body) = Self.response(for: request)
        if let url = request.url,
           let response = HTTPURLResponse(
               url: url,
               statusCode: status,
               httpVersion: "HTTP/1.1",
               headerFields: ["Content-Type": "application/json"]
           ) {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: body)
        }
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    private static func response(for request: URLRequest) -> (status: Int, body: Data) {
        let method = request.httpMethod ?? "GET"
        let parts = (request.url?.path ?? "").split(separator: "/").map(String.init)
        guard parts.count >= 2, parts[0] == "api" else { return notFound }
        let resource = parts[1].lowercased()
        let id = parts.count > 2 ? Int(parts[2]) : nil

        let cityIds: Set<Int>? = queryValue("city", in: request.url).map { city in
            Set(PreviewData.municipalities.filter { $0.name.lowercased() == city.lowercased() }.map { $0.id })
        }
        func inCity(_ municipalityId: Int) -> Bool {
            cityIds?.contains(municipalityId) ?? true
        }

        switch (method, resource) {
        case ("POST", "auth"):
            let auth = PreviewData.auth
            return json(AuthResponse(token: auth.token, email: auth.email, fullName: auth.fullName))
        case ("GET", "auth"):
            let identity = PreviewData.identity
            return json(FirebaseTokenResponse(token: "preview-firebase-token", uid: identity.uid, email: identity.email))
        case ("GET", "municipalities"):
            return json(PreviewData.municipalities)
        case ("GET", "elections"):
            let elections = PreviewData.municipalities.filter { inCity($0.id) }.map { municipality -> Municipality in
                var election = municipality
                election.positions = PreviewData.positions.filter { $0.municipalityId == municipality.id }
                return election
            }
            return json(elections)
        case ("GET", "positions"), ("GET", "offices"):
            guard parts.count > 2 else {
                return json(PreviewData.positions.filter { inCity($0.municipalityId) })
            }
            guard var position = PreviewData.positions.first(where: { $0.id == id && inCity($0.municipalityId) }) else {
                return notFound
            }
            position.candidates = PreviewData.candidates.filter { $0.positionId == position.id }
            return json(position)
        case ("GET", "candidates"):
            let candidates = PreviewData.candidates.filter { inCity($0.municipalityId) }
            guard parts.count > 2 else { return json(candidates) }
            if parts[2].lowercased() == "search" {
                let query = (queryValue("name", in: request.url) ?? "").lowercased()
                return json(query.isEmpty ? candidates : candidates.filter { $0.name.lowercased().contains(query) })
            }
            guard let candidate = candidates.first(where: { $0.id == id }) else {
                return notFound
            }
            return json(candidate)
        default:
            return notFound
        }
    }

    private static var notFound: (status: Int, body: Data) {
        (404, Data("{\"title\":\"Not found\"}".utf8))
    }

    private static func json<T: Encodable>(_ value: T, status: Int = 200) -> (status: Int, body: Data) {
        (status, (try? JSONCoding.encoder.encode(value)) ?? Data())
    }

    private static func queryValue(_ name: String, in url: URL?) -> String? {
        url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) }?
            .queryItems?
            .first { $0.name == name }?
            .value
    }
}

extension ApiService {
    static let preview: ApiService = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [PreviewURLProtocol.self]
        return ApiService(session: URLSession(configuration: configuration))
    }()
}
#endif
