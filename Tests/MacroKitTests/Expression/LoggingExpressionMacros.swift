import Macros
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

final class LoggingExpressionMacrosTests: XCTestCase {
    func testMacro() throws {
        assertMacroExpansion(
            #"""
            #log(level: .debug, "message")
            """#,
            expandedSource: #"""
            {
              #if os(iOS)
                if #available (iOS 14.0, *) {
                  Logger(logger).log(level: .debug, "message")
                } else {
                  os_log(.debug, log: logger, "message")
                }
              #else
                os_log(.debug, log: logger, "message")
              #endif
            }()
            """#,
            macros: ["log": LoggingExpressionMacros.self]
        )
    }
}
