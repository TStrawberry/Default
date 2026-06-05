import Foundation
import Testing
@testable import Default

@DefaultDecodable
public struct User: Codable, Equatable {
    @Default("default name")
    public internal(set) var name: String

    @Default(10)
    var age: Int
    
    var isAdult: Bool
}

@Test func normalInitialization() throws {
    let user = User(name: "Alice", age: 25, isAdult: true)
    
    #expect(user.name == "Alice")
    #expect(user.age == 25)
    #expect(user.isAdult)
}

@Test func defaultInitialization() throws {
    let user = User(isAdult: true)

    #expect(user.name == "default name")
    #expect(user.age == 10)
    #expect(user.isAdult)
}

@Test func generatedInitUsesDefaultValues() {
    let user = User(isAdult: false)

    #expect(user.name == "default name")
    #expect(user.age == 10)
    #expect(user.isAdult == false)
}

@Test func decodeTheFieldsThatIsNotMarked() throws {
    let json = #"{"name": "Alice", "age": 25}"#
    do {
        let _ = try JSONDecoder().decode(User.self, from: Data(json.utf8))
    } catch DecodingError.keyNotFound(let key, _) {
        #expect(key.stringValue == "isAdult")
    }
}

@Test func presentValidValueOverridesDefault() throws {
    let json = #"{"name": "Alice", "age": 25, "isAdult": true }"#
    let user = try JSONDecoder().decode(User.self, from: Data(json.utf8))
    
    #expect(user.name == "Alice")
    #expect(user.age == 25)
}

@Test func nullValueFallsBackToDefault() throws {
    let json = #"{"name": null, "age": null, "isAdult": false }"#
    let user = try JSONDecoder().decode(User.self, from: Data(json.utf8))

    #expect(user.name == "default name")
    #expect(user.age == 10)
}

@Test func wrongTypeFallsBackToDefault() throws {
    let json = #"{"name": 123, "age": "x", "isAdult": true }"#
    let user = try JSONDecoder().decode(User.self, from: Data(json.utf8))

    #expect(user.name == "default name")
    #expect(user.age == 10)
}

@Test func multipleDefaultedPropertiesDecodeIndependently() throws {
    let json = #"{"age": 20, "isAdult": true}"#
    let user = try JSONDecoder().decode(User.self, from: Data(json.utf8))

    #expect(user.name == "default name")
    #expect(user.age == 20)
    #expect(user.isAdult)
}

@Test func encodesWrappedValueOnly() throws {
    let json = #"{"name": "Bob", "age": 1, "isAdult": false }"#
    var user = try JSONDecoder().decode(User.self, from: Data(json.utf8))
    user.name = "Charlie"
    user.age = 2

    let data = try JSONEncoder().encode(user)
    let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]

    #expect(object?["name"] as? String == "Charlie")
    #expect(object?["age"] as? Int == 2)
    #expect(object?["isAdult"] as? Bool == false)
}

@Test func sharedDefaultValueTypeCanBeReused() throws {
    let json = #"{"name": "Bob", "isAdult": false }"#
    let user = try JSONDecoder().decode(User.self, from: Data(json.utf8))

    #expect(user.name == "Bob")
    #expect(user.age == 10)
    #expect(user.isAdult == false)
}

@Test func customCodingKeysRemainAvailable() throws {
    @DefaultDecodable
    struct Config: Decodable, Equatable {
        @Default("production")
        var environment: String

        enum CodingKeys: String, CodingKey {
            case environment = "env"
        }
    }

    let json = #"{"env": "staging"}"#
    let config = try JSONDecoder().decode(Config.self, from: Data(json.utf8))

    #expect(config.environment == "staging")
}

@Test func handleMissingKeys() throws {
    let json = #"{ "isAdult": false }"#
    let user = try JSONDecoder().decode(User.self, from: Data(json.utf8))
    #expect(user.name == "default name")
    #expect(user.age == 10)
}


