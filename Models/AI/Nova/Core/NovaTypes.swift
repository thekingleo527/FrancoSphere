import Foundation

public struct NovaPrompt: Identifiable, Codable, Hashable {
    public let id: UUID
    public var text: String
    public var createdAt: Date

    public init(text: String, createdAt: Date = Date()) {
        self.id = UUID()
        self.text = text
        self.createdAt = createdAt
    }
}

public struct NovaContext: Codable, Hashable {
    public var data: String

    public init(data: String = "") {
        self.data = data
    }

    public static let empty = NovaContext()
}
