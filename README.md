<p align="center">
  <a href="https://developer.apple.com/swift/"><img alt="Swift Version" src="https://img.shields.io/badge/Swift-6.4-ea7a50.svg?logo=swift&logoColor=white"></a>
  <a href="https://developer.apple.com/xcode/"><img alt="Xcode Version" src="https://img.shields.io/badge/Xcode-27-50ace8.svg?logo=xcode&logoColor=white"></a>
  <a href="https://forums.swift.org/t/introducing-anyappleos/85728"><img alt="Platforms" src="https://img.shields.io/badge/AnyAppleOS-26%2B-lightgrey.svg?logo=apple&logoColor=white"></a>
  <a href="https://developer.apple.com/documentation/xcode/swift-packages"><img alt="SPM" src="https://img.shields.io/badge/SPM-ready-b68f6a.svg?logo=gitlfs&logoColor=white"></a>
  <a href="https://thatfactory.github.io/lexiconkit/documentation/lexiconkit/"><img alt="DocC" src="https://img.shields.io/badge/DocC-documentation-0288D1.svg?logo=bookstack&logoColor=white"></a>
  <a href="https://en.wikipedia.org/wiki/MIT_License"><img alt="License" src="https://img.shields.io/badge/License-MIT-67ac5b.svg?logo=googledocs&logoColor=white"></a>
  <a href="https://github.com/thatfactory/lexiconkit/actions/workflows/ci.yml"><img alt="CI" src="https://github.com/thatfactory/lexiconkit/actions/workflows/ci.yml/badge.svg"></a>
  <a href="https://github.com/thatfactory/lexiconkit/actions/workflows/release.yml"><img alt="Release" src="https://github.com/thatfactory/lexiconkit/actions/workflows/release.yml/badge.svg"></a>
</p>

# LexiconKit

LexiconKit is a reusable, UI-agnostic domain package for personal vocabulary collections, definitions, provenance, lightweight metadata, and opaque references to host-owned media.

LexiconKit provides persistence-friendly values for vocabulary entries, terms, optional grammatical gender, definitions, definition provenance, tags, and opaque host-owned media references. Dictionary lookup, translation, language-specific display articles, exercises, persistence frameworks, synchronization, and UI remain outside its boundary.

```swift
let entry = LexiconEntry(
    term: LexiconTerm(
        text: "Haus",
        languageCode: "de",
        grammaticalGender: .neuter
    ),
    definitions: [
        LexiconDefinition(
            text: "house",
            languageCode: "en",
            source: .user
        )
    ]
)
```

## Documentation

API documentation is published with DocC after a GitHub release. See the [LexiconKit documentation](https://thatfactory.github.io/lexiconkit/documentation/lexiconkit/).

## Runtime diagnostics

LexiconKit currently emits no runtime diagnostics. Its public surface contains only pure domain values and initializers; persistence, synchronization, validation workflows, and application lifecycle remain host responsibilities. Logging value construction would add noise and could expose vocabulary content. If the package later gains stateful or fallible runtime behavior, its diagnostics will use a package-local `LexiconLogging` gateway, subsystem `com.thatfactory.lexiconkit`, and the canonical 📖 prefix.

## Requirements

- Swift 6.4
- Xcode 27
- Apple platform versions shown in the badge above
- Swift Package Manager
