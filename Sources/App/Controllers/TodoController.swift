import Fluent
import Vapor

struct TodoController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let tokenAuthRoutes = routes.grouped("todos").grouped(Token.authenticator(), User.guardMiddleware())
        tokenAuthRoutes.get(use: indexHandler)
        tokenAuthRoutes.post(use: createHandler)
        tokenAuthRoutes.delete(":todoID", use: deleteHandler)
    }
    
    func indexHandler(_ req: Request) async throws -> [Todo] {
        return try await Todo.query(on: req.db).all()
    }

    func createHandler(_ req: Request) async throws -> Todo {
        let data = try req.content.decode(TodoCreateData.self)
        let user = try req.auth.require(User.self)
        let todo = try Todo(title: data.title, userID: user.requireID())
        try await todo.save(on: req.db)
        return todo
    }

    func deleteHandler(_ req: Request) async throws -> HTTPStatus {
        guard let todo: Todo = try await Todo.find(req.parameters.get("todoID"), on: req.db) else {
          throw Abort(.notFound)
        }

        let user = try req.auth.require(User.self)
        guard try user.userType == .admin || user.requireID() == todo.$user.id else {
            throw Abort(.forbidden)
        }

        try await todo.delete(on: req.db)
        return .ok

    }
}

struct TodoCreateData: Content {
    let title: String
}
