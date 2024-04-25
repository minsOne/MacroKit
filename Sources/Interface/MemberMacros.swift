import Foundation
@_exported import OSLog

// MARK: - Case Detection

public enum CaseDetectionAccessLevelConfig {
    case `private`
    case `fileprivate`
    case `internal`
    case `public`
}

/// Add computed properties named `is<Case>` for each case element in the enum.
@attached(member, names: named(init), arbitrary)
public macro CaseDetection(_ accessLevel: CaseDetectionAccessLevelConfig? = nil) = #externalMacro(module: "Macros", type: "CaseDetectionMacro")

// MARK: - Logging

@attached(member, names: named(logger))
public macro Logging(category: String? = nil) = #externalMacro(module: "Macros", type: "LoggingMacro")

public enum LoggingMacroHelper {
    public static func generateOSLog(_ fileID: String = #fileID, category: String) -> OSLog {
        let (module, fileName) = {
            let list = fileID.components(separatedBy: "/")
            return (list.first, list.last?.components(separatedBy: ".").first)
        }()

        guard let module,
              let fileName
        else { return .default }

        let subsystem = "kr.minsone.\(module).\(fileName)"
        return OSLog(subsystem: subsystem, category: category)
    }
}

// MARK: - Associated Values

public enum AssociatedValuesAccessLevelConfig {
    case `private`
    case `fileprivate`
    case `internal`
    case `package`
    case `public`
}

@attached(member, names: arbitrary)
public macro AssociatedValues(_ accessLevel: AssociatedValuesAccessLevelConfig? = nil) = #externalMacro(module: "Macros", type: "AssociatedValuesMacro")
