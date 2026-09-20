# ``LexiconKit``

Model persistence-friendly vocabulary values and query immutable lexical models without coupling consumers to UI, learning progression, or storage frameworks.

## Overview

LexiconKit models vocabulary independently from persistence, synchronization, user interface, and learning progression. Hosts decide how entries are validated, deduplicated, stored, synchronized, and presented.

Create a ``LexiconEntry`` from a ``LexiconTerm`` and one or more ``LexiconDefinition`` values. A term can carry an optional ``LexiconGrammaticalGender`` category without encoding a language-specific display article. Definitions retain their ``LexiconDefinitionSource`` so application-provided and user-provided content remain distinguishable after serialization. ``LexiconTag`` values and an optional ``LexiconAssetReference`` carry host-defined metadata without leaking application or media-framework types into the domain.

All public values are `Codable`, `Hashable`, and `Sendable`. Stable entry and definition identifiers plus explicit creation and modification timestamps let a host persist and merge values using its own policy.

``LexiconModel`` memory-maps a versioned immutable artifact and exposes synchronous exact term and gloss matching. The storage format, dense identifiers, and lookup indexes remain private. Model initialization validates structural metadata without scanning the full corpus; ``LexiconModel/verifyArtifact(at:against:)`` provides the explicit full-checksum path for CI and resource installation.

## Topics

### Entries

- ``LexiconEntry``
- ``LexiconTerm``
- ``LexiconGrammaticalGender``

### Definitions

- ``LexiconDefinition``
- ``LexiconDefinitionSource``

### Host-owned metadata

- ``LexiconTag``
- ``LexiconAssetReference``

### Lexical models

- ``LexiconModel``
- ``LexiconModelLookupResult``
- ``LexiconModelSense``
- ``LexiconModelGloss``
- ``LexiconPartOfSpeech``
