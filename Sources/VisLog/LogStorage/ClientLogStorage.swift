import Foundation

public actor ClientLogStorage: VisLogStorage {
    enum ItemState {
        case `default`
        case pending
    }

    struct ItemWrapper {
        let item: LogItem
        var state: ItemState
    }

    private var items: [ItemWrapper] = []

    public func append(item: LogItem) async {
        items.append(ItemWrapper(item: item, state: .default))
    }

    func dequeueItems() -> [LogItem] {
        let itemsToSend = items.filter { $0.state == .default }.map(\.item)
        changeDefaultsToPendings()
        return itemsToSend
    }

    private var sendTask: Task<Void, Never>?
    private let sendInterval: TimeInterval = 3.0
    private var isSending = false

    let url: URL
    let accessTokenProvider: () -> String?
    let sendLog: ((DTO) async throws -> Void)?

    public init(url: URL, accessTokenProvider: @escaping () -> String?, sendLog: ((DTO) async throws -> Void)? = nil) {
        self.url = url
        self.accessTokenProvider = accessTokenProvider
        self.sendLog = sendLog

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

    public struct DTO: Codable {
        let logItems: [LogItem]
    }

    func send() async {
        guard !isSending else { return }

        isSending = true

        let itemsToSend = dequeueItems()

        guard !itemsToSend.isEmpty else {
            isSending = false
            return
        }

        let dto = DTO(logItems: itemsToSend)

        do {
            if let sendLog = sendLog {
                try await sendLog(dto)
            } else {
                let encoder = JSONEncoder()

                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                if let token = accessTokenProvider() {
                    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                }

                request.httpBody = try? encoder.encode(dto)

                let (data, response) = try await URLSession.shared.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse,
                    (200...299).contains(httpResponse.statusCode)
                else {
                    let dataString = String(data: data, encoding: .utf8)
                    print("Error: Invalid response: " + (dataString ?? ""))

                    changePendingsToDefaults()
                    return
                }
            }

            items = items.filter { $0.state != .pending }
        } catch {
            print("Error sending logs: \(error)")

            changePendingsToDefaults()
        }

        isSending = false
    }

    func changePendingsToDefaults() {
        items = items.map { item in
            var item = item
            if item.state == .pending {
                item.state = .default
            }
            return item
        }
    }

    func changeDefaultsToPendings() {
        items = items.map { item in
            var item = item
            if item.state == .default {
                item.state = .pending
            }
            return item
        }
    }
}
