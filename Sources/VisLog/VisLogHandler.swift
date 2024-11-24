// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import Logging

public struct VisLogHandler<Storage>: LogHandler where Storage: VisLogStorage {
    var label: String
    let storage: Storage
    let infoProvider: VisLogHandlerInfoProvider

    init(label: String, storage: Storage, infoProvider: VisLogHandlerInfoProvider) {
        self.label = label
        self.storage = storage
        self.infoProvider = infoProvider
    }

    public subscript(metadataKey key: String) -> Logger.Metadata.Value? {
        get { metadata[key] }
        set { metadata[key] = newValue }
    }

    public var metadata: Logger.Metadata = .init()

    public var logLevel: Logger.Level = .info

    public func log(level: Logger.Level, message: Logger.Message, metadata: Logger.Metadata?, source: String, file: String, function: String, line: UInt) {
        let encodedMetadataString =
            metadata?.map { key, value in
                "\(key): \(value)"
            }.joined(separator: ", ") ?? ""

        let logItem = LogItem(
            date: .now,
            label: label,
            level: level,
            message: message.description,
            metadata: encodedMetadataString,
            source: source,
            file: file,
            function: function,
            line: line,
            user: infoProvider.user,
            deviceId: infoProvider.deviceId
        )

        Task {
            await storage.append(item: logItem)
        }
    }
}
