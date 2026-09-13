import Foundation

/// A collected lexical form or phrase and its language metadata.
public struct LexiconTerm: Codable, Hashable, Sendable {
    public var languageCode: String
    public var text: String

    /// Creates a vocabulary term.
    ///
    /// - Parameters:
    ///   - text: The collected lexical form or phrase.
    ///   - languageCode: The BCP 47 language code for the text.
    public init(text: String, languageCode: String) {
        self.languageCode = languageCode
        self.text = text
    }
}
