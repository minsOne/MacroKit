import Macros
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

private let testMacros: [String: Macro.Type] = [
    "AssociatedValues": AssociatedValuesMacro.self,
]

final class AssociatedValuesMacroTests: XCTestCase {
    func testGenerateVarForAssociatedValues() {
        assertMacroExpansion(
            """
            @AssociatedValues
            enum SomeEnum {
              case none
              case labeledValue(a: String, b: String)
              case optional(String?)
              case value(Int)
              case closure(() -> Void)
              indirect case someEnum(SomeEnum)
            }
            """,
            expandedSource:
            """
            enum SomeEnum {
              case none
              case labeledValue(a: String, b: String)
              case optional(String?)
              case value(Int)
              case closure(() -> Void)
              indirect case someEnum(SomeEnum)

              var labeledValue: (a: String, b: String)? {
                if case let .labeledValue(v0, v1) = self {
                  return (v0, v1)
                }
                return nil
              }

              var optional: (String?)? {
                if case let .optional(v0) = self {
                  return v0
                }
                return nil
              }

              var value: (Int)? {
                if case let .value(v0) = self {
                  return v0
                }
                return nil
              }

              var closure: (() -> Void)? {
                if case let .closure(v0) = self {
                  return v0
                }
                return nil
              }

              var someEnum: (SomeEnum)? {
                if case let .someEnum(v0) = self {
                  return v0
                }
                return nil
              }
            }
            """,
            macros: testMacros,
            indentationWidth: .spaces(2)
        )
    }

    func testGenerateVarForAssociatedValues_accessLevel_variable_fileprivate() {
        assertMacroExpansion(
            """
            @AssociatedValues(.fileprivate)
            enum SomeEnum {
              case none
              case labeledValue(a: String, b: String)
              case optional(String?)
              case value(Int)
              case closure(() -> Void)
              indirect case someEnum(SomeEnum)
            }
            """,
            expandedSource:
            """
            enum SomeEnum {
              case none
              case labeledValue(a: String, b: String)
              case optional(String?)
              case value(Int)
              case closure(() -> Void)
              indirect case someEnum(SomeEnum)

              fileprivate var labeledValue: (a: String, b: String)? {
                if case let .labeledValue(v0, v1) = self {
                  return (v0, v1)
                }
                return nil
              }

              fileprivate var optional: (String?)? {
                if case let .optional(v0) = self {
                  return v0
                }
                return nil
              }

              fileprivate var value: (Int)? {
                if case let .value(v0) = self {
                  return v0
                }
                return nil
              }

              fileprivate var closure: (() -> Void)? {
                if case let .closure(v0) = self {
                  return v0
                }
                return nil
              }

              fileprivate var someEnum: (SomeEnum)? {
                if case let .someEnum(v0) = self {
                  return v0
                }
                return nil
              }
            }
            """,
            macros: testMacros,
            indentationWidth: .spaces(2)
        )
    }

    func testGenerateVarForAssociatedValues_accessLevel_public() {
        assertMacroExpansion(
            """
            @AssociatedValues
            public enum SomeEnum {
              case none
              case labeledValue(a: String, b: String)
              case optional(String?)
              case value(Int)
              case closure(() -> Void)
              indirect case someEnum(SomeEnum)
            }
            """,
            expandedSource:
            """
            public enum SomeEnum {
              case none
              case labeledValue(a: String, b: String)
              case optional(String?)
              case value(Int)
              case closure(() -> Void)
              indirect case someEnum(SomeEnum)

              public var labeledValue: (a: String, b: String)? {
                if case let .labeledValue(v0, v1) = self {
                  return (v0, v1)
                }
                return nil
              }

              public var optional: (String?)? {
                if case let .optional(v0) = self {
                  return v0
                }
                return nil
              }

              public var value: (Int)? {
                if case let .value(v0) = self {
                  return v0
                }
                return nil
              }

              public var closure: (() -> Void)? {
                if case let .closure(v0) = self {
                  return v0
                }
                return nil
              }

              public var someEnum: (SomeEnum)? {
                if case let .someEnum(v0) = self {
                  return v0
                }
                return nil
              }
            }
            """,
            macros: testMacros,
            indentationWidth: .spaces(2)
        )
    }

    func testMacroIsOnlySupportEnum() {
        assertMacroExpansion(
            #"""
            @AssociatedValues
            struct SomeStructure {

            }
            """#,
            expandedSource:
            #"""
            struct SomeStructure {

            }
            """#,
            diagnostics: [
                DiagnosticSpec(message: #"Can only be applied to enum"#, line: 1, column: 1),
            ],
            macros: testMacros
        )
    }
}
