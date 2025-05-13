import Foundation
import Logging

public struct LogItem: Sendable, Codable {
    var id = UUID()
    let appId: String
    let appVersion: String
    let appBuild: String
    let date: Date
    let label: String
    let level: Logger.Level
    let message: String
    let metadata: String
    let source: String
    let file: String
    let function: String
    let line: UInt
    let user: String?
    let deviceId: String?
    let category: String?
}
