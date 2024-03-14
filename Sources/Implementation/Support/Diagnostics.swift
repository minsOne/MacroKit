import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacroExpansion

// MARK: - Diagnose VariableDeclSyntax

func diagnoseMultipleConfigurations(variable: VariableDeclSyntax) -> [Diagnostic]? {
  guard variable.customConfigurationAttributes.count > 1 else { return nil }

  return variable.customConfigurationAttributes.dropFirst().map { attribute in
    Diagnostic(
      node: attribute,
      message: MacroExpansionErrorMessage(
        "Multiple @Init configurations are not supported by @MemberwiseInit"
      )
    )
  }
}

func diagnoseVariableDecl(
  customSettings: VariableCustomSettings?,
  variable: VariableDeclSyntax,
  targetAccessLevel: AccessLevelModifier
) -> [Diagnostic] {
  let customSettingsDiagnostics =
    customSettings.map { settings in
      if let diagnostic = diagnoseInitOnInitializedLet(customSettings: settings, variable: variable)
      {
        return [diagnostic]
      }

      if let diagnostic = diagnoseMemberModifiers(customSettings: settings, variable: variable) {
        return [diagnostic]
      }

      return [
        diagnoseVariableLabel(customSettings: settings, variable: variable),
        diagnoseDefaultValueAppliedToMultipleBindings(
          customSettings: settings,
          variable: variable
        )
          ?? diagnoseDefaultValueAppliedToInitialized(customSettings: settings, variable: variable),
      ].compactMap { $0 }
    } ?? [Diagnostic]()

  let accessibilityDiagnostics = [
    diagnoseAccessibilityLeak(
      customSettings: customSettings,
      variable: variable,
      targetAccessLevel: targetAccessLevel
    )
  ].compactMap { $0 }

  return customSettingsDiagnostics + accessibilityDiagnostics
}

private func diagnoseInitOnInitializedLet(
  customSettings: VariableCustomSettings,
  variable: VariableDeclSyntax
) -> Diagnostic? {
  guard
    variable.isLet,
    variable.isFullyInitialized
  else { return nil }

  let fixIts = [
    variable.fixItRemoveCustomInit,
    variable.fixItRemoveInitializer,
  ].compactMap { $0 }

  var diagnosticMessage: DiagnosticMessage {
    let attributeName = customSettings.customAttributeName

    let message = "@\(attributeName) can't be applied to already initialized constant"

    // @InitWrapper and @InitRaw can be errors instead of warnings since they haven't seen release.
    if attributeName != "Init" {
      return MacroExpansionErrorMessage(message)
    }
    // @Init(default:) hasn't seen release, so any misuses that include "default" can be an error.
    if variable.includesArgument("default") {
      return MacroExpansionErrorMessage(message)
    }

    // TODO: For 1.0, @Init can also be an error
    // Conservatively, make @Init be a warning to tolerate uses relying on @Init being silently ignored.
    return MacroExpansionWarningMessage(message)
  }

  return customSettings.diagnosticOnDefault(diagnosticMessage, fixIts: fixIts)
}

private func diagnoseMemberModifiers(
  customSettings: VariableCustomSettings,
  variable: VariableDeclSyntax
) -> Diagnostic? {
  let attributeName = customSettings.customAttributeName

  if let modifier = variable.firstModifierWhere(keyword: .static) {
    return Diagnostic(
      node: modifier,
      message: MacroExpansionWarningMessage(
        "@\(attributeName) can't be applied to 'static' members"),
      fixIts: [variable.fixItRemoveCustomInit].compactMap { $0 }
    )
  }

  if let modifier = variable.firstModifierWhere(keyword: .lazy) {
    return Diagnostic(
      node: modifier,
      message: MacroExpansionWarningMessage("@\(attributeName) can't be applied to 'lazy' members"),
      fixIts: [variable.fixItRemoveCustomInit].compactMap { $0 }
    )
  }

  return nil
}

private func diagnoseVariableLabel(
  customSettings: VariableCustomSettings,
  variable: VariableDeclSyntax
) -> Diagnostic? {
  if let label = customSettings.label,
    label != "_",
    variable.bindings.count > 1
  {
    return customSettings.diagnosticOnLabel(
      MacroExpansionErrorMessage("Custom 'label' can't be applied to multiple bindings")
    )
  }

  if customSettings.label?.isInvalidSwiftLabel ?? false {
    return customSettings.diagnosticOnLabelValue(MacroExpansionErrorMessage("Invalid label value"))
  }

  return nil
}

private func diagnoseDefaultValueAppliedToMultipleBindings(
  customSettings: VariableCustomSettings,
  variable: VariableDeclSyntax
) -> Diagnostic? {
  guard
    let defaultValue = customSettings.defaultValue,
    variable.bindings.count > 1
  else { return nil }

  let fixIts = [
    determineRemoveDefaultFixIt(variable: variable, defaultValue: defaultValue),
    determineRemoveCustomInitFixIt(variable: variable),
  ].compactMap { $0 }

  return customSettings.diagnosticOnDefault(
    MacroExpansionErrorMessage("Custom 'default' can't be applied to multiple bindings"),
    fixIts: fixIts
  )
}

private func diagnoseDefaultValueAppliedToInitialized(
  customSettings: VariableCustomSettings,
  variable: VariableDeclSyntax
) -> Diagnostic? {
  guard
    let defaultValue = customSettings.defaultValue,
    variable.isFullyInitialized
  else { return nil }

  let fixIts = [
    determineRemoveDefaultFixIt(variable: variable, defaultValue: defaultValue),
    determineRemoveCustomInitFixIt(variable: variable),
    variable.fixItRemoveInitializer,
  ].compactMap { $0 }

  return customSettings.diagnosticOnDefault(
    MacroExpansionErrorMessage("Custom 'default' can't be applied to already initialized variable"),
    fixIts: fixIts
  )
}

private func determineRemoveDefaultFixIt(
  variable: VariableDeclSyntax,
  defaultValue: String
) -> FixIt? {
  let shouldRemoveDefault =
    variable.isVar
    && (!variable.hasSoleArgument("default") || variable.hasNonConfigurationAttributes)
    || variable.bindings.count > 1 && !variable.hasSoleArgument("default")

  return shouldRemoveDefault ? variable.fixItRemoveDefault(defaultValue: defaultValue) : nil
}

private func determineRemoveCustomInitFixIt(
  variable: VariableDeclSyntax
) -> FixIt? {
  let shouldRemoveCustomInit =
    !variable.hasNonConfigurationAttributes && variable.hasSoleArgument("default")

  return shouldRemoveCustomInit ? variable.fixItRemoveCustomInit : nil
}

private func diagnoseAccessibilityLeak(
  customSettings: VariableCustomSettings?,
  variable: VariableDeclSyntax,
  targetAccessLevel: AccessLevelModifier
) -> Diagnostic? {
  let effectiveAccessLevel = customSettings?.accessLevel ?? variable.accessLevel

  guard
    targetAccessLevel > effectiveAccessLevel,
    !variable.isFullyInitializedLet
  else { return nil }

  let customAccess = variable.customConfigurationArguments?
    .first?
    .expression
    .as(MemberAccessExprSyntax.self)

  let targetNode =
    customAccess?._syntaxNode
    ?? (variable.modifiers.isEmpty ? variable._syntaxNode : variable.modifiers._syntaxNode)

  return Diagnostic(
    node: targetNode,
    message: MacroExpansionErrorMessage(
      """
      @MemberwiseInit(.\(targetAccessLevel)) would leak access to '\(effectiveAccessLevel)' property
      """
    )
  )
}

// MARK: - Diagnose [PropertyBinding] and [MemberProperty]

func customInitLabelDiagnosticsFor(bindings: [PropertyBinding]) -> [Diagnostic] {
  var diagnostics: [Diagnostic] = []

  let customLabeledBindings = bindings.filter {
    $0.variable.customSettings?.label != nil
  }

  // Diagnose custom label conflicts with another custom label
  var seenCustomLabels: Set<String> = []
  for binding in customLabeledBindings {
    guard
      let customSettings = binding.variable.customSettings,
      let label = customSettings.label,
      label != "_"
    else { continue }
    defer { seenCustomLabels.insert(label) }
    if seenCustomLabels.contains(label) {
      diagnostics.append(
        customSettings.diagnosticOnLabelValue(
          MacroExpansionErrorMessage("Label '\(label)' conflicts with another label")
        )
      )
    }
  }

  return diagnostics
}

func customInitLabelDiagnosticsFor(properties: [MemberProperty]) -> [Diagnostic] {
  var diagnostics: [Diagnostic] = []

  let propertiesByName = Dictionary(grouping: properties, by: { $0.name })

  // Diagnose custom label conflicts with a property
  for property in properties {
    guard
      let propertyCustomSettings = property.customSettings,
      let label = propertyCustomSettings.label,
      let duplicates = propertiesByName[label],
      duplicates.contains(where: { $0 != property })
    else { continue }

    diagnostics.append(
      propertyCustomSettings.diagnosticOnLabelValue(
        MacroExpansionErrorMessage("Label '\(label)' conflicts with a property name")
      )
    )
  }

  return diagnostics
}

// MARK: Fix-its

extension VariableDeclSyntax {
  func fixItRemoveDefault(defaultValue: String) -> FixIt? {
    guard
      let customAttribute = self.customConfigurationAttribute,
      let arguments = self.customConfigurationArguments
    else { return nil }

    var newAttribute = customAttribute
    let newArguments = arguments.filter { $0.label?.text != "default" }
    newAttribute.arguments = newArguments.as(AttributeSyntax.Arguments.self)
    if newArguments.count == 0 {
      newAttribute.leftParen = nil
      newAttribute.rightParen = nil
    }

    return FixIt(
      message: MacroExpansionFixItMessage("Remove 'default: \(defaultValue)'"),
      changes: [
        FixIt.Change.replace(
          oldNode: Syntax(customAttribute),
          newNode: Syntax(newAttribute))
      ]
    )
  }

  var fixItRemoveCustomInit: FixIt? {
    guard let customAttribute = self.customConfigurationAttribute else { return nil }

    let newVariable = AttributeRemover(
      removingWhere: {
        ["Init", "InitWrapper", "InitRaw"].contains($0.attributeName.trimmedDescription)
      }
    ).rewrite(self)

    return FixIt(
      message: MacroExpansionFixItMessage("Remove '\(customAttribute.trimmedDescription)'"),
      changes: [
        FixIt.Change.replace(
          oldNode: Syntax(self), newNode: Syntax(newVariable)
        )
      ]
    )
  }

  var fixItRemoveInitializer: FixIt? {
    guard
      self.bindings.count == 1,
      let firstBinding = self.bindings.first,
      let firstBindingInitializer = firstBinding.initializer
    else { return nil }

    var newFirstBinding = firstBinding.with(\.initializer, nil)

    if firstBinding.typeAnnotation == nil {
      let inferredTypeSyntax = firstBindingInitializer.value.inferredTypeSyntax

      newFirstBinding.typeAnnotation = TypeAnnotationSyntax(
        colon: .colonToken(trailingTrivia: .space),
        type: inferredTypeSyntax
          ?? MissingTypeSyntax(placeholder: TokenSyntax(stringLiteral: "\u{3C}#Type#\u{3E}"))
          .as(TypeSyntax.self)!
      )
      newFirstBinding.pattern = newFirstBinding.pattern.trimmed
    }

    var newNode = self.detached
    newNode.bindings = .init(arrayLiteral: newFirstBinding)

    return FixIt(
      message: MacroExpansionFixItMessage(
        "Remove '\(firstBindingInitializer.trimmedDescription)'"
      ),
      changes: [
        FixIt.Change.replace(
          oldNode: Syntax(self), newNode: Syntax(newNode)
        )
      ]
    )
  }
}

struct SimpleDiagnosticMessage: DiagnosticMessage, Error {
    let message: String
    let diagnosticID: MessageID
    let severity: DiagnosticSeverity
}

extension SimpleDiagnosticMessage: FixItMessage {
    var fixItID: MessageID { diagnosticID }
}

enum CustomError: Error, CustomStringConvertible {
    case message(String)

    var description: String {
        switch self {
        case .message(let text): text
        }
    }
}
