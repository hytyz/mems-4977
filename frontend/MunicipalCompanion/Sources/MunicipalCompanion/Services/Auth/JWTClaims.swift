import Foundation

struct JWTClaims: Equatable {
    let subject: String?
    let expiresAt: Date?

    init?(token: String) {
        let segments = token.split(separator: ".")
        guard segments.count == 3,
              let payload = Self.decodeBase64URL(String(segments[1])),
              let object = (try? JSONSerialization.jsonObject(with: payload)) as? [String: Any]
        else { return nil }

        subject = object["sub"] as? String
        if let seconds = (object["exp"] as? NSNumber)?.doubleValue {
            expiresAt = Date(timeIntervalSince1970: seconds)
        } else {
            expiresAt = nil
        }
    }

    func isExpired(at date: Date = Date()) -> Bool {
        guard let expiresAt else { return false }
        return expiresAt <= date
    }

    private static func decodeBase64URL(_ value: String) -> Data? {
        var base64 = value
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 {
            base64.append("=")
        }
        return Data(base64Encoded: base64)
    }
}
