import Fluent

struct CreateToken: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("tokens")
            .id()
            .field("token_value", .string, .required)
            .field("user_id", .uuid, .required, .references("users", "id"))
            .field("expires_at", .date, .required)
            .unique(on: "token_value")
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("tokens").delete()
    }
}

