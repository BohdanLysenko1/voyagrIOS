import Foundation
import Observation

@Observable
final class EventFormViewModel {

    // MARK: - Form Fields

    var title: String = ""
    var date: Date = Date()
    var endDate: Date?
    var hasEndDate: Bool = false
    var location: String = ""
    var notes: String = ""
    var category: EventCategory = .general
    var isAllDay: Bool = false

    // MARK: - State

    private(set) var isSaving = false
    var error: String?
    private(set) var didSave = false

    // MARK: - Validation

    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        (!hasEndDate || (endDate ?? date) >= date)
    }

    var titleError: String? {
        if title.isEmpty { return nil }
        if title.trimmingCharacters(in: .whitespaces).isEmpty {
            return "Title cannot be empty"
        }
        return nil
    }

    var dateError: String? {
        guard hasEndDate, let endDate else { return nil }
        if endDate < date {
            return "End time must be after start time"
        }
        return nil
    }

    // MARK: - Dependencies

    private let eventService: EventServiceProtocol
    private let existingEvent: Event?

    var isEditing: Bool { existingEvent != nil }

    // MARK: - Init

    init(eventService: EventServiceProtocol, event: Event? = nil) {
        self.eventService = eventService
        self.existingEvent = event

        if let event {
            self.title = event.title
            self.date = event.date
            self.endDate = event.endDate
            self.hasEndDate = event.endDate != nil
            self.location = event.location
            self.notes = event.notes
            self.category = event.category
            self.isAllDay = event.isAllDay
        }
    }

    // MARK: - Actions

    func save() async {
        guard isValid else { return }

        isSaving = true
        error = nil

        do {
            if let existingEvent {
                let updatedEvent = Event(
                    id: existingEvent.id,
                    title: title.trimmingCharacters(in: .whitespaces),
                    date: date,
                    endDate: hasEndDate ? endDate : nil,
                    location: location.trimmingCharacters(in: .whitespaces),
                    notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
                    category: category,
                    isAllDay: isAllDay,
                    createdAt: existingEvent.createdAt,
                    updatedAt: Date()
                )
                try await eventService.updateEvent(updatedEvent)
            } else {
                let newEvent = Event(
                    title: title.trimmingCharacters(in: .whitespaces),
                    date: date,
                    endDate: hasEndDate ? endDate : nil,
                    location: location.trimmingCharacters(in: .whitespaces),
                    notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
                    category: category,
                    isAllDay: isAllDay
                )
                try await eventService.createEvent(newEvent)
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
