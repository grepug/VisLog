// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import Logging

public struct VisLogHandler<Storage>: LogHandler where Storage: VisLogStorage {
    let label: String
    let storage: Storage

    public var metadataProvider: Logger.MetadataProvider?

    public init(
        label: String, metadataProvider: Logger.MetadataProvider, storage: Storage
    ) {
        self.metadataProvider = metadataProvider
        self.label = label
        self.storage = storage
    }

    public subscript(metadataKey key: String) -> Logger.Metadata.Value? {
        get { metadata[key] }
        set { metadata[key] = newValue }
    }

    public var metadata: Logger.Metadata = .init()

    public var logLevel: Logger.Level = .info

    public func log(level: Logger.Level, message: Logger.Message, metadata: Logger.Metadata?, source: String, file: String, function: String, line: UInt) {
        var metadata = metadata ?? [:]
        let fromProvider = metadataProvider?.get() ?? [:]

        metadata.merge(fromProvider) { _, new in new }
        metadata.merge(self.metadata) { _, new in new }
        
        let category = metadata[Logger.MetadataProvider.CustomStringKey.category.rawValue] ?? ""
        
        metadata.removeValue(forKey: Logger.MetadataProvider.CustomStringKey.appId.rawValue)
        metadata.removeValue(forKey: Logger.MetadataProvider.CustomStringKey.deviceId.rawValue)
        metadata.removeValue(forKey: Logger.MetadataProvider.CustomStringKey.user.rawValue)
        metadata.removeValue(forKey: Logger.MetadataProvider.CustomStringKey.appVersion.rawValue)
        metadata.removeValue(forKey: Logger.MetadataProvider.CustomStringKey.appBuild.rawValue)
        metadata.removeValue(forKey: Logger.MetadataProvider.CustomStringKey.category.rawValue)

        let formattedMetadata = (try? JSONEncoder().encode(metadata)).map { String(data: $0, encoding: .utf8) ?? "" } ?? ""

        let logItem = LogItem(
            appId: metadataProvider?.getCustomStringKey(.appId) ?? "",
            appVersion: metadataProvider?.getCustomStringKey(.appVersion) ?? "",
            appBuild: metadataProvider?.getCustomStringKey(.appBuild) ?? "",
            date: Date(),
            label: label,
            level: level,
            message: message.description,
            metadata: formattedMetadata,
            source: source,
            file: file,
            function: function,
            line: line,
            user: metadataProvider?.getCustomStringKey(.user),
            deviceId: metadataProvider?.getCustomStringKey(.deviceId),
            category: "\(category)",
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

extension Logger.MetadataProvider {
    public enum CustomStringKey: String, CaseIterable {
        case user
        case appId
        case appVersion
        case appBuild
        case deviceId
        case deviceName
        case deviceModel
        case osVersion
        case category
    }

    public static func makeProvider(withKeys keys: @escaping @Sendable () -> [CustomStringKey: String?]) -> Logger.MetadataProvider {
        Logger.MetadataProvider {
            keys().reduce(into: [:]) {
                if let value = $1.value {
                    $0[$1.key.rawValue] = "\(value)"
                }
            }
        }
    }

    func getCustomStringKey(_ key: CustomStringKey) -> String? {
        self.get()[key.rawValue].map { "\($0)" }
    }
}

extension Logger.MetadataValue: @retroactive Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.description)
    }
}
