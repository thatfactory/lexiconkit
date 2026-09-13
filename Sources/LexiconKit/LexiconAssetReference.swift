import Foundation

/// An opaque stable reference to media owned and resolved by the host application.
public struct LexiconAssetReference: RawRepresentable, Codable, Hashable, Sendable {
    public let rawValue: String

    /// Creates an opaque host-owned asset reference.
    ///
    /// - Parameter rawValue: The stable value understood by the host application.
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}
