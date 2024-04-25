import Foundation

// MARK: - Case Detection

/// Add computed properties named `is<Case>` for each case element in the enum.
@attached(member, names: named(init), arbitrary)
public macro CaseDetection(_ accessLevel: AccessLevelConfig? = nil) = #externalMacro(module: "Macros", type: "CaseDetectionMacro")
