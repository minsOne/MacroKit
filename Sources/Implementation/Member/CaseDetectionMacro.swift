//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros

public enum CaseDetectionMacro: MemberMacro {
    public static func expansion<D, C>(
        of node: AttributeSyntax,
        providingMembersOf decl: D,
        in context: C
    ) throws -> [SwiftSyntax.DeclSyntax]
        where D: DeclGroupSyntax, C: MacroExpansionContext {
        guard [SwiftSyntax.SyntaxKind.enumDecl].contains(decl.kind) else {
            throw MacroExpansionErrorMessage(
                """
                @CaseDetection can only be attached to a enum; \
                not to \(decl.descriptiveDeclKind(withArticle: true)).
                """
            )
        }

        let configuredAccessLevel: AccessLevelModifier? = extractConfiguredAccessLevel(from: node)

        let accessLevel = configuredAccessLevel ?? .internal

        return decl.memberBlock.members
            .compactMap { $0.decl.as(EnumCaseDeclSyntax.self) }
            .map { $0.elements.first!.name }
            .map { ($0, $0.initialUppercased) }
            .map { original, uppercased in
                """
                \(raw: accessLevel) var is\(raw: uppercased): Bool {
                  if case .\(raw: original) = self {
                    return true
                  }

                  return false
                }
                """
            }
    }

    private static func extractConfiguredAccessLevel(
        from node: AttributeSyntax
    ) -> AccessLevelModifier? {
        node.arguments?.as(LabeledExprListSyntax.self)?
            .lazy
            .compactMap { labeledExprSyntax -> AccessLevelModifier? in
                guard
                    let identifier = labeledExprSyntax.expression.as(MemberAccessExprSyntax.self)?.declName,
                    let accessLevel = AccessLevelModifier(rawValue: identifier.baseName.trimmedDescription)
                else {
                    return nil
                }

                return accessLevel
            }
            .first
    }
}

private extension TokenSyntax {
    var initialUppercased: String {
        guard let initial = text.first else {
            return text
        }

        return "\(initial.uppercased())\(text.dropFirst())"
    }
}
