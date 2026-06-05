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

public struct DefaultDecodableMacro: MemberMacro, MemberAttributeMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            throw DefaultDecodableMacroError.notStruct
        }

        guard !hasCustomInitializer(in: structDecl) else {
            return []
        }

        let properties = try storedProperties(in: structDecl)
        guard !properties.isEmpty else {
            return []
        }

        let parameters = properties.map { property in
            parameterDeclaration(for: property)
        }.joined(separator: ",\n    ")

        let assignments = properties.map { property in
            "self.\(property.name) = \(property.name)"
        }.joined(separator: "\n        ")

        return [
            DeclSyntax(
                """
                init(
                    \(raw: parameters)
                ) {
                    \(raw: assignments)
                }
                """
            ),
        ]
    }

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
            AttributeSyntax("@DefaultProperty<\(raw: typeName)>"),
        ]
    }
}

private struct PropertyInfo {
    let name: String
    let type: String
    let defaultExpression: String?
}

private func defaultValueTypeName(for propertyName: String) -> String {
    "__DefaultValue_\(propertyName)"
}

private func parameterDeclaration(for property: PropertyInfo) -> String {
    if let defaultExpression = property.defaultExpression {
        return "\(property.name): \(property.type) = \(defaultExpression)"
    }

    return "\(property.name): \(property.type)"
}

private func hasCustomInitializer(in structDecl: StructDeclSyntax) -> Bool {
    structDecl.memberBlock.members.contains { member in
        guard let initializer = member.decl.as(InitializerDeclSyntax.self) else {
            return false
        }

        return !initializer.signature.parameterClause.parameters.contains { parameter in
            parameter.firstName.text == "from" && parameter.secondName?.text == "decoder"
        }
    }
}

private func storedProperties(in structDecl: StructDeclSyntax) throws -> [PropertyInfo] {
    var result: [PropertyInfo] = []

    for member in structDecl.memberBlock.members {
        guard let varDecl = member.decl.as(VariableDeclSyntax.self) else { continue }
        guard !varDecl.modifiers.contains(where: { $0.name.text == "static" || $0.name.text == "class" }) else {
            continue
        }

        for binding in varDecl.bindings {
            guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self) else { continue }
            guard binding.accessorBlock == nil else { continue }
            guard let typeAnnotation = binding.typeAnnotation else {
                throw DefaultDecodableMacroError.missingTypeAnnotation(property: pattern.identifier.text)
            }

            let name = pattern.identifier.text
            let type = typeAnnotation.type.trimmedDescription

            result.append(
                PropertyInfo(
                    name: name,
                    type: type,
                    defaultExpression: defaultArgumentExpression(from: varDecl)
                )
            )
        }
    }

    return result
}

private func hasDefaultAttribute(_ varDecl: VariableDeclSyntax) -> Bool {
    varDecl.attributes.contains { attribute in
        guard let attribute = attribute.as(AttributeSyntax.self) else { return false }
        return attribute.attributeName.trimmedDescription == "Default"
    }
}

private func defaultArgumentExpression(from varDecl: VariableDeclSyntax) -> String? {
    for attribute in varDecl.attributes {
        guard let attribute = attribute.as(AttributeSyntax.self),
              attribute.attributeName.trimmedDescription == "Default" else {
            continue
        }

        guard case let .argumentList(arguments) = attribute.arguments,
              let defaultExpression = arguments.first?.expression else {
            continue
        }

        return defaultExpression.trimmedDescription
    }

    return nil
}
