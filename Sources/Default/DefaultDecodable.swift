/// Attaches `@DefaultProperty` to each `@Default` property. Does not generate
/// `CodingKeys` or `init(from:)`.
@attached(memberAttribute)
public macro DefaultDecodable() = #externalMacro(module: "DefaultMacros", type: "DefaultDecodableMacro")
