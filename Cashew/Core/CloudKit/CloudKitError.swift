import Foundation
import CloudKit

enum CloudKitError: LocalizedError {
    case notAuthenticated
    case networkUnavailable
    case recordNotFound
    case conversionFailed
    case operationFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please sign in to iCloud to sync your data"
        case .networkUnavailable:
            return "Network unavailable. Changes will sync when connection is restored"
        case .recordNotFound:
            return "Record not found in cloud"
        case .conversionFailed:
            return "Failed to convert cloud data"
        case .operationFailed(let error):
            return "Cloud operation failed: \(error.localizedDescription)"
        }
    }

    static func from(_ error: Error) -> CloudKitError {
        if let ckError = error as? CKError {
            switch ckError.code {
            case .notAuthenticated:
                return .notAuthenticated
            case .networkUnavailable, .networkFailure:
                return .networkUnavailable
            case .unknownItem:
                return .recordNotFound
            default:
                return .operationFailed(underlying: error)
            }
        }
        return .operationFailed(underlying: error)
    }
}
