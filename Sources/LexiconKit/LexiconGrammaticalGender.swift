/// A grammatical gender category associated with a lexical term.
public enum LexiconGrammaticalGender: String, Codable, Hashable, Sendable {
    /// The feminine grammatical gender.
    case feminine

    /// The masculine grammatical gender.
    case masculine

    /// The neuter grammatical gender.
    case neuter
}
