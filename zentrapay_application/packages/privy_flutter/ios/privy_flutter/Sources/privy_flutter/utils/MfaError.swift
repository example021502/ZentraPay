import Foundation

enum MfaError: LocalizedError {
    case cancelled(String)

    var errorDescription: String? {
        switch self {
        case .cancelled(let message):
            return message
        }
    }
}
