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
              if #available (iOS 14.0, macOS 11.0, watchOS 7.0, tvOS 14.0, *) {
                Logger(logger).log(level: .debug, "message")
              } else {
                os_log(.debug, log: logger, "message")
              }
            }()
            """#,
            macros: ["log": LoggingExpressionMacros.self]
        )
    }
}
