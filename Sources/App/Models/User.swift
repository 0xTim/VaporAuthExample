import Fluent
import Vapor

final class User: Model, Content, ModelAuthenticatable, @unchecked Sendable {
    static let schema = "users"
    static var usernameKey: KeyPath<User, Field<String>> { \.$email }
    static var passwordHashKey: KeyPath<User, Field<String>> { \.$passwordHash }

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String
    
    @Field(key: "email")
    var email: String
    
    @Field(key: "password_hash")
    var passwordHash: String
    
    @Field(key: "user_type")
    var userType: UserType

    init() { }

    init(id: UUID? = nil, name: String, email: String, passwordHash: String, userType: UserType) {
        self.id = id
        self.name = name
        self.email = email
        self.passwordHash = passwordHash
        self.userType = userType
    }
    
    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.passwordHash)
    }
}

extension User {
    func generateToken() throws -> Token {
        try .init(
            value: [UInt8].random(count: 32).base64,
            userID: self.requireID()
        )
    }
}

enum UserType: String, Content {
    case normal
    case admin
}
