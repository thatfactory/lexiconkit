# ``LexiconKit``

Model persistence-friendly vocabulary values without coupling consumers to UI, learning progression, or storage frameworks.

## Overview

LexiconKit models vocabulary independently from persistence, synchronization, user interface, and learning progression. Hosts decide how entries are validated, deduplicated, stored, synchronized, and presented.

Create a ``LexiconEntry`` from a ``LexiconTerm`` and one or more ``LexiconDefinition`` values. Definitions retain their ``LexiconDefinitionSource`` so application-provided and user-provided content remain distinguishable after serialization. ``LexiconTag`` values and an optional ``LexiconAssetReference`` carry host-defined metadata without leaking application or media-framework types into the domain.

All public values are `Codable`, `Hashable`, and `Sendable`. Stable entry and definition identifiers plus explicit creation and modification timestamps let a host persist and merge values using its own policy.

## Topics

### Entries

- ``LexiconEntry``
- ``LexiconTerm``

### Definitions

- ``LexiconDefinition``
- ``LexiconDefinitionSource``

### Host-owned metadata

- ``LexiconTag``
- ``LexiconAssetReference``
