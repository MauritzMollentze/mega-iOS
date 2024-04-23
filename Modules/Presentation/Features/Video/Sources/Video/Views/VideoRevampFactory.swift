import Combine
import MEGADomain
import SwiftUI

public final class VideoRevampSyncModel: ObservableObject {
    @Published public var videoRevampSortOrderType: SortOrderEntity?
    @Published public var videoRevampVideoPlaylistsSortOrderType: SortOrderEntity = .modificationAsc
    @Published public var editMode: EditMode = .inactive {
        didSet {
            showsTabView = editMode.isEditing ? false : true
        }
    }
    @Published public var isAllSelected = false
    @Published public var searchText = ""
    @Published public private(set) var showsTabView = false
    @Published public var currentTab: VideosTab = .all
    @Published public var shouldShowAddNewPlaylistAlert = false
    
    private var subscriptions = Set<AnyCancellable>()
    
    public init() {
        _editMode.projectedValue
            .map(\.isEditing)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isEditing in
                self?.showsTabView = isEditing ? false : true
            }
            .store(in: &subscriptions)
    }
}

public class VideoRevampFactory {
    public static func makeTabContainerView(
        fileSearchUseCase: some FilesSearchUseCaseProtocol,
        thumbnailUseCase: some ThumbnailUseCaseProtocol,
        syncModel: VideoRevampSyncModel,
        videoSelection: VideoSelection,
        videoConfig: VideoConfig,
        router: some VideoRevampRouting
    ) -> UIViewController {
        let videoListViewModel = VideoListViewModel(
            fileSearchUseCase: fileSearchUseCase,
            thumbnailUseCase: thumbnailUseCase,
            syncModel: syncModel,
            selection: videoSelection
        )
        let videoPlaylistViewModel = VideoPlaylistsViewModel(
            syncModel: syncModel
        )
        let view = TabContainerView(
            videoListViewModel: videoListViewModel,
            videoPlaylistViewModel: videoPlaylistViewModel,
            videoConfig: videoConfig,
            router: router,
            didChangeCurrentTab: { syncModel.currentTab = $0 }
        )
        return UIHostingController(rootView: view)
    }
    
    public static func makeToolbarView(viewModel: VideoToolbarViewModel, videoConfig: VideoConfig) -> UIViewController {
        let controller = UIHostingController(rootView: VideoToolbar(videoConfig: videoConfig, viewModel: viewModel))
        controller.view.backgroundColor = .clear
        return controller
    }
}
