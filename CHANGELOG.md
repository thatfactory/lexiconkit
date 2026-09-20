# Changelog

All notable changes to LexiconKit are documented here.

## Unreleased

## 0.3.0 — 2026-09-21

### Added

- Add a memory-mapped, language-neutral lexicon model reader with synchronous exact term and gloss lookup.
- Add explicit model verification for CI and installed-resource integrity checks.

### Changed

- Adopt Agent Guidelines `0.0.34`.

## 0.2.0 — 2026-09-20

### Added

- Add optional, language-independent grammatical gender metadata to `LexiconTerm` with backward-compatible Codable behavior.

## 0.1.2 — 2026-09-19

### Changed

- Adopted Agent Guidelines `0.0.33` and the Swift package compiler-settings baseline.
- Declared Swift 6, warnings as errors, and the required upcoming language features for every package target.
- Made imports and existential types explicit where required by the stricter compiler policy without intentionally changing runtime behavior.

## 0.1.1 — 2026-09-13

### Changed

- Documented the package's deliberate no-event logging decision for its current pure-value API and reserved its future logging identity.

## 0.1.0 — 2026-09-13

### Added

- Added persistence-friendly vocabulary entries, terms, definitions, provenance, tags, opaque asset references, and explicit timestamps.
- Added Codable round-trip and identity tests for the complete vocabulary model.
