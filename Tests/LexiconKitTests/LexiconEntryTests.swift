import Foundation
import Testing

@testable import LexiconKit

struct LexiconEntryTests {
    @Test func legacyEntryWithoutGrammaticalGenderDecodesWithNil() throws {
        let payload = Data(
            #"{"createdAt":0,"definitions":[],"id":"D2E60778-E44B-48BE-B539-268D1F15229A","modifiedAt":0,"tags":[],"term":{"languageCode":"de","text":"Haus"}}"#
                .utf8
        )

        let entry = try JSONDecoder().decode(LexiconEntry.self, from: payload)

        #expect(entry.term.text == "Haus")
        #expect(entry.term.grammaticalGender == nil)
    }

    @Test(
        "Every supported grammatical gender round-trips",
        arguments: [
            LexiconGrammaticalGender.feminine,
            .masculine,
            .neuter,
        ]
    )
    func grammaticalGenderRoundTrips(_ gender: LexiconGrammaticalGender) throws {
        let term = LexiconTerm(
            text: "Haus",
            languageCode: "de",
            grammaticalGender: gender
        )

        let data = try JSONEncoder().encode(term)
        let decoded = try JSONDecoder().decode(LexiconTerm.self, from: data)

        #expect(decoded == term)
        #expect(decoded.grammaticalGender == gender)
    }

    @Test func existingInitializerDefaultsGrammaticalGenderToNil() {
        let term = LexiconTerm(text: "laufen", languageCode: "de")

        #expect(term.grammaticalGender == nil)
    }

    @Test func equalityAndHashingIncludeGrammaticalGender() {
        let masculine = LexiconTerm(
            text: "See",
            languageCode: "de",
            grammaticalGender: .masculine
        )
        let feminine = LexiconTerm(
            text: "See",
            languageCode: "de",
            grammaticalGender: .feminine
        )

        #expect(masculine != feminine)
        #expect(Set([masculine, feminine]).count == 2)
    }

    @Test func legacyDecoderIgnoresNewGrammaticalGenderKey() throws {
        let entry = LexiconEntry(
            term: LexiconTerm(
                text: "Haus",
                languageCode: "de",
                grammaticalGender: .neuter
            ),
            definitions: []
        )

        let data = try JSONEncoder().encode(entry)
        let legacyEntry = try JSONDecoder().decode(LegacyEntry.self, from: data)

        #expect(legacyEntry.term == LegacyTerm(languageCode: "de", text: "Haus"))
    }

    @Test func completeEntryRoundTripsThroughCodable() throws {
        // Given
        let entryID = UUID(uuidString: "D2E60778-E44B-48BE-B539-268D1F15229A")!
        let definitionID = UUID(uuidString: "707E18F0-4433-45BE-A2FA-4EE156615677")!
        let createdAt = Date(timeIntervalSince1970: 1_789_300_000)
        let modifiedAt = createdAt.addingTimeInterval(60)
        let entry = LexiconEntry(
            id: entryID,
            term: LexiconTerm(text: "Haus", languageCode: "de"),
            definitions: [
                LexiconDefinition(
                    id: definitionID,
                    text: "house",
                    languageCode: "en",
                    source: .user
                )
            ],
            tags: [LexiconTag(rawValue: "reading")],
            assetReference: LexiconAssetReference(rawValue: "images/haus"),
            createdAt: createdAt,
            modifiedAt: modifiedAt
        )

        // When
        let data = try JSONEncoder().encode(entry)
        let decoded = try JSONDecoder().decode(LexiconEntry.self, from: data)

        // Then
        #expect(decoded == entry)
        #expect(decoded.id == entryID)
        #expect(decoded.definitions.first?.id == definitionID)
        #expect(decoded.definitions.first?.source == .user)
        #expect(decoded.tags == [LexiconTag(rawValue: "reading")])
        #expect(decoded.assetReference == LexiconAssetReference(rawValue: "images/haus"))
    }

    @Test func applicationDefinitionProvenanceRoundTrips() throws {
        let definition = LexiconDefinition(
            text: "a building for people to live in",
            languageCode: "en",
            source: .application
        )

        let data = try JSONEncoder().encode(definition)
        let decoded = try JSONDecoder().decode(LexiconDefinition.self, from: data)

        #expect(decoded == definition)
        #expect(decoded.source == .application)
    }

    @Test func initialModifiedTimestampMatchesCreationTimestamp() {
        let createdAt = Date(timeIntervalSince1970: 1_789_300_000)

        let entry = LexiconEntry(
            term: LexiconTerm(text: "Maus", languageCode: "de"),
            definitions: [],
            createdAt: createdAt
        )

        #expect(entry.createdAt == createdAt)
        #expect(entry.modifiedAt == createdAt)
    }

    @Test func hostCanUpdateContentWithoutChangingIdentityOrCreationTimestamp() {
        let createdAt = Date(timeIntervalSince1970: 1_789_300_000)
        let modifiedAt = createdAt.addingTimeInterval(90)
        var entry = LexiconEntry(
            term: LexiconTerm(text: "Buch", languageCode: "de"),
            definitions: [],
            createdAt: createdAt
        )
        let originalID = entry.id

        entry.definitions.append(
            LexiconDefinition(text: "book", languageCode: "en", source: .user)
        )
        entry.modifiedAt = modifiedAt

        #expect(entry.id == originalID)
        #expect(entry.createdAt == createdAt)
        #expect(entry.modifiedAt == modifiedAt)
        #expect(entry.definitions.map(\.text) == ["book"])
    }
}

private struct LegacyTerm: Codable, Equatable {
    var languageCode: String
    var text: String
}

private struct LegacyEntry: Codable {
    let id: UUID
    var assetReference: LexiconAssetReference?
    var createdAt: Date
    var definitions: [LexiconDefinition]
    var modifiedAt: Date
    var tags: Set<LexiconTag>
    var term: LegacyTerm
}
