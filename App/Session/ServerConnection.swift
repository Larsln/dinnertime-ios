import Foundation
import DinnertimeKit

/// A server whose address was validated but where nobody is signed in yet.
struct ServerConnection: Equatable {
    /// Root URL of the server.
    let url: URL
    /// What the server said about itself.
    let info: ServerInfo
}
