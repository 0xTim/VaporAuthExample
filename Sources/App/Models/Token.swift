import Fluent
import Vapor

final class Token: Model, Content, ModelTokenAuthenticatable {    
    typealias User = App.User
    static let schema = "tokens"
    static let valueKey = \Token.$value
    static let userKey = \Token.$user
    
    var isValid: Bool {
        return self.expiresAt > Date() && !self.isRevoked
    }
    
    @ID(key: .id)
    var id: UUID?

    @Field(key: "token_value")
    var value: String
    
    @Parent(key: "user_id")
    var user: User
    
    @Field(key: "expires_at")
    var expiresAt: Date
    
    @Field(key: "is_revoked")
    var isRevoked: Bool

    init() { }

    init(id: UUID? = nil, value: String, userID: User.IDValue) {
        self.id = id
        self.value = value
        self.$user.id = userID
        // Set expirty to 30 days
        self.expiresAt = Date().advanced(by: 60 * 60 * 24 * 30)
        self.isRevoked = false
    }
}


