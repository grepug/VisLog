# VisLog

A powerful logging framework built on [swift-log](https://github.com/apple/swift-log) that enables seamless log collection and management for iOS/macOS applications.

## Features

✨ Core Capabilities:
- Seamless integration with Apple's `swift-log` framework
- Automated log batching and remote server synchronization
- Comprehensive metadata collection (device, app, user info)
- Thread-safe asynchronous operations
- iOS 16+ and macOS 13+ compatibility

## Quick Start

Add to your Swift package dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/grepug/VisLog.git", from: "1.0.0")
]
```

## Usage

### Basic Setup

Bootstrap VisLog during app initialization:

```swift
LoggingSystem.bootstrap { label in
    let storage = ClientLogStorage(
        url: URL(string: "https://your-log-server.com/logs")!,
        accessTokenProvider: { "your-auth-token" }
    )
    
    return VisLogHandler(
        label: label,
        metadataProvider: .default,
        storage: storage
    )
}
```

### Advanced Configuration

Create a custom logger with enhanced metadata:

```swift
let storage = ClientLogStorage(
    url: URL(string: "https://your-log-server.com/logs")!,
    accessTokenProvider: { "your-auth-token" }
)

let logger = Logger(label: "com.example.app") { label in
    VisLogHandler(
        label: label,
        metadataProvider: .makeProvider(withKeys: {
            [
                .appId: "com.example.app",
                .deviceId: "device-uuid",
                .user: "user-id"
            ]
        }),
        storage: storage
    )
}

// Log events
logger.info("Application started")
logger.error("Error occurred", metadata: ["details": "error description"])
```

## License

Available under the MIT license. See LICENSE file for details.
