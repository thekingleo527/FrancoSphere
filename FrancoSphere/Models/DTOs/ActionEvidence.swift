import Foundation

public struct ActionEvidence: Codable, Hashable {
    public let description: String
    public let photoURLs: [URL]
    public let timestamp: Date
    
    // Photo data for local storage until cloud integration
    public let photoData: [Data]?
    
    public init(
        description: String, 
        photoURLs: [URL] = [], 
        timestamp: Date = Date(),
        photoData: [Data]? = nil
    ) {
        self.description = description
        self.photoURLs = photoURLs
        self.timestamp = timestamp
        self.photoData = photoData
    }
