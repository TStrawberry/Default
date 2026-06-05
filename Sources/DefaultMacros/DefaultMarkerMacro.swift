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
        let bindingInfo = try bindingInfo(from: declaration, attribute: node)
        let typeName = defaultValueTypeName(for: bindingInfo.name)

        return [
            DeclSyntax(
                """
                enum \(raw: typeName): DecodeDefaultValue {
                    typealias T = \(raw: bindingInfo.type)
                    static var defaultValue: \(raw: bindingInfo.type) { \(raw: bindingInfo.defaultExpression) }
                }
                """
            ),
        ]
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

private func bindingInfo(
    from declaration: some DeclSyntaxProtocol,
    attribute: AttributeSyntax
) throws -> BindingInfo {
    guard let varDecl = declaration.as(VariableDeclSyntax.self) else {
        throw DefaultPropertyMacroError.notVariable
    }

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
