import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct MacrosPlugin: CompilerPlugin {
    init() {}

    static var expressionMacros: [Macro.Type] {
        [
            StringifyMacro.self,
            LoggingExpressionMacros.self,
        ]
    }

    static var memberMacros: [Macro.Type] {
        [
            AssociatedValuesMacro.self,
            CaseDetectionMacro.self,
            LoggingMacro.self,
        ]
    }

    static var peerMacros: [Macro.Type] {
        [
            AddAsyncMacro.self,
            AddCompletionHandlerMacro.self,
        ]
    }

    let providingMacros: [Macro.Type] = [
        expressionMacros,
        memberMacros,
        peerMacros,
    ].flatMap { $0 }
}
