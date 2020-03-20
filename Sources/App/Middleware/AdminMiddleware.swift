import Vapor

struct AdminMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        guard let user = try? request.auth.require(User.self), user.userType == .admin else {
            return request.eventLoop.makeFailedFuture(Abort(.forbidden))
        }
        return next.respond(to: request)
    }
}
