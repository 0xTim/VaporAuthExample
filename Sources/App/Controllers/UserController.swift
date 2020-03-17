import Fluent
import Vapor

struct UserController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let userRoutes = routes.grouped("users")
        userRoutes.get(use: indexHandler)
        userRoutes.post(use: createHandler)
        let httpBasicAuthRoutes = userRoutes.grouped(User.authenticator().middleware())
        httpBasicAuthRoutes.post("login", use: loginHandler)
        
        let tokenAuthRoutes = userRoutes.grouped(Token.authenticator().middleware())
        tokenAuthRoutes.get("me", use: getMyDetailsHandler)
        tokenAuthRoutes.delete(":userID", use: deleteHandler)
    }
    
    func indexHandler(_ req: Request) throws -> EventLoopFuture<[User]> {
        return User.query(on: req.db).all()
    }

    func createHandler(_ req: Request) throws -> EventLoopFuture<User> {
        let user = try req.content.decode(User.self)
        user.passwordHash = try Bcrypt.hash(user.passwordHash)
        return user.save(on: req.db).map { user }
    }

    func deleteHandler(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        return User.find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { $0.delete(on: req.db) }
            .transform(to: .ok)
    }
    
    func loginHandler(_ req: Request) throws -> EventLoopFuture<Token> {
        let user = try req.auth.require(User.self)
        let token = try user.generateToken()
        return token.save(on: req.db).map { token }
    }
    
    func getMyDetailsHandler(_ req: Request) throws -> User {
        try req.auth.require(User.self)
    }
}
