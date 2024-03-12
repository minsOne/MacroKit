import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

/// OS 버전에 따라 Logger의 호출이 달라지므로, 조건에 따라 변경이 필요함
public struct LoggingExpressionMacros: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        let argumentList = node.argumentList
        guard
            argumentList.count == 2,
            let firstElement = argumentList.first,
            let secondElement = argumentList.last
        else {
            fatalError("compiler bug: the macro does not have any arguments")
        }

        let oslogType = firstElement.expression
            .as(MemberAccessExprSyntax.self)?
            .declName.baseName.text
        let msg = secondElement.expression
            .as(StringLiteralExprSyntax.self)?
            .segments.first?
            .as(StringSegmentSyntax.self)?
            .content.text

        guard
            let oslogType, let msg
        else {
            fatalError("compiler bug: the macro does not have any arguments")
        }

        return "\(raw: generateExpr(oslogType: oslogType, msg: msg))"
    }

    private static func generateExpr(oslogType: String, msg: String) -> String {
        """
        {
          #if os(iOS)
            if #available(iOS 14.0, *) {
              Logger(logger).log(level: .\(oslogType), "\(msg)")
            } else {
              \(debug(oslogType: oslogType, msg: msg))
            }
          #else
            \(debug(oslogType: oslogType, msg: msg))
          #endif
        }()
        """
    }

    private static func debug(oslogType: String, msg: String) -> String {
        """
        os_log(.\(oslogType), log: logger, "\(msg)")
        """
    }
}