// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import Logging

public struct VisLogHandler<Storage>: LogHandler where Storage: VisLogStorage {
    let appId: String
    let appVersion: String
    let appBuild: String
    let label: String
    let storage: Storage
    let infoProvider: VisLogHandlerInfoProvider

    public init(label: String, appId: String, appVersion: String, appBuild: String, storage: Storage, infoProvider: VisLogHandlerInfoProvider = .shared) {
        self.appId = appId
        self.appVersion = appVersion
        self.appBuild = appBuild
        self.label = label
        self.storage = storage
        self.infoProvider = infoProvider
    }

    public subscript(metadataKey key: String) -> Logger.Metadata.Value? {
        get { metadata[key] }
        set {
            metadata[key] = newValue
            print("set metadata: \(metadata)")
        }
    }

    public var metadata: Logger.Metadata = .init()

    public var logLevel: Logger.Level = .info

    public func log(level: Logger.Level, message: Logger.Message, metadata: Logger.Metadata?, source: String, file: String, function: String, line: UInt) {
        var metadata = metadata ?? [:]
        metadata.merge(self.metadata) { _, new in new }

        let formattedMetadata = (try? JSONEncoder().encode(metadata)).map { String(data: $0, encoding: .utf8) ?? "" } ?? ""

        let logItem = LogItem(
            appId: appId,
            appVersion: appVersion,
            appBuild: appBuild,
            date: .now,
            label: label,
            level: level,
            message: message.description,
            metadata: formattedMetadata,
            source: source,
            file: file,
            function: function,
            line: line,
            user: infoProvider.user(),
            deviceId: infoProvider.deviceId()
        )

        Task {
            await storage.append(item: logItem)
        }

        print(
            """
            \(logItem.date) \
            [\(level)] - \
            \(message) \
            \(formattedMetadata) \
            \(source) \
            file: \(file) \
            func: \(function) \
            line: \(line) 
            """
        )
    }
}

extension Logger.MetadataValue: @retroactive Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.description)
    }
}
