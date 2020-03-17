import Fluent
import Vapor

final class Token: Model, Content, ModelUserToken {
    static let schema = "tokens"
    static let valueKey = \Token.$value
    static let userKey = \Token.$user
    
    var isValid: Bool {
        true
    }
    
    @ID(key: .id)
    var id: UUID?

    @Field(key: "token_value")
    var value: String
    
    @Parent(key: "user_id")
    var user: User

    init() { }

    init(id: UUID? = nil, value: String, userID: User.IDValue) {
        self.id = id
        self.value = value
        self.$user.id = userID
    }
}


