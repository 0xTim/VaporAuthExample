import Vapor

struct AdminMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        guard let user = request.auth.get(User.self), user.userType == .admin else {
          throw Abort(.unauthorized)
        }
      
        return try await next.respond(to: request)
    }
}
