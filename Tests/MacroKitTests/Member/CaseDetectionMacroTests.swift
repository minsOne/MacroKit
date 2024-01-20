import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import Macros

fileprivate let testMacros: [String: Macro.Type] = [
    "CaseDetection": CaseDetectionMacro.self,
]

final class CaseDetectionMacroTests: XCTestCase {
    func testExpansion_public() {
        assertMacroExpansion(
      """
      @CaseDetection(.public)
      enum Animal {
        case dog
        case cat(curious: Bool)
      }
      """,
      expandedSource: """
        enum Animal {
          case dog
          case cat(curious: Bool)
        
          public var isDog: Bool {
            if case .dog = self {
              return true
            }
        
            return false
          }
        
          public var isCat: Bool {
            if case .cat = self {
              return true
            }
        
            return false
          }
        }
        """,
      macros: testMacros,
      indentationWidth: .spaces(2))
    }
    
    func testExpansion_internal() {
        assertMacroExpansion(
      """
      @CaseDetection(.internal)
      enum Animal {
        case dog
        case cat(curious: Bool)
      }
      """,
      expandedSource: """
        enum Animal {
          case dog
          case cat(curious: Bool)
        
          internal var isDog: Bool {
            if case .dog = self {
              return true
            }
        
            return false
          }
        
          internal var isCat: Bool {
            if case .cat = self {
              return true
            }
        
            return false
          }
        }
        """,
      macros: testMacros,
      indentationWidth: .spaces(2))
    }
    
    func testExpansion_fileprivate() {
        assertMacroExpansion(
      """
      @CaseDetection(.fileprivate)
      enum Animal {
        case dog
        case cat(curious: Bool)
      }
      """,
      expandedSource: """
        enum Animal {
          case dog
          case cat(curious: Bool)
        
          fileprivate var isDog: Bool {
            if case .dog = self {
              return true
            }
        
            return false
          }
        
          fileprivate var isCat: Bool {
            if case .cat = self {
              return true
            }
        
            return false
          }
        }
        """,
      macros: testMacros,
      indentationWidth: .spaces(2))
    }
    
    func testExpansion_private() {
        assertMacroExpansion(
      """
      @CaseDetection(.private)
      enum Animal {
        case dog
        case cat(curious: Bool)
      }
      """,
      expandedSource: """
        enum Animal {
          case dog
          case cat(curious: Bool)
        
          private var isDog: Bool {
            if case .dog = self {
              return true
            }
        
            return false
          }
        
          private var isCat: Bool {
            if case .cat = self {
              return true
            }
        
            return false
          }
        }
        """,
      macros: testMacros,
      indentationWidth: .spaces(2))
    }
    
    func testExpansion_default_internal() {
        assertMacroExpansion(
      """
      @CaseDetection
      enum Animal {
        case dog
        case cat(curious: Bool)
      }
      """,
      expandedSource: """
        enum Animal {
          case dog
          case cat(curious: Bool)
        
          internal var isDog: Bool {
            if case .dog = self {
              return true
            }
        
            return false
          }
        
          internal var isCat: Bool {
            if case .cat = self {
              return true
            }
        
            return false
          }
        }
        """,
      macros: testMacros,
      indentationWidth: .spaces(2))
    }
}
