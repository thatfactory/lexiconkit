import Testing
@testable import LexiconKit

@Test("The package namespace is available")
func packageNamespaceIsAvailable() {
    _ = LexiconKit.self
}
