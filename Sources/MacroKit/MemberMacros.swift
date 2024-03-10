import Foundation
@_exported import OSLog

public enum CaseDetectionAccessLevelConfig {
    case `private`
    case `fileprivate`
    case `internal`
    case `public`
}

/// Add computed properties named `is<Case>` for each case element in the enum.
@attached(member, names: named(init), arbitrary)
public macro CaseDetection(_ accessLevel: CaseDetectionAccessLevelConfig? = nil) = #externalMacro(module: "Macros", type: "CaseDetectionMacro")

@attached(member, names: named(logger))
public macro Logging() = #externalMacro(module: "Macros", type: "LoggingMacro")

@attached(member, names: named(logger))
public macro LazyLogging() = #externalMacro(module: "Macros", type: "LazyLoggingMacro")
