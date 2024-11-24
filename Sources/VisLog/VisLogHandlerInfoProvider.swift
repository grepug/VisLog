import Foundation

public class VisLogHandlerInfoProvider: @unchecked Sendable {
    public static let shared = VisLogHandlerInfoProvider()

    var user: () -> String? = { nil }
    var deviceId: () -> String? = { nil }

    public func setUserProvider(_ provider: @escaping () -> String?) {
        user = provider
    }

    public func setDeviceIdProvider(_ provider: @escaping () -> String?) {
        deviceId = provider
    }

    init() {}
}
