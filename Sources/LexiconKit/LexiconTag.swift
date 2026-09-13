import Foundation

/// A host-defined vocabulary classification value.
public struct LexiconTag: RawRepresentable, Codable, Hashable, Sendable {
    public let rawValue: String

    /// Creates a tag without imposing application-specific validation or normalization.
    ///
    /// - Parameter rawValue: The host-defined tag value.
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}
