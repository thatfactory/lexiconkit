import CryptoKit
import Foundation
import Testing

@testable import LexiconKit

struct LexiconModelTests {
    @Test func exactLemmaAndFormLookupReturnTheSameSense() throws {
        let fixture = try ModelFixture()
        let model = try LexiconModel(contentsOf: fixture.modelURL, manifestURL: fixture.manifestURL)

        let lemma = try #require(model.lookup("Haus").uniqueSense)
        let form = try #require(model.lookup("Häuser").uniqueSense)

        #expect(lemma == form)
        #expect(lemma.lemma == "Haus")
        #expect(lemma.grammaticalGender == .neuter)
    }

    @Test func exactGlossNarrowsAnAmbiguousHomograph() throws {
        let fixture = try ModelFixture()
        let model = try LexiconModel(contentsOf: fixture.modelURL, manifestURL: fixture.manifestURL)

        let unresolved = try model.lookup("See")
        let lake = try model.matchSense(for: "See", gloss: " LAKE ", languageCodes: ["en"])

        #expect(unresolved.multipleSenses?.count == 2)
        #expect(lake.uniqueSense?.grammaticalGender == .masculine)
    }

    @Test func nonNounAndUnknownTermsRemainExplicit() throws {
        let fixture = try ModelFixture()
        let model = try LexiconModel(contentsOf: fixture.modelURL, manifestURL: fixture.manifestURL)

        #expect(try model.lookup("laufen").uniqueSense?.partOfSpeech == .other("verb"))
        #expect(try model.lookup("unbekannt") == .notFound)
    }

    @Test func fullVerificationRejectsChangedBytes() throws {
        let fixture = try ModelFixture()
        var bytes = try Data(contentsOf: fixture.modelURL)
        bytes.append(0)
        try bytes.write(to: fixture.modelURL)

        #expect(throws: LexiconModelError.corruptArtifact("artifact-byte-count")) {
            try LexiconModel.verifyArtifact(at: fixture.modelURL, against: fixture.manifestURL)
        }
    }

    @Test func lookupRejectsMalformedReachedPosting() throws {
        let fixture = try ModelFixture()
        var bytes = try Data(contentsOf: fixture.modelURL)
        let postingSection = Int(Self.uint64(bytes, at: 168))
        bytes.replaceSubrange(postingSection..<(postingSection + 4), with: Data(repeating: 0xFF, count: 4))
        try bytes.write(to: fixture.modelURL)
        try fixture.updateManifestChecksum()
        let model = try LexiconModel(contentsOf: fixture.modelURL, manifestURL: fixture.manifestURL)

        #expect(throws: LexiconModelError.corruptArtifact("posting")) {
            try model.lookup("Haus")
        }
    }

    @Test func initializerRejectsUnsupportedFormat() throws {
        let fixture = try ModelFixture()
        var bytes = try Data(contentsOf: fixture.modelURL)
        bytes.replaceSubrange(8..<12, with: Data([2, 0, 0, 0]))
        try bytes.write(to: fixture.modelURL)
        try fixture.updateManifestChecksum()

        #expect(throws: LexiconModelError.unsupportedFormat(2)) {
            try LexiconModel(contentsOf: fixture.modelURL, manifestURL: fixture.manifestURL)
        }
    }

    @Test func initializerRejectsTruncatedArtifact() throws {
        let fixture = try ModelFixture()
        var bytes = try Data(contentsOf: fixture.modelURL)
        bytes.removeLast(1)
        try bytes.write(to: fixture.modelURL)
        try fixture.updateManifestChecksum()

        #expect(throws: LexiconModelError.corruptArtifact("section-bounds")) {
            try LexiconModel(contentsOf: fixture.modelURL, manifestURL: fixture.manifestURL)
        }
    }

    private static func uint64(_ data: Data, at offset: Int) -> UInt64 {
        (0..<8).reduce(0) { $0 | UInt64(data[offset + $1]) << UInt64($1 * 8) }
    }
}

extension LexiconModelLookupResult {
    fileprivate var multipleSenses: [LexiconModelSense]? {
        guard case .multiple(let senses) = self else { return nil }
        return senses
    }

    fileprivate var uniqueSense: LexiconModelSense? {
        guard case .unique(let sense) = self else { return nil }
        return sense
    }
}

private final class ModelFixture {
    let manifestURL: URL
    let modelURL: URL

    init() throws {
        let root = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        modelURL = root.appending(path: "German.lexicon")
        manifestURL = root.appending(path: "manifest.json")
        try Self.artifact().write(to: modelURL)
        try updateManifestChecksum()
    }

    func updateManifestChecksum() throws {
        let bytes = try Data(contentsOf: modelURL)
        let digest = SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined()
        let manifest: [String: Any] = [
            "artifact": ["byteCount": bytes.count, "sha256": digest],
            "languageCode": "de",
            "modelVersion": 1,
            "schemaVersion": 1,
        ]
        try JSONSerialization.data(withJSONObject: manifest).write(to: manifestURL)
    }

    private static func artifact() -> Data {
        let strings = ["Haus", "Häuser", "See", "en", "house", "lake", "laufen", "noun", "sea", "verb"]
        let identifiers = Dictionary(uniqueKeysWithValues: strings.enumerated().map { ($1, UInt32($0)) })
        var stringRecords = Data()
        var stringBytes = Data()
        for string in strings {
            append(UInt32(stringBytes.count), to: &stringRecords)
            append(UInt32(string.utf8.count), to: &stringRecords)
            stringBytes.append(Data(string.utf8))
        }
        var lexemes = Data()
        for row: [UInt32] in [
            [identifiers["Haus"]!, identifiers["noun"]!, 0, 1],
            [identifiers["See"]!, identifiers["noun"]!, 1, 2],
            [identifiers["laufen"]!, identifiers["verb"]!, 3, 1],
        ] {
            for value in row { append(value, to: &lexemes) }
        }
        var senses = Data()
        for row: (UInt32, UInt32, UInt8) in [(0, 1, 3), (1, 1, 1), (2, 1, 2), (3, 0, 0)] {
            append(row.0, to: &senses)
            append(row.1, to: &senses)
            senses.append(row.2)
            senses.append(contentsOf: [0, 0, 0])
        }
        var glosses = Data()
        for text in ["house", "lake", "sea"] {
            append(identifiers["en"]!, to: &glosses)
            append(identifiers[text]!, to: &glosses)
            append(identifiers[text]!, to: &glosses)
        }
        var lookups = Data()
        for row: (UInt32, UInt32, UInt32) in [
            (identifiers["Haus"]!, 0, 1),
            (identifiers["Häuser"]!, 1, 1),
            (identifiers["See"]!, 2, 1),
            (identifiers["laufen"]!, 3, 1),
        ] {
            append(row.0, to: &lookups)
            append(row.1, to: &lookups)
            append(row.2, to: &lookups)
        }
        var postings = Data()
        for value: UInt64 in [1 << 32, (2 << 32), 1 | (1 << 32), 2 | (1 << 32)] {
            append(value, to: &postings)
        }
        let sections = [stringRecords, stringBytes, lexemes, senses, glosses, lookups, postings]
        var artifact = Data(repeating: 0, count: 256)
        var sectionOffsets: [(UInt64, UInt64)] = []
        for section in sections {
            sectionOffsets.append((UInt64(artifact.count), UInt64(section.count)))
            artifact.append(section)
        }
        artifact.replaceSubrange(0..<8, with: Data("TFLEX001".utf8))
        var header = Data()
        for value: UInt32 in [1, 1, 1, 1] { append(value, to: &header) }
        for value: UInt64 in [3, 4, 3, 4, 4, UInt64(strings.count)] { append(value, to: &header) }
        for section in sectionOffsets {
            append(section.0, to: &header)
            append(section.1, to: &header)
        }
        header.append(Data(repeating: 0, count: 64))
        artifact.replaceSubrange(8..<(8 + header.count), with: header)
        return artifact
    }

    private static func append<T: FixedWidthInteger>(_ value: T, to data: inout Data) {
        var littleEndian = value.littleEndian
        withUnsafeBytes(of: &littleEndian) { data.append(contentsOf: $0) }
    }
}
