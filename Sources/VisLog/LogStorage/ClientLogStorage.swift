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

    init(url: URL) {
        self.url = url

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
                try? await Task.sleep(for: .seconds(sendInterval))
                await send()
            }
        }
    }

    struct DTO: Codable {
        let logItems: [LogItem]
    }

    func send() async {
        guard !items.isEmpty else { return }

        let encoder = JSONEncoder()

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let itemsToSend = await dequeueItems()
        let dto = DTO(logItems: itemsToSend)
        let data = try? encoder.encode(dto)
        request.httpBody = data

        do {
            let (_, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                (200...299).contains(httpResponse.statusCode)
            else {
                print("Error: Invalid response")
                return
            }
        } catch {
            print("Error sending logs: \(error)")
        }
    }
}
