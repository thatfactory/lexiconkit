import Foundation

/// The provenance of a vocabulary definition.
public enum LexiconDefinitionSource: String, Codable, Hashable, Sendable {
    /// Content supplied by the consuming application.
    case application

    /// Content authored or captured by the person using the application.
    case user
}
