import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct DefaultMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        DefaultMarkerMacro.self,
        DefaultDecodableMacro.self,
    ]
}
