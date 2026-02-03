import Foundation

enum RepositoryError: LocalizedError {
    case notFound
    case saveFailed(underlying: Error)
    case loadFailed(underlying: Error)
    case deleteFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Item not found"
        case .saveFailed(let error):
            return "Failed to save: \(error.localizedDescription)"
        case .loadFailed(let error):
            return "Failed to load: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete: \(error.localizedDescription)"
        }
    }
}
