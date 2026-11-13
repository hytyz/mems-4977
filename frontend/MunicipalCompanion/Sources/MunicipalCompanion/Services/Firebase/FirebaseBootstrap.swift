import Foundation
import FirebaseCore

enum FirebaseBootstrap {
    private(set) static var isConfigured = false

    static func configure() {
        if FirebaseApp.app() != nil {
            isConfigured = true
            return
        }
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let options = FirebaseOptions(contentsOfFile: path),
              let projectID = options.projectID,
              !projectID.isEmpty,
              !projectID.hasPrefix("REPLACE"),
              !options.googleAppID.hasPrefix("REPLACE")
        else { return }

        FirebaseApp.configure(options: options)
        isConfigured = true
    }
}
