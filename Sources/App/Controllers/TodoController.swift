import Fluent
import Vapor

struct TodoController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let tokenAuthRoutes = routes.grouped("todos").grouped(Token.authenticator().middleware(), User.guardMiddleware())
        tokenAuthRoutes.get(use: indexHandler)
        tokenAuthRoutes.post(use: createHandler)
        tokenAuthRoutes.delete(":todoID", use: deleteHandler)
    }
    
    func indexHandler(_ req: Request) throws -> EventLoopFuture<[Todo]> {
        return Todo.query(on: req.db).all()
    }

    func createHandler(_ req: Request) throws -> EventLoopFuture<Todo> {
        let data = try req.content.decode(TodoCreateData.self)
        let user = try req.auth.require(User.self)
        let todo = try Todo(title: data.title, userID: user.requireID())
        return todo.save(on: req.db).map { todo }
    }

    func deleteHandler(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        return Todo.find(req.parameters.get("todoID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { todo in
                do {
                    let user = try req.auth.require(User.self)
                    guard try user.userType == .admin || user.requireID() == todo.$user.id else {
                        throw Abort(.forbidden)
                    }
                    return todo.delete(on: req.db).transform(to: .ok)
                } catch {
                    return req.eventLoop.makeFailedFuture(error)
                }
        }
    }
}

struct TodoCreateData: Content {
    let title: String
}
