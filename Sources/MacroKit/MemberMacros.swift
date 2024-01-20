public enum CaseDetectionAccessLevelConfig {
    case `private`
    case `fileprivate`
    case `internal`
    case `public`
}

/// Add computed properties named `is<Case>` for each case element in the enum.
@attached(member, names: named(init), arbitrary)
public macro CaseDetection(_ accessLevel: CaseDetectionAccessLevelConfig? = nil) = #externalMacro(module: "Macros", type: "CaseDetectionMacro")
