public import Foundation

/// A persistence-friendly vocabulary entry independent of storage and presentation frameworks.
public struct LexiconEntry: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var assetReference: LexiconAssetReference?
    public var createdAt: Date
    public var definitions: [LexiconDefinition]
    public var modifiedAt: Date
    public var tags: Set<LexiconTag>
    public var term: LexiconTerm

    /// Creates a vocabulary entry.
    ///
    /// When `modifiedAt` is omitted, it begins at the same instant as `createdAt`.
    ///
    /// - Parameters:
    ///   - id: The stable entry identifier.
    ///   - term: The collected lexical form or phrase.
    ///   - definitions: The definitions associated with the term.
    ///   - tags: Optional host-defined classification tags.
    ///   - assetReference: An optional opaque reference to host-owned media.
    ///   - createdAt: The instant the entry was created.
    ///   - modifiedAt: The instant the entry was last modified.
    public init(
        id: UUID = UUID(),
        term: LexiconTerm,
        definitions: [LexiconDefinition],
        tags: Set<LexiconTag> = [],
        assetReference: LexiconAssetReference? = nil,
        createdAt: Date = Date(),
        modifiedAt: Date? = nil
    ) {
        self.id = id
        self.assetReference = assetReference
        self.createdAt = createdAt
        self.definitions = definitions
        self.modifiedAt = modifiedAt ?? createdAt
        self.tags = tags
        self.term = term
    }
}
