# Default

`Default` is a Swift package for defining fallback values on `Decodable` properties.

You write `@Default` on each property and `@DefaultDecodable` on the struct. The macros generate a private `DecodeDefaultValue` type per property and attach `@DefaultProperty` for lenient decoding. `@DefaultDecodable` never generates `CodingKeys` or `init(from:)`, so you can still provide your own Codable implementation.

## Quick start

```swift
import Default

@DefaultDecodable
struct User: Codable, Equatable {
    @Default("default name")
    var name: String

    @Default(10)
    var age: Int
}

let user = User(name: "Alice", age: 25)
let decoded = try JSONDecoder().decode(User.self, from: jsonData)
```

## How it works

Three pieces work together:

| Piece | Role |
|-------|------|
| `@Default` | Marker only. Generates a private `DecodeDefaultValue` type for the property. |
| `@DefaultProperty` | Property wrapper that decodes leniently when a JSON key is present. |
| `@DefaultDecodable` | Attaches `@DefaultProperty` to each `@Default` property. Does not generate `CodingKeys` or `init(from:)`. |

Given this source:

```swift
@DefaultDecodable
struct User: Codable, Equatable {
    @Default("default name")
    var name: String

    @Default(10)
    var age: Int
}
```

the macros expand it to something like:

```swift
@DefaultDecodable
struct User: Codable, Equatable {
    enum __DefaultValue_name: DecodeDefaultValue {
        typealias T = String
        static var defaultValue: String { "default name" }
    }

    enum __DefaultValue_age: DecodeDefaultValue {
        typealias T = Int
        static var defaultValue: Int { 10 }
    }

    @Default("default name")
    @DefaultProperty<__DefaultValue_name>
    var name: String

    @Default(10)
    @DefaultProperty<__DefaultValue_age>
    var age: Int
}
```

`DecodeDefaultValue` holds the fallback value. `DefaultProperty` uses that type when decoding from a single-value container.

## Decoding behavior

When a JSON key **is present**, `DefaultProperty` handles decoding:

| Input | Result |
|-------|--------|
| Valid value | Decodes normally |
| `null` | Falls back to default |
| Wrong type | Falls back to default |

When a JSON key **is missing**, Swift's synthesized `Decodable` implementation does not apply property-wrapper defaults automatically. Provide your own `init(from:)` if you need fallback behavior for missing keys (see below).

## Supported default expressions

`@Default` accepts `Int`, `Bool`, `String`, `Double`, and `Float` literals, as well as expressions that resolve to those types:

```swift
private enum Defaults {
    static let name = "guest"
}

@DefaultDecodable
struct Settings: Codable {
    @Default(0) var count: Int
    @Default(true) var isEnabled: Bool
    @Default("guest") var nickname: String
    @Default(Defaults.name) var name: String
}
```

Each property needs an explicit type annotation (for example `var name: String`, not `var name`).

## Custom `CodingKeys`

`@DefaultDecodable` does not generate `CodingKeys`. You can define your own:

```swift
@DefaultDecodable
struct Config: Decodable {
    @Default("production")
    var environment: String

    enum CodingKeys: String, CodingKey {
        case environment = "env"
    }
}
```

Swift synthesizes `init(from:)` from your `CodingKeys`. `@DefaultProperty` still handles `null` and type mismatches when the key is present.

## Custom `init(from:)` for missing keys

When you need defaults for **missing** keys, write your own initializer and use the generated `__DefaultValue_*` type:

```swift
@DefaultDecodable
struct Settings: Decodable {
    @Default("guest")
    var nickname: String

    enum CodingKeys: String, CodingKey {
        case nickname
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        _nickname = try container.decodeIfPresent(
            DefaultProperty<__DefaultValue_nickname>.self,
            forKey: .nickname
        ) ?? DefaultProperty(wrappedValue: __DefaultValue_nickname.defaultValue)
    }
}
```

Because `@DefaultDecodable` never generates `init(from:)`, this does not conflict with the macros.

## Requirements

- Swift 6.0+
- iOS 13+, macOS 10.15+, tvOS 13+, watchOS 6+

## Installation

Add the package to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/your-org/Default.git", from: "1.0.0"),
]
```

Or add it locally:

```swift
dependencies: [
    .package(path: "../Default"),
]
```

Then add `Default` to your target dependencies:

```swift
.target(
    name: "YourTarget",
    dependencies: ["Default"]
)
```
