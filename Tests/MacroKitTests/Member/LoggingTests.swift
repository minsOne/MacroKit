import Macros
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

final class LoggingTests: XCTestCase {
    func testLazyLoggingMacroExpansion() throws {
        assertMacroExpansion(
            """
            @LazyLogging
            class TestingObject {
            }
            """,
            expandedSource: """
            class TestingObject {

                lazy private var logger: Logger = {
                    return Logger(subsystem: Bundle.main.bundleIdentifier ?? "Default Subsystem",
                                  category: String(describing: Self.self))
                }()
            }
            """,
            macros: ["LazyLogging": LazyLoggingMacro.self]
        )
    }

    func testLoggingMacroExpansion() throws {
        assertMacroExpansion(
            """
            @Logging
            struct TestingView: View {

                var body: some View {
                    Text("Hello, world!")
                }
            }
            """,
            expandedSource: """
            struct TestingView: View {

                var body: some View {
                    Text("Hello, world!")
                }

                private let logger: Logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Default Subsystem",
                                                    category: String(describing: Self.self))
            }
            """,
            macros: ["Logging": LoggingMacro.self]
        )
    }
}
