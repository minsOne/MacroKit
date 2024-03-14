import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros

/// OS 버전에 따라 Logger의 호출이 달라지므로, 조건에 따라 변경이 필요함
public struct LoggingExpressionMacros: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {
        let argumentList = node.argumentList
        guard
            argumentList.count == 2,
            let firstElement = argumentList.first,
            let secondElement = argumentList.last
        else {
            throw MacroExpansionErrorMessage(
                "log는 OSLogType, message이 필요합니다. 확인해주세요"
            )
        }

        let oslogType = firstElement.expression
            .as(MemberAccessExprSyntax.self)?
            .declName.baseName.text
        let msg = secondElement.expression
            .as(StringLiteralExprSyntax.self)?
            .segments.first?
            .as(StringSegmentSyntax.self)?
            .content.text

        guard let oslogType else {
            throw MacroExpansionErrorMessage(
                "log는 OSLogType, message이 필요합니다. 확인해주세요"
            )
        }
        guard let msg else {
            throw MacroExpansionErrorMessage(
                "message 타입이 String인지 확인해주세요"
            )
        }

        return "\(raw: generateExpr(oslogType: oslogType, msg: msg))"
    }

    private static func generateExpr(oslogType: String, msg: String) -> String {
        """
        {
          if #available(iOS 14.0, macOS 11.0, watchOS 7.0, tvOS 14.0, *) {
            Logger(logger).log(level: .\(oslogType), "\(msg)")
          } else {
            \(debug(oslogType: oslogType, msg: msg))
          }
        }()
        """
    }

    private static func debug(oslogType: String, msg: String) -> String {
        """
        os_log(.\(oslogType), log: logger, "\(msg)")
        """
    }
}
