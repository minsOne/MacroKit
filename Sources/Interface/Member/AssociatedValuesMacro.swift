import Foundation

// MARK: - Associated Values

@attached(member, names: arbitrary)
public macro AssociatedValues(_ accessLevel: AccessLevelConfig? = nil) = #externalMacro(module: "Macros", type: "AssociatedValuesMacro")
