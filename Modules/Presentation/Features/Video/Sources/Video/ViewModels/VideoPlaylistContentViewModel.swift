import AsyncAlgorithms
import Combine
import MEGADomain
import MEGASwiftUI

final class VideoPlaylistContentViewModel: ObservableObject {
    
    private var videoPlaylistEntity: VideoPlaylistEntity
    private let videoPlaylistContentsUseCase: any VideoPlaylistContentsUseCaseProtocol
    private(set) var thumbnailUseCase: any ThumbnailUseCaseProtocol
    private let videoPlaylistThumbnailLoader: any VideoPlaylistThumbnailLoaderProtocol
    private let sortOrderPreferenceUseCase: any SortOrderPreferenceUseCaseProtocol
    
    @Published public private(set) var videos: [NodeEntity] = []
    @Published var headerPreviewEntity: VideoPlaylistCellPreviewEntity = .placeholder
    @Published var secondaryInformationViewType: VideoPlaylistCellViewModel.SecondaryInformationViewType = .emptyPlaylist
    @Published var shouldPopScreen = false
    @Published var shouldShowError = false
    
    public private(set) var sharedUIState: VideoPlaylistContentSharedUIState
    
    private(set) var presentationConfig: VideoPlaylistContentSnackBarPresentationConfig?
    
    init(
        videoPlaylistEntity: VideoPlaylistEntity,
        videoPlaylistContentsUseCase: some VideoPlaylistContentsUseCaseProtocol,
        thumbnailUseCase: some ThumbnailUseCaseProtocol,
        videoPlaylistThumbnailLoader: some VideoPlaylistThumbnailLoaderProtocol,
        sharedUIState: VideoPlaylistContentSharedUIState,
        presentationConfig: VideoPlaylistContentSnackBarPresentationConfig? = nil,
        sortOrderPreferenceUseCase: some SortOrderPreferenceUseCaseProtocol
    ) {
        self.videoPlaylistEntity = videoPlaylistEntity
        self.videoPlaylistContentsUseCase = videoPlaylistContentsUseCase
        self.thumbnailUseCase = thumbnailUseCase
        self.videoPlaylistThumbnailLoader = videoPlaylistThumbnailLoader
        self.sortOrderPreferenceUseCase = sortOrderPreferenceUseCase
        self.sharedUIState = sharedUIState
        self.presentationConfig = presentationConfig
    }
    
    @MainActor
    func onViewAppeared() async {
        configureSnackBar()
        await monitorUserVideoPlaylist()
    }
    
    private func configureSnackBar() {
        sharedUIState.shouldShowSnackBar = presentationConfig?.shouldShowSnackBar ?? false
        sharedUIState.snackBarText = presentationConfig?.text ?? ""
    }
    
    @MainActor
    private func monitorUserVideoPlaylist() async {
        do {
            let sortOrderChangedSequence = sortOrderPreferenceUseCase.monitorSortOrder(for: . videoPlaylistContent)
                .compactMap {  [weak self] (sortOrder: SortOrderEntity) -> SortOrderEntity? in
                    guard let self else {
                        return nil
                    }
                    return doesSupport(sortOrder) ? sortOrder : .defaultAsc
                }
                .removeDuplicates()
                .values
            
            let anyVideoPlaylistUpdateSequence = combineLatest(
                videoPlaylistContentsUseCase.monitorVideoPlaylist(for: videoPlaylistEntity),
                videoPlaylistContentsUseCase.monitorUserVideoPlaylistContent(for: videoPlaylistEntity),
                sortOrderChangedSequence
            )
            
            for try await (videoPlaylist, videos, sortOrder) in anyVideoPlaylistUpdateSequence {
                guard !Task.isCancelled else {
                    break
                }
                self.videoPlaylistEntity = videoPlaylist
                self.videos = VideoPlaylistContentSorter.sort(videos, by: sortOrder)
                self.sharedUIState.videosCount = videos.count
                await loadThumbnails(for: videos)
            }
        } catch {
            handle(error)
        }
    }
    
    @MainActor
    private func loadThumbnails(for videos: [NodeEntity]) async {
        let imageContainers = await videoPlaylistThumbnailLoader.loadThumbnails(for: videos)
        
        headerPreviewEntity = videoPlaylistEntity.toVideoPlaylistCellPreviewEntity(
            thumbnailContainers: imageContainers.compactMap { $0 },
            videosCount: videos.count,
            durationText: durationText(from: videos)
        )
        
        secondaryInformationViewType = videos.count == 0 ? .emptyPlaylist : .information
    }
    
    private func durationText(from videos: [NodeEntity]) -> String {
        let playlistDuration = videos
            .map(\.duration)
            .reduce(0, +)
        
        return VideoDurationFormatter.formatDuration(seconds: UInt(max(playlistDuration, 0)))
    }
    
    // Later when handling delete video playlist, we will handle this in detail wether it should pop screen or show error depending on error case.
    @MainActor
    private func handle(_ error: any Error) {
        guard let videoPlaylistError = error as? VideoPlaylistErrorEntity else {
            shouldShowError = true
            return
        }
        
        switch videoPlaylistError {
        case .videoPlaylistNotFound:
            shouldPopScreen = true
        default:
            shouldShowError = true
        }
    }
    
    private func doesSupport(_ sortOrder: SortOrderEntity) -> Bool {
         [.defaultAsc, .defaultDesc, .modificationAsc, .modificationDesc].contains(sortOrder)
     }
}
