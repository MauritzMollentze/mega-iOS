public typealias SetHandleEntity = UInt64

public struct SetIdentifier: Equatable, Sendable {
    public let handle: SetHandleEntity
    
    public init(handle: SetHandleEntity) {
        self.handle = handle
    }
}