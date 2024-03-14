@_exported import os.log

/// A macro that produces both a value and a string containing the
/// source code that generated the value. For example,
///
///     #stringify(x + y)
///
/// produces a tuple `(x + y, "x + y")`.
@freestanding(expression)
public macro stringify<T>(_ value: T) -> (T, String) = #externalMacro(module: "Macros", type: "StringifyMacro")

@freestanding(expression)
public macro log(level: OSLogType, _ message: String) = #externalMacro(module: "Macros", type: "LoggingExpressionMacros")
