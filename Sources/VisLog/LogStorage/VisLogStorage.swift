public protocol VisLogStorage: Sendable {
    func append(item: LogItem) async
}
