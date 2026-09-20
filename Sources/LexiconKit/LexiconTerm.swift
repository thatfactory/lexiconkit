import Foundation

/// A collected lexical form or phrase and its language metadata.
public struct LexiconTerm: Codable, Hashable, Sendable {
    /// The term's optional grammatical gender.
    public var grammaticalGender: LexiconGrammaticalGender?

    public var languageCode: String
    public var text: String

    /// Creates a vocabulary term.
    ///
    /// - Parameters:
    ///   - text: The collected lexical form or phrase.
    ///   - languageCode: The BCP 47 language code for the text.
    ///   - grammaticalGender: An optional language-independent grammatical gender category.
    public init(
        text: String,
        languageCode: String,
        grammaticalGender: LexiconGrammaticalGender? = nil
    ) {
        self.grammaticalGender = grammaticalGender
        self.languageCode = languageCode
        self.text = text
    }
}
