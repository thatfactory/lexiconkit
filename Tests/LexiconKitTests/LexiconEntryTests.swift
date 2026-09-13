import Foundation
import Testing

@testable import LexiconKit

struct LexiconEntryTests {
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
