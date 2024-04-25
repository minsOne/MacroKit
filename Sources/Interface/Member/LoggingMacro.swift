import Foundation

@_exported import OSLog

// MARK: - Logging

@attached(member, names: named(logger))
public macro Logging(category: String? = nil) = #externalMacro(module: "Macros", type: "LoggingMacro")

// MARK: - Helper

public struct GenerateOSLog {
    public let log: OSLog

    public init(_ fileID: String = #fileID, category: String) {
        let (module, fileName) = {
            let list = fileID.components(separatedBy: "/")
            return (list.first, list.last?.components(separatedBy: ".").first)
        }()

        guard let module,
              let fileName
        else {
            log = .default
            return
        }

        let subsystem = "kr.minsone.\(module).\(fileName)"
        log = OSLog(subsystem: subsystem, category: category)
    }
}
