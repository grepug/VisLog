import Foundation

public actor ClientLogStorage: VisLogStorage {
    private var items: [LogItem] = []

    public func append(item: LogItem) async {
        items.append(item)
    }

    func dequeueItems() async -> [LogItem] {
        let itemsToSend = items
        items = []
        return itemsToSend
    }

    private var sendTask: Task<Void, Never>?
    private let sendInterval: TimeInterval = 3.0

    let url: URL
    let accessTokenProvider: () -> String?
    let dtoEntryptionProvider: (Data) -> Data

    public init(url: URL, accessTokenProvider: @escaping () -> String?, dtoEntryptionProvider: @escaping (Data) -> Data = { $0 }) {
        self.url = url
        self.accessTokenProvider = accessTokenProvider
        self.dtoEntryptionProvider = dtoEntryptionProvider

        Task {
            await startSendTimer()
        }
    }

    deinit {
        sendTask?.cancel()
    }

    private func startSendTimer() {
        sendTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(sendInterval * 1_000_000_000))
                await send()
            }
        }
    }

    struct DTO: Codable {
        let logItems: [LogItem]
    }

    func send() async {
        guard !items.isEmpty else { return }
        guard let token = accessTokenProvider() else { return }

        let encoder = JSONEncoder()

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let itemsToSend = await dequeueItems()
        let dto = DTO(logItems: itemsToSend)
        let data = try? encoder.encode(dto)

        guard let data = data else { return }

        request.httpBody = dtoEntryptionProvider(data)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                (200...299).contains(httpResponse.statusCode)
            else {
                let dataString = String(data: data, encoding: .utf8)
                print("Error: Invalid response: " + (dataString ?? ""))
                return
            }
        } catch {
            print("Error sending logs: \(error)")
        }
    }
}
