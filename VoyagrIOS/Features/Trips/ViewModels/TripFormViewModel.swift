import Foundation
import Observation

@Observable
final class TripFormViewModel {

    // MARK: - Form Fields

    var name: String = ""
    var destination: String = ""
    var startDate: Date = Date()
    var endDate: Date = Date().addingTimeInterval(86400 * 7) // 1 week default
    var notes: String = ""

    // MARK: - State

    private(set) var isSaving = false
    var error: String?
    private(set) var didSave = false

    // MARK: - Validation

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !destination.trimmingCharacters(in: .whitespaces).isEmpty &&
        endDate >= startDate
    }

    var nameError: String? {
        if name.isEmpty { return nil }
        if name.trimmingCharacters(in: .whitespaces).isEmpty {
            return "Name cannot be empty"
        }
        return nil
    }

    var destinationError: String? {
        if destination.isEmpty { return nil }
        if destination.trimmingCharacters(in: .whitespaces).isEmpty {
            return "Destination cannot be empty"
        }
        return nil
    }

    var dateError: String? {
        if endDate < startDate {
            return "End date must be after start date"
        }
        return nil
    }

    // MARK: - Dependencies

    private let tripService: TripServiceProtocol
    private let existingTrip: Trip?

    var isEditing: Bool { existingTrip != nil }

    // MARK: - Init

    init(tripService: TripServiceProtocol, trip: Trip? = nil) {
        self.tripService = tripService
        self.existingTrip = trip

        if let trip {
            self.name = trip.name
            self.destination = trip.destination
            self.startDate = trip.startDate
            self.endDate = trip.endDate
            self.notes = trip.notes
        }
    }

    // MARK: - Actions

    func save() async {
        guard isValid else { return }

        isSaving = true
        error = nil

        do {
            if let existingTrip {
                let updatedTrip = Trip(
                    id: existingTrip.id,
                    name: name.trimmingCharacters(in: .whitespaces),
                    destination: destination.trimmingCharacters(in: .whitespaces),
                    startDate: startDate,
                    endDate: endDate,
                    notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
                    coverImageURL: existingTrip.coverImageURL,
                    status: existingTrip.status,
                    createdAt: existingTrip.createdAt,
                    updatedAt: Date()
                )
                try await tripService.updateTrip(updatedTrip)
            } else {
                let newTrip = Trip(
                    name: name.trimmingCharacters(in: .whitespaces),
                    destination: destination.trimmingCharacters(in: .whitespaces),
                    startDate: startDate,
                    endDate: endDate,
                    notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
                )
                try await tripService.createTrip(newTrip)
            }
            didSave = true
        } catch {
            self.error = error.localizedDescription
        }

        isSaving = false
    }

    func clearError() {
        error = nil
    }
}
