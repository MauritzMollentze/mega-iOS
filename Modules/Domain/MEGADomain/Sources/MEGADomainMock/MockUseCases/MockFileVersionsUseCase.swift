import MEGADomain

public struct MockFileVersionsUseCase: FileVersionsUseCaseProtocol {
    private let versions: Int64
    private let versionsSize: Int64
    private let isFileVersionsEnabled: (Result<Bool, FileVersionErrorEntity>)
    private let enableFileVersions: (Result<Bool, FileVersionErrorEntity>)
    private let deletePreviousFileVersions: (Result<Bool, FileVersionErrorEntity>)
    
    public init(
        versions: Int64 = 0,
        versionsSize: Int64 = 0,
        isFileVersionsEnabled: Result<Bool, FileVersionErrorEntity> = .failure(.generic),
        enableFileVersions: Result<Bool, FileVersionErrorEntity> = .failure(.generic),
        deletePreviousFileVersions: Result<Bool, FileVersionErrorEntity> = .failure(.generic)
    ) {
        self.versions = versions
        self.versionsSize = versionsSize
        self.isFileVersionsEnabled = isFileVersionsEnabled
        self.enableFileVersions = enableFileVersions
        self.deletePreviousFileVersions = deletePreviousFileVersions
    }
    
    public func isFileVersionsEnabled() async throws -> Bool {
        try isFileVersionsEnabled.get()
    }
    
    public func enableFileVersions(_ enable: Bool) async throws -> Bool {
        try enableFileVersions.get()
    }
    
    public func rootNodeFileVersionCount() -> Int64 {
        versions
    }
    
    public func rootNodeFileVersionTotalSizeInBytes() -> Int64 {
        versionsSize
    }
    
    public func deletePreviousFileVersions() async throws -> Bool {
        try deletePreviousFileVersions.get()
    }
}
