import Foundation

/// A lexical part of speech without imposing a language-specific closed vocabulary.
public enum LexiconPartOfSpeech: Hashable, Sendable {
    /// A noun entry.
    case noun

    /// Another source-defined part of speech.
    case other(String)
}

/// One model-provided definition gloss.
public struct LexiconModelGloss: Equatable, Hashable, Sendable {
    public let languageCode: String
    public let text: String

    public init(languageCode: String, text: String) {
        self.languageCode = languageCode
        self.text = text
    }
}

/// One lexical sense returned from an immutable model.
public struct LexiconModelSense: Equatable, Hashable, Sendable {
    public let glosses: [LexiconModelGloss]
    public let grammaticalGender: LexiconGrammaticalGender?
    public let lemma: String
    public let partOfSpeech: LexiconPartOfSpeech

    public init(
        lemma: String,
        partOfSpeech: LexiconPartOfSpeech,
        grammaticalGender: LexiconGrammaticalGender?,
        glosses: [LexiconModelGloss]
    ) {
        self.glosses = glosses
        self.grammaticalGender = grammaticalGender
        self.lemma = lemma
        self.partOfSpeech = partOfSpeech
    }
}

/// The exact candidates returned by a model lookup.
public enum LexiconModelLookupResult: Equatable, Sendable {
    case multiple([LexiconModelSense])
    case notFound
    case unique(LexiconModelSense)
}

/// Stable errors raised while opening or reading an immutable model.
public enum LexiconModelError: Error, Equatable, Sendable {
    case corruptArtifact(String)
    case unsupportedFormat(UInt32)
}
