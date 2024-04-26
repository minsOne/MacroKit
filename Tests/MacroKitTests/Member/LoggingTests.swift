import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

@testable import Macros

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
                    GenerateOSLog(category: String(describing: Self.self)).log
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
                    GenerateOSLog(category: String(describing: Self.self)).log
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
                    GenerateOSLog(category: "UI").log
                }()
            }
            """,
            macros: ["Logging": LoggingMacro.self]
        )
    }
}
