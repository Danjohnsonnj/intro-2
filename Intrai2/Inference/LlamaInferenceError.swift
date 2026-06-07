import Foundation

enum LlamaInferenceError: Error, LocalizedError {
    case modelLoadFailed(String)
    case modelNotLoaded
    case generationFailed(String)
    case contextLimitReached(String)

    var errorDescription: String? {
        switch self {
        case .modelLoadFailed(let reason): reason
        case .modelNotLoaded: "No model is loaded."
        case .generationFailed(let reason): reason
        case .contextLimitReached(let reason): reason
        }
    }
}
