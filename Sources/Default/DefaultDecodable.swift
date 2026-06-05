/// Attaches `@DefaultProperty` to each `@Default` property and generates a
/// memberwise `init` with default values for those properties. Does not
/// generate `CodingKeys` or `init(from:)`.
@attached(member, names: named(init))
@attached(memberAttribute)
public macro DefaultDecodable() = #externalMacro(module: "DefaultMacros", type: "DefaultDecodableMacro")
