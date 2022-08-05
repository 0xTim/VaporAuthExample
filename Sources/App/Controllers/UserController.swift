import Fluent
import Vapor

struct UserController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let userRoutes = routes.grouped("users")
        userRoutes.get(use: indexHandler)
        userRoutes.post(use: createHandler)
        let httpBasicAuthRoutes = userRoutes.grouped(User.authenticator())
        httpBasicAuthRoutes.post("login", use: loginHandler)
        
        // Token.authenticator.middleware() adds Bearer authentication with middleware,
        // Guard middlware ensures a user is logged in
        let tokenAuthRoutes = userRoutes.grouped(Token.authenticator(), User.guardMiddleware())
        tokenAuthRoutes.get("me", use: getMyDetailsHandler)
        
        let adminMiddleware = tokenAuthRoutes.grouped(AdminMiddleware())
        adminMiddleware.delete(":userID", use: deleteHandler)
    }
    
    func indexHandler(_ req: Request) async throws -> [User] {
        return try await User.query(on: req.db).all()
    }

    func createHandler(_ req: Request) async throws -> User {
        let userData = try req.content.decode(CreateUserData.self)
        let passwordHash = try Bcrypt.hash(userData.password)
        let user = User(name: userData.name, email: userData.email, passwordHash: passwordHash, userType: userData.userType)
        try await user.save(on: req.db)
        return user
    }

    func deleteHandler(_ req: Request) async throws -> HTTPStatus {
      guard let user: User = try await User.find(req.parameters.get("userID"), on: req.db) else {
        throw Abort(.notFound)
      }
      try await user.delete(on: req.db)
      return .ok
    }
    
    func loginHandler(_ req: Request) async throws -> Token {
        let user = try req.auth.require(User.self)
        let token = try user.generateToken()
        try await token.save(on: req.db)
        return token
    }
    
    func getMyDetailsHandler(_ req: Request) throws -> User {
        try req.auth.require(User.self)
    }
}

struct CreateUserData: Content {
    let name: String
    let email: String
    let password: String
    let userType: UserType
}
