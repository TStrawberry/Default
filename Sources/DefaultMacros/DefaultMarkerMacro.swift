import SwiftSyntax
import SwiftSyntaxMacros

enum DefaultPropertyMacroError: Error, CustomStringConvertible {
    case notVariable
    case missingDefaultValue
    case missingTypeAnnotation(property: String)

    var description: String {
        switch self {
        case .notVariable:
            "@Default can only be applied to stored properties"
        case .missingDefaultValue:
            "@Default requires a default value argument"
        case let .missingTypeAnnotation(property):
            "@Default requires an explicit type for `\(property)`"
        }
    }
}

public struct DefaultMarkerMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let varDecl = declaration.as(VariableDeclSyntax.self) else {
            throw DefaultPropertyMacroError.notVariable
        }

        let bindingInfo = try bindingInfo(from: varDecl, attribute: node)
        let typeName = defaultValueTypeName(for: bindingInfo.name)
        let accessLevel = accessLevelKeyword(for: varDecl)

        let enumDecl: DeclSyntax
        if accessLevel.isEmpty {
            enumDecl = """
                enum \(raw: typeName): DecodeDefaultValue {
                    typealias T = \(raw: bindingInfo.type)
                    static var defaultValue: \(raw: bindingInfo.type) { \(raw: bindingInfo.defaultExpression) }
                }
                """
        } else {
            enumDecl = """
                \(raw: accessLevel) enum \(raw: typeName): DecodeDefaultValue {
                    \(raw: accessLevel) typealias T = \(raw: bindingInfo.type)
                    \(raw: accessLevel) static var defaultValue: \(raw: bindingInfo.type) {
                        \(raw: bindingInfo.defaultExpression)
                    }
                }
                """
        }

        return [DeclSyntax(enumDecl)]
    }
}

private struct BindingInfo {
    let name: String
    let type: String
    let defaultExpression: String
}

private func defaultValueTypeName(for propertyName: String) -> String {
    "__DefaultValue_\(propertyName)"
}

private func accessLevelKeyword(for varDecl: VariableDeclSyntax) -> String {
    if varDecl.modifiers.contains(where: { $0.name.text == "public" }) {
        return "public"
    }

    if varDecl.modifiers.contains(where: { $0.name.text == "package" }) {
        return "package"
    }

    return ""
}

private func bindingInfo(
    from varDecl: VariableDeclSyntax,
    attribute: AttributeSyntax
) throws -> BindingInfo {
    guard let binding = varDecl.bindings.first,
          let pattern = binding.pattern.as(IdentifierPatternSyntax.self) else {
        throw DefaultPropertyMacroError.notVariable
    }

    guard binding.accessorBlock == nil else {
        throw DefaultPropertyMacroError.notVariable
    }

    guard let typeAnnotation = binding.typeAnnotation else {
        throw DefaultPropertyMacroError.missingTypeAnnotation(property: pattern.identifier.text)
    }

    guard case let .argumentList(arguments) = attribute.arguments,
          let defaultExpression = arguments.first?.expression else {
        throw DefaultPropertyMacroError.missingDefaultValue
    }

    return BindingInfo(
        name: pattern.identifier.text,
        type: typeAnnotation.type.trimmedDescription,
        defaultExpression: defaultExpression.trimmedDescription
    )
}
