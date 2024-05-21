import MEGASwift
import MEGADomain

public class MockUserVideoPlaylistsRepository: UserVideoPlaylistsRepositoryProtocol, @unchecked Sendable {
    
    public enum Message: Sendable, Equatable {
        case userVideoPlaylists
        case addVideosToVideoPlaylist(id: HandleEntity, nodes: [NodeEntity])
        case deleteVideoPlaylistElements(videoPlaylistId: HandleEntity, elementIds: [HandleEntity])
        case deleteVideoPlaylist(id: HandleEntity)
        case videoPlaylistContent(id: HandleEntity, includeElementsInRubbishBin: Bool)
    }
    
    public private(set) var messages = [Message]()
    
    public let setsUpdatedAsyncSequence: AnyAsyncSequence<[SetEntity]>
    public let setElementsUpdatedAsyncSequence: AnyAsyncSequence<[SetElementEntity]>
    private let videoPlaylistsResult: [SetEntity]
    private let addVideosToVideoPlaylistResult: Result<VideoPlaylistCreateSetElementsResultEntity, Error>
    private let deleteVideosResult: Result<VideoPlaylistCreateSetElementsResultEntity, Error>
    private let deleteVideoPlaylistResult: Result<VideoPlaylistEntity, Error>
    private let videoPlaylistContentResult: [SetElementEntity]
    
    public init(
        videoPlaylistsResult: [SetEntity] = [],
        addVideosToVideoPlaylistResult: Result<VideoPlaylistCreateSetElementsResultEntity, Error> = .failure(GenericErrorEntity()),
        deleteVideosResult: Result<VideoPlaylistCreateSetElementsResultEntity, Error> = .failure(GenericErrorEntity()),
        deleteVideoPlaylistResult: Result<VideoPlaylistEntity, Error> = .failure(GenericErrorEntity()),
        videoPlaylistContentResult: [SetElementEntity] = [],
        setsUpdatedAsyncSequence: AnyAsyncSequence<[SetEntity]> = EmptyAsyncSequence().eraseToAnyAsyncSequence(),
        setElementsUpdatedAsyncSequence: AnyAsyncSequence<[SetElementEntity]> = EmptyAsyncSequence().eraseToAnyAsyncSequence()
    ) {
        self.videoPlaylistsResult = videoPlaylistsResult
        self.addVideosToVideoPlaylistResult = addVideosToVideoPlaylistResult
        self.deleteVideosResult = deleteVideosResult
        self.deleteVideoPlaylistResult = deleteVideoPlaylistResult
        self.videoPlaylistContentResult = videoPlaylistContentResult
        self.setsUpdatedAsyncSequence = setsUpdatedAsyncSequence
        self.setElementsUpdatedAsyncSequence = setElementsUpdatedAsyncSequence
    }
    
    public func videoPlaylists() async -> [SetEntity] {
        messages.append(.userVideoPlaylists)
        return videoPlaylistsResult
    }
    
    public func addVideosToVideoPlaylist(by id: HandleEntity, nodes: [NodeEntity]) async throws -> VideoPlaylistCreateSetElementsResultEntity {
        messages.append(.addVideosToVideoPlaylist(id: id, nodes: nodes))
        return try addVideosToVideoPlaylistResult.get()
    }
    
    public func deleteVideoPlaylistElements(videoPlaylistId: HandleEntity, elementIds: [HandleEntity]) async throws -> VideoPlaylistCreateSetElementsResultEntity {
        messages.append(.deleteVideoPlaylistElements(videoPlaylistId: videoPlaylistId, elementIds: elementIds))
        return try deleteVideosResult.get()
    }
    
    public func deleteVideoPlaylist(by videoPlaylist: VideoPlaylistEntity) async throws -> VideoPlaylistEntity {
        messages.append(.deleteVideoPlaylist(id: videoPlaylist.id))
        return try deleteVideoPlaylistResult.get()
    }
    
    public func videoPlaylistContent(by id: HandleEntity, includeElementsInRubbishBin: Bool) async -> [SetElementEntity] {
        messages.append(.videoPlaylistContent(id: id, includeElementsInRubbishBin: includeElementsInRubbishBin))
        return videoPlaylistContentResult
    }
}
