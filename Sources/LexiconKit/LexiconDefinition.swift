import Foundation

/// A textual explanation associated with a vocabulary entry.
public struct LexiconDefinition: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var languageCode: String?
    public var source: LexiconDefinitionSource
    public var text: String

    /// Creates a definition with stable identity and explicit provenance.
    ///
    /// - Parameters:
    ///   - id: The stable definition identifier.
    ///   - text: The definition text.
    ///   - languageCode: An optional BCP 47 language code for the text.
    ///   - source: The origin of the definition.
    public init(
        id: UUID = UUID(),
        text: String,
        languageCode: String? = nil,
        source: LexiconDefinitionSource
    ) {
        self.id = id
        self.languageCode = languageCode
        self.source = source
        self.text = text
    }
}
