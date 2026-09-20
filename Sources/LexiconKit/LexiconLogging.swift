import AppLogger

enum LexiconLogging {
    static func modelOpened() {
        logger().log(level: .info, "📖 Lexicon model opened")
    }

    static func modelOpenFailed() {
        logger().log(level: .error, "📖 Lexicon model open failed")
    }

    private static func logger() -> AppLogger {
        AppLogger(
            subsystem: "com.thatfactory.lexiconkit",
            category: "model"
        )
    }
}
