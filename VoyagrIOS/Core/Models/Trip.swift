import Foundation

struct Trip: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var name: String
    var destination: String
    var startDate: Date
    var endDate: Date
    var notes: String
    var coverImageURL: URL?
    var status: TripStatus
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        destination: String,
        startDate: Date,
        endDate: Date,
        notes: String = "",
        coverImageURL: URL? = nil,
        status: TripStatus = .planning,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.destination = destination
        self.startDate = startDate
        self.endDate = endDate
        self.notes = notes
        self.coverImageURL = coverImageURL
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
