//
//  LoggingMacro.swift
//
//  Created by James Sedlacek on 12/29/23.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros

public struct LoggingMacro: MemberMacro {
    public enum MacroError: Error {
        case incorrectType
    }

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let allowTypes: [SyntaxKind] = [
            .classDecl,
            .structDecl,
            .actorDecl,
        ]

        guard allowTypes.contains(declaration.kind)
        else {
            let msg = "@Logger는 Class, Struct, Actor에만 사용 가능합니다."
            throw MacroExpansionErrorMessage(msg)
        }

        let category = extractCategory(from: node).map { "\"\($0)\"" } ?? "String(describing: Self.self)"

        return [
            DeclSyntax(
                """
                lazy var logger: OSLog = {
                    LoggingMacroHelper.generateOSLog(category: \(raw: category))
                }()
                """),
        ]
    }

    private static func extractCategory(from node: AttributeSyntax) -> String? {
        node.arguments?.as(LabeledExprListSyntax.self)?
            .lazy
            .compactMap { labeledExprSyntax -> String? in
                labeledExprSyntax.expression
                    .as(StringLiteralExprSyntax.self)?
                    .segments.first?
                    .as(StringSegmentSyntax.self)?
                    .content.text
            }
            .first
    }
}
