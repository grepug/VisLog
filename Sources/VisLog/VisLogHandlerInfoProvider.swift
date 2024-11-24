import Foundation

public class VisLogHandlerInfoProvider: @unchecked Sendable {
    public static let shared = VisLogHandlerInfoProvider()

    var user: String?
    var deviceId: String?

    public func setUser(_ user: String) {
        self.user = user
    }

    public func setDeviceId(_ deviceId: String) {
        self.deviceId = deviceId
    }
}
