import Fluent
import Vapor

struct UserController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let userRoutes = routes.grouped("users")
        userRoutes.get(use: index)
        userRoutes.post(use: create)
        let httpBasicAuthRoutes = userRoutes.grouped(User.authenticator().middleware())
        httpBasicAuthRoutes.post("login", use: login)
        
        let tokenAuthRoutes = userRoutes.grouped(Token.authenticator().middleware())
        tokenAuthRoutes.get("me", use: getMyDetails)
        tokenAuthRoutes.delete(":userID", use: delete)
    }
    
    func index(req: Request) throws -> EventLoopFuture<[User]> {
        return User.query(on: req.db).all()
    }

    func create(req: Request) throws -> EventLoopFuture<User> {
        let user = try req.content.decode(User.self)
        user.passwordHash = try Bcrypt.hash(user.passwordHash)
        return user.save(on: req.db).map { user }
    }

    func delete(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        return User.find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { $0.delete(on: req.db) }
            .transform(to: .ok)
    }
    
    func login(req: Request) throws -> EventLoopFuture<Token> {
        let user = try req.auth.require(User.self)
        let token = try user.generateToken()
        return token.save(on: req.db).map { token }
    }
    
    func getMyDetails(req: Request) throws -> User {
        try req.auth.require(User.self)
    }
}
