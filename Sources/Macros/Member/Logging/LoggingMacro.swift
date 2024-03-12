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

        return [
            DeclSyntax(
                """
                lazy var logger: Logger = {
                    LoggingMacroHelper.generateLogger(category: String(describing: Self.self))
                }()
                """),
        ]
    }
}
