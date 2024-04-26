import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

struct AssociatedValuesMacro: MemberMacro {
    static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
            throw AssociatedValuesMacroError.notAEnum
        }

        let configuredAccessLevel: AccessLevelModifier? = extractConfiguredAccessLevel(from: node)

        return enumDecl.memberBlock.members.compactMap {
            $0.decl.as(EnumCaseDeclSyntax.self)?
                .elements
                .compactMap { $0 }
        }
        .reduce([], +)
        .compactMap { element -> DeclSyntax? in
            guard let associatedValue = element.parameterClause else {
                return nil
            }

            let variableNames = associatedValue
                .parameters
                .enumerated()
                .map { index, _ in
                    "v\(index)"
                }
                .joined(separator: ", ")

            var accessLevel: String = configuredAccessLevel?.rawValue ?? declaration.modifiers.description
            accessLevel += (accessLevel.isEmpty || accessLevel.last == " ")
                ? ""
                : " "

            return """
            \(raw: accessLevel)var \(element.name): \(raw: associatedValue)? {
              if case let .\(element.name)(\(raw: variableNames)) = self {
                \(associatedValue.parameters.count == 1 ? "return \(raw: variableNames)" : "return (\(raw: variableNames))")
              }
              return nil
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

private enum AssociatedValuesMacroError: Error, CustomStringConvertible {
    case notAEnum

    var description: String {
        switch self {
        case .notAEnum:
            "Can only be applied to enum"
        }
    }
}
