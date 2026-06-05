import SwiftSyntax
import SwiftSyntaxMacros

enum DefaultDecodableMacroError: Error, CustomStringConvertible {
    case notStruct
    case missingTypeAnnotation(property: String)
    case missingDefaultValue(property: String)

    var description: String {
        switch self {
        case .notStruct:
            "@DefaultDecodable can only be applied to struct declarations"
        case let .missingTypeAnnotation(property):
            "@Default requires an explicit type for `\(property)`"
        case let .missingDefaultValue(property):
            "@Default requires a default value for `\(property)`"
        }
    }
}

public struct DefaultDecodableMacro: MemberAttributeMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingAttributesFor member: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AttributeSyntax] {
        guard let varDecl = member.as(VariableDeclSyntax.self),
              hasDefaultAttribute(varDecl),
              let name = varDecl.bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else {
            return []
        }

        let typeName = defaultValueTypeName(for: name)
        return [
            AttributeSyntax(
                "@DefaultProperty<\(raw: typeName)>" // (wrappedValue: \(raw: typeName).defaultValue)
            ),
        ]
    }
}

private func defaultValueTypeName(for propertyName: String) -> String {
    "__DefaultValue_\(propertyName)"
}

private func hasDefaultAttribute(_ varDecl: VariableDeclSyntax) -> Bool {
    varDecl.attributes.contains { attribute in
        guard let attribute = attribute.as(AttributeSyntax.self) else { return false }
        return attribute.attributeName.trimmedDescription == "Default"
    }
}
