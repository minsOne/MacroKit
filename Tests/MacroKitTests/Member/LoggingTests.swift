import Macros
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

final class LoggingTests: XCTestCase {
    func testLoggingMacroExpansion1() throws {
        assertMacroExpansion(
            """
            @Logging
            class TestingObject {
            }
            """,
            expandedSource: """
            class TestingObject {

                lazy var logger: OSLog = {
                    LoggingMacroHelper.generateOSLog(category: String(describing: Self.self))
                }()
            }
            """,
            macros: ["Logging": LoggingMacro.self]
        )
    }

    func testLoggingMacroExpansion2() throws {
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

                lazy var logger: OSLog = {
                    LoggingMacroHelper.generateOSLog(category: String(describing: Self.self))
                }()
            }
            """,
            macros: ["Logging": LoggingMacro.self]
        )
    }

    func testLoggingMacroExpansion3() throws {
        assertMacroExpansion(
            """
            @Logging(category: "UI")
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

                lazy var logger: OSLog = {
                    LoggingMacroHelper.generateOSLog(category: "UI")
                }()
            }
            """,
            macros: ["Logging": LoggingMacro.self]
        )
    }
}
