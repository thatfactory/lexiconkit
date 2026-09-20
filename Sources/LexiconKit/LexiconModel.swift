import CryptoKit
public import Foundation

/// A synchronous, read-only lexical model backed by a mapped immutable artifact.
public final class LexiconModel: @unchecked Sendable {
    private static let headerSize = 256
    private static let magic = Data("TFLEX001".utf8)

    private let counts: [Int]
    private let data: Data
    private let sections: [(offset: Int, length: Int)]

    /// The model's BCP 47 language code.
    public let languageCode: String

    /// The semantic model version.
    public let modelVersion: Int

    /// The runtime schema version.
    public let schemaVersion: Int

    /// Opens and maps an immutable model without scanning or deserializing its corpus.
    public init(contentsOf modelURL: URL, manifestURL: URL) throws {
        do {
            let manifest = try JSONDecoder().decode(
                Manifest.self,
                from: Data(contentsOf: manifestURL)
            )
            let data = try Data(contentsOf: modelURL, options: .mappedIfSafe)
            guard data.count >= Self.headerSize, data.prefix(8) == Self.magic else {
                throw LexiconModelError.corruptArtifact("header")
            }
            let formatVersion = Self.uint32(data, at: 8)
            guard formatVersion == 1 else {
                throw LexiconModelError.unsupportedFormat(formatVersion)
            }
            let schemaVersion = Self.uint32(data, at: 12)
            let modelVersion = Self.uint32(data, at: 16)
            guard schemaVersion == 1 else {
                throw LexiconModelError.unsupportedFormat(schemaVersion)
            }
            guard Int64(data.count) == manifest.artifact.byteCount,
                Int(schemaVersion) == manifest.schemaVersion,
                Int(modelVersion) == manifest.modelVersion
            else { throw LexiconModelError.corruptArtifact("manifest-metadata") }

            var counts: [Int] = []
            for index in 0..<6 {
                guard let count = Int(exactly: Self.uint64(data, at: 24 + index * 8)) else {
                    throw LexiconModelError.corruptArtifact("record-count")
                }
                counts.append(count)
            }
            var sections: [(offset: Int, length: Int)] = []
            for index in 0..<7 {
                guard
                    let offset = Int(exactly: Self.uint64(data, at: 72 + index * 16)),
                    let length = Int(exactly: Self.uint64(data, at: 80 + index * 16)),
                    offset >= Self.headerSize,
                    length >= 0,
                    offset <= data.count,
                    length <= data.count - offset
                else { throw LexiconModelError.corruptArtifact("section-bounds") }
                sections.append((offset, length))
            }
            guard Self.hasRecordLayout(sections[0].length, count: counts[5], stride: 8),
                Self.hasRecordLayout(sections[2].length, count: counts[0], stride: 16),
                Self.hasRecordLayout(sections[3].length, count: counts[1], stride: 12),
                Self.hasRecordLayout(sections[4].length, count: counts[2], stride: 12),
                Self.hasRecordLayout(sections[5].length, count: counts[3], stride: 12),
                Self.hasRecordLayout(sections[6].length, count: counts[4], stride: 8)
            else { throw LexiconModelError.corruptArtifact("section-length") }

            self.counts = counts
            self.data = data
            self.languageCode = manifest.languageCode
            self.modelVersion = Int(modelVersion)
            self.schemaVersion = Int(schemaVersion)
            self.sections = sections
            LexiconLogging.modelOpened()
        } catch {
            LexiconLogging.modelOpenFailed()
            throw error
        }
    }

    /// Performs the full checksum verification intended for CI, tests, or downloaded-resource installation.
    public static func verifyArtifact(at modelURL: URL, against manifestURL: URL) throws {
        let manifest = try JSONDecoder().decode(
            Manifest.self,
            from: Data(contentsOf: manifestURL)
        )
        let attributes = try FileManager.default.attributesOfItem(atPath: modelURL.path)
        guard (attributes[.size] as? NSNumber)?.int64Value == manifest.artifact.byteCount else {
            throw LexiconModelError.corruptArtifact("artifact-byte-count")
        }
        let handle = try FileHandle(forReadingFrom: modelURL)
        defer { try? handle.close() }
        var hasher = SHA256()
        while let bytes = try handle.read(upToCount: 1_048_576), !bytes.isEmpty {
            hasher.update(data: bytes)
        }
        let digest = hasher.finalize().map { String(format: "%02x", $0) }.joined()
        guard digest == manifest.artifact.sha256 else {
            throw LexiconModelError.corruptArtifact("artifact-checksum")
        }
    }

    /// Returns all exact lexical senses for a lemma, source form, or generated alias.
    public func lookup(_ term: String) throws -> LexiconModelLookupResult {
        let normalizedTerm = term.trimmingCharacters(in: .whitespacesAndNewlines)
            .precomposedStringWithCanonicalMapping
        guard !normalizedTerm.isEmpty else { return .notFound }
        let postings = try postings(for: normalizedTerm)
        let exact = postings.filter { ($0.flags & 3) != 0 }
        return try result(for: exact.isEmpty ? postings : exact)
    }

    /// Narrows exact term candidates to senses with an exact normalized gloss in an allowed language.
    public func matchSense(
        for term: String,
        gloss: String,
        languageCodes: Set<String>
    ) throws -> LexiconModelLookupResult {
        let termResult = try lookup(term)
        let candidates: [LexiconModelSense]
        switch termResult {
        case .multiple(let senses): candidates = senses
        case .notFound: return .notFound
        case .unique(let sense): candidates = [sense]
        }
        let normalized = Self.normalizedGloss(gloss)
        let matched = candidates.filter { candidate in
            candidate.glosses.contains { modelGloss in
                languageCodes.contains(modelGloss.languageCode)
                    && Self.normalizedGloss(modelGloss.text) == normalized
            }
        }
        return Self.result(for: matched)
    }

    // MARK: - Private

    private func result(for postings: [(lexeme: UInt32, flags: UInt8)]) throws -> LexiconModelLookupResult {
        var matchedSenses: [LexiconModelSense] = []
        for posting in postings {
            matchedSenses.append(contentsOf: try senses(forLexeme: posting.lexeme))
        }
        return Self.result(for: matchedSenses)
    }

    private static func result(for senses: [LexiconModelSense]) -> LexiconModelLookupResult {
        switch senses.count {
        case 0: .notFound
        case 1: .unique(senses[0])
        default: .multiple(senses)
        }
    }

    private func postings(for term: String) throws -> [(lexeme: UInt32, flags: UInt8)] {
        var low = 0
        var high = counts[3]
        while low < high {
            let middle = (low + high) / 2
            let text = try string(try uint32(inSection: 5, record: middle, stride: 12, field: 0))
            if text.utf8.lexicographicallyPrecedes(term.utf8) { low = middle + 1 } else { high = middle }
        }
        guard low < counts[3] else { return [] }
        let key = try string(try uint32(inSection: 5, record: low, stride: 12, field: 0))
        guard key == term else { return [] }
        let start = Int(try uint32(inSection: 5, record: low, stride: 12, field: 4))
        let count = Int(try uint32(inSection: 5, record: low, stride: 12, field: 8))
        guard start <= counts[4], count <= counts[4] - start else {
            throw LexiconModelError.corruptArtifact("posting-range")
        }
        return try (start..<(start + count)).map { index in
            let value = try uint64(inSection: 6, record: index, stride: 8, field: 0)
            let lexeme = UInt32(truncatingIfNeeded: value)
            let flags = UInt8(truncatingIfNeeded: value >> 32)
            guard Int(lexeme) < counts[0], flags != 0, flags & ~7 == 0 else {
                throw LexiconModelError.corruptArtifact("posting")
            }
            return (lexeme, flags)
        }
    }

    private func senses(forLexeme lexemeID: UInt32) throws -> [LexiconModelSense] {
        guard Int(lexemeID) < counts[0] else {
            throw LexiconModelError.corruptArtifact("lexeme-id")
        }
        let index = Int(lexemeID)
        let lemma = try string(try uint32(inSection: 2, record: index, stride: 16, field: 0))
        let rawPartOfSpeech = try string(try uint32(inSection: 2, record: index, stride: 16, field: 4))
        let senseStart = Int(try uint32(inSection: 2, record: index, stride: 16, field: 8))
        let senseCount = Int(try uint32(inSection: 2, record: index, stride: 16, field: 12))
        guard senseStart <= counts[1], senseCount <= counts[1] - senseStart else {
            throw LexiconModelError.corruptArtifact("sense-range")
        }
        let partOfSpeech: LexiconPartOfSpeech = rawPartOfSpeech == "noun" ? .noun : .other(rawPartOfSpeech)
        return try (senseStart..<(senseStart + senseCount)).map { senseIndex in
            let glossStart = Int(try uint32(inSection: 3, record: senseIndex, stride: 12, field: 0))
            let glossCount = Int(try uint32(inSection: 3, record: senseIndex, stride: 12, field: 4))
            guard glossStart <= counts[2], glossCount <= counts[2] - glossStart else {
                throw LexiconModelError.corruptArtifact("gloss-range")
            }
            let genderOffset = try offset(inSection: 3, record: senseIndex, stride: 12, field: 8, width: 1)
            let gender: LexiconGrammaticalGender?
            switch data[genderOffset] {
            case 0: gender = nil
            case 1: gender = .masculine
            case 2: gender = .feminine
            case 3: gender = .neuter
            default: throw LexiconModelError.corruptArtifact("gender")
            }
            let glosses = try (glossStart..<(glossStart + glossCount)).map { glossIndex in
                LexiconModelGloss(
                    languageCode: try string(
                        try uint32(inSection: 4, record: glossIndex, stride: 12, field: 0)
                    ),
                    text: try string(
                        try uint32(inSection: 4, record: glossIndex, stride: 12, field: 4)
                    )
                )
            }
            return LexiconModelSense(
                lemma: lemma,
                partOfSpeech: partOfSpeech,
                grammaticalGender: gender,
                glosses: glosses
            )
        }
    }

    private func string(_ identifier: UInt32) throws -> String {
        guard Int(identifier) < counts[5] else {
            throw LexiconModelError.corruptArtifact("string-id")
        }
        let record = try offset(inSection: 0, record: Int(identifier), stride: 8, field: 0, width: 8)
        let byteOffset = Int(Self.uint32(data, at: record))
        let byteCount = Int(Self.uint32(data, at: record + 4))
        guard byteOffset <= sections[1].length, byteCount <= sections[1].length - byteOffset else {
            throw LexiconModelError.corruptArtifact("string-range")
        }
        let start = sections[1].offset + byteOffset
        guard let value = String(data: data[start..<(start + byteCount)], encoding: .utf8) else {
            throw LexiconModelError.corruptArtifact("string-utf8")
        }
        return value
    }

    private func uint32(inSection section: Int, record: Int, stride: Int, field: Int) throws -> UInt32 {
        Self.uint32(data, at: try offset(inSection: section, record: record, stride: stride, field: field, width: 4))
    }

    private func uint64(inSection section: Int, record: Int, stride: Int, field: Int) throws -> UInt64 {
        Self.uint64(data, at: try offset(inSection: section, record: record, stride: stride, field: field, width: 8))
    }

    private func offset(
        inSection section: Int,
        record: Int,
        stride: Int,
        field: Int,
        width: Int
    ) throws -> Int {
        guard record >= 0, stride > 0, field >= 0, field <= stride - width,
            record <= (sections[section].length - width - field) / stride
        else { throw LexiconModelError.corruptArtifact("record-bounds") }
        return sections[section].offset + record * stride + field
    }

    private static func normalizedGloss(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
            .precomposedStringWithCanonicalMapping
            .folding(options: [.caseInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }

    private static func hasRecordLayout(_ length: Int, count: Int, stride: Int) -> Bool {
        length % stride == 0 && length / stride == count
    }

    private static func uint32(_ data: Data, at offset: Int) -> UInt32 {
        (0..<4).reduce(0) { $0 | UInt32(data[offset + $1]) << UInt32($1 * 8) }
    }

    private static func uint64(_ data: Data, at offset: Int) -> UInt64 {
        (0..<8).reduce(0) { $0 | UInt64(data[offset + $1]) << UInt64($1 * 8) }
    }

    private struct Manifest: Decodable {
        struct Artifact: Decodable {
            let byteCount: Int64
            let sha256: String
        }

        let artifact: Artifact
        let languageCode: String
        let modelVersion: Int
        let schemaVersion: Int
    }
}
