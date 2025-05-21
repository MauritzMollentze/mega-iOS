import Combine
import ContentLibraries
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGAAssets
import MEGADomain
import MEGAL10n
import MEGASwiftUI
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
    @Published public var isSearchActive = false
    
    @Published public var shouldShowSnackBar = false
    public var snackBarMessage = ""
    
    private var subscriptions = Set<AnyCancellable>()
    
    public init() {
        $editMode.combineLatest($isSearchActive)
            .map { editMode, isSearchActive in !(editMode.isEditing || isSearchActive) }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .assign(to: &$showsTabView)
    }
}

@MainActor
public class VideoRevampFactory {
    public static func makeTabContainerView(
        fileSearchUseCase: some FilesSearchUseCaseProtocol,
        photoLibraryUseCase: some PhotoLibraryUseCaseProtocol,
        syncModel: VideoRevampSyncModel,
        videoSelection: VideoSelection,
        videoPlaylistUseCase: some VideoPlaylistUseCaseProtocol,
        videoPlaylistContentUseCase: some VideoPlaylistContentsUseCaseProtocol,
        videoPlaylistModificationUseCase: some VideoPlaylistModificationUseCaseProtocol,
        sortOrderPreferenceUseCase: some SortOrderPreferenceUseCaseProtocol,
        nodeIconUseCase: some NodeIconUsecaseProtocol,
        nodeUseCase: some NodeUseCaseProtocol,
        sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol,
        accountStorageUseCase: some AccountStorageUseCaseProtocol,
        videoConfig: VideoConfig,
        router: some VideoRevampRouting,
        featureFlagProvider: any FeatureFlagProviderProtocol
    ) -> UIViewController {
        
        let thumbnailLoader = makeThumbnailLoader(
            sensitiveNodeUseCase: sensitiveNodeUseCase,
            nodeIconUseCase: nodeIconUseCase)
        let videoListViewModel = VideoListViewModel(
            syncModel: syncModel, 
            contentProvider: VideoListViewModelContentProvider(photoLibraryUseCase: photoLibraryUseCase),
            selection: videoSelection,
            fileSearchUseCase: fileSearchUseCase,
            thumbnailLoader: thumbnailLoader,
            sensitiveNodeUseCase: sensitiveNodeUseCase,
            nodeUseCase: nodeUseCase,
            featureFlagProvider: featureFlagProvider
        )
        let videoPlaylistViewModel = VideoPlaylistsViewModel(
            videoPlaylistsUseCase: videoPlaylistUseCase,
            videoPlaylistContentUseCase: videoPlaylistContentUseCase,
            videoPlaylistModificationUseCase: videoPlaylistModificationUseCase, 
            sortOrderPreferenceUseCase: sortOrderPreferenceUseCase,
            accountStorageUseCase: accountStorageUseCase,
            syncModel: syncModel,
            alertViewModel: TextFieldAlertViewModel(
                title: Strings.Localizable.Videos.Tab.Playlist.Content.Alert.title,
                placeholderText: Strings.Localizable.Videos.Tab.Playlist.Content.Alert.placeholder,
                affirmativeButtonTitle: Strings.Localizable.Videos.Tab.Playlist.Content.Alert.Button.create,
                destructiveButtonTitle: Strings.Localizable.cancel,
                message: nil
            ),
            renameVideoPlaylistAlertViewModel: TextFieldAlertViewModel(
                title: Strings.Localizable.Videos.Tab.Playlist.Content.Alert.Title.rename,
                placeholderText: Strings.Localizable.Videos.Tab.Playlist.Content.Alert.placeholder,
                affirmativeButtonTitle: Strings.Localizable.Videos.Tab.Playlist.Content.Alert.Button.rename,
                affirmativeButtonInitiallyEnabled: false,
                destructiveButtonTitle: Strings.Localizable.cancel,
                message: Strings.Localizable.Videos.Tab.Playlist.Content.Alert.Subtitle.enterTheNewName
            ),
            thumbnailLoader: thumbnailLoader,
            featureFlagProvider: featureFlagProvider,
            contentProvider: VideoPlaylistsViewModelContentProvider(
                videoPlaylistsUseCase: videoPlaylistUseCase
            ),
            videoRevampRouter: router
        )
        let view = TabContainerView(
            videoListViewModel: videoListViewModel,
            videoPlaylistViewModel: videoPlaylistViewModel,
            syncModel: syncModel,
            videoConfig: videoConfig,
            router: router,
            didChangeCurrentTab: { syncModel.currentTab = $0 }
        )
        return UIHostingController(rootView: view)
    }
    
    @MainActor
    public static func makeVideoContentContainerView(
        videoConfig: VideoConfig,
        previewEntity: VideoPlaylistEntity,
        videoPlaylistContentUseCase: some VideoPlaylistContentsUseCaseProtocol,
        sortOrderPreferenceUseCase: some SortOrderPreferenceUseCaseProtocol,
        videoPlaylistUseCase: some VideoPlaylistUseCaseProtocol,
        videoPlaylistModificationUseCase: some VideoPlaylistModificationUseCaseProtocol,
        nodeIconUseCase: some NodeIconUsecaseProtocol,
        nodeUseCase: some NodeUseCaseProtocol,
        featureFlagProvider: some FeatureFlagProviderProtocol,
        sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol,
        accountStorageUseCase: some AccountStorageUseCaseProtocol,
        router: some VideoRevampRouting,
        sharedUIState: VideoPlaylistContentSharedUIState,
        videoSelection: VideoSelection,
        selectionAdapter: VideoPlaylistContentViewModelSelectionAdapter,
        presentationConfig: VideoPlaylistContentSnackBarPresentationConfig,
        syncModel: VideoRevampSyncModel
    ) -> UIViewController {
        let thumbnailLoader = makeThumbnailLoader(
            sensitiveNodeUseCase: sensitiveNodeUseCase,
            nodeIconUseCase: nodeIconUseCase)
        let viewModel = VideoPlaylistContentViewModel(
            videoPlaylistEntity: previewEntity,
            videoPlaylistContentsUseCase: videoPlaylistContentUseCase,
            videoPlaylistThumbnailLoader: VideoPlaylistThumbnailLoader(
                thumbnailLoader: thumbnailLoader,
                fallbackImageContainer: ImageContainer(
                    image: MEGAAssets.Image.videoPlaylistThumbnailFallback,
                    type: .thumbnail
                )
            ),
            sharedUIState: sharedUIState,
            presentationConfig: presentationConfig,
            sortOrderPreferenceUseCase: sortOrderPreferenceUseCase,
            selectionDelegate: selectionAdapter,
            renameVideoPlaylistAlertViewModel: TextFieldAlertViewModel(
                title: Strings.Localizable.Videos.Tab.Playlist.Content.Alert.Title.rename,
                placeholderText: Strings.Localizable.Videos.Tab.Playlist.Content.Alert.placeholder,
                affirmativeButtonTitle: Strings.Localizable.Videos.Tab.Playlist.Content.Alert.Button.rename,
                affirmativeButtonInitiallyEnabled: false,
                destructiveButtonTitle: Strings.Localizable.cancel,
                message: Strings.Localizable.Videos.Tab.Playlist.Content.Alert.Subtitle.enterTheNewName
            ),
            videoPlaylistsUseCase: videoPlaylistUseCase,
            videoPlaylistModificationUseCase: videoPlaylistModificationUseCase,
            thumbnailLoader: thumbnailLoader,
            sensitiveNodeUseCase: sensitiveNodeUseCase,
            nodeUseCase: nodeUseCase,
            accountStorageUseCase: accountStorageUseCase,
            videoRevampRouter: router,
            featureFlagProvider: featureFlagProvider,
            syncModel: syncModel
        )
        
        let view = PlaylistContentScreen(
            viewModel: viewModel,
            videoConfig: videoConfig,
            videoSelection: videoSelection,
            router: router
        )
        return UIHostingController(rootView: view)
    }
}

extension VideoRevampFactory {
    public static func makeThumbnailLoader(
        sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol,
        nodeIconUseCase: some NodeIconUsecaseProtocol
    ) -> any ThumbnailLoaderProtocol {
        ThumbnailLoaderFactory.makeThumbnailLoader(
            config: .sensitiveWithFallbackIcon(
                sensitiveNodeUseCase: sensitiveNodeUseCase,
                nodeIconUseCase: nodeIconUseCase
            ),
            thumbnailUseCase: ThumbnailUseCase(
                repository: ThumbnailRepository.newRepo
            )
        )
    }
}
