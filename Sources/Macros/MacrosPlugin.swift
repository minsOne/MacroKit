import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct MacrosPlugin: CompilerPlugin {
    init() {}

    static var expressionMacros: [Macro.Type] {
        [
            StringifyMacro.self,
        ]
    }

    static var memberMacros: [Macro.Type] {
        [
            CaseDetectionMacro.self,
            LoggingMacro.self,
        ]
    }

    let providingMacros: [Macro.Type] = [
        expressionMacros,
        memberMacros,
    ].flatMap { $0 }
}
