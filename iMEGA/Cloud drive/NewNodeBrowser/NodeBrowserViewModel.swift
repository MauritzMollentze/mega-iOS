import Combine
import Foundation
import MEGADomain
import MEGAL10n
import Search

class NodeBrowserViewModel: ObservableObject {

    // retain for example context menu objects that need to leave as long as this view model
    var actionHandlers: [Any] = []

    // View is in edit mode once user starts selecting nodes
    // Otherwise, view will be in regular mode, with Bool value indicating whether the back button
    // should be displayed or not
    enum ViewState {
        case editing
        case regular(showBackButton: Bool)
    }

    let searchResultsViewModel: SearchResultsViewModel
    let mediaDiscoveryViewModel: MediaDiscoveryContentViewModel? // not available for recent buckets yet
    let warningViewModel: WarningViewModel?
    var mediaContentDelegate: MediaContentDelegate?
    let upgradeEncouragementViewModel: UpgradeEncouragementViewModel?
    let config: NodeBrowserConfig
    var hasOnlyMediaNodesChecker: () async -> Bool

    @Published var shouldShowMediaDiscoveryAutomatically: Bool?
    @Published var viewMode: ViewModePreferenceEntity = .list
    @Published var selected: Set<ResultId> = []
    @Published var editing = false
    @Published var title = ""
    @Published var viewState: ViewState = .regular(showBackButton: false)
    var isSelectionHidden = false
    private var subscriptions = Set<AnyCancellable>()

    let avatarViewModel: MyAvatarViewModel

    private let nodeSource: NodeSource
    private let titleBuilder: (_ isEditing: Bool, _ selectedNodeCount: Int) -> String
    private let onOpenUserProfile: () -> Void
    private let onUpdateSearchBarVisibility: (Bool) -> Void
    private let onBack: () -> Void

    init(
        searchResultsViewModel: SearchResultsViewModel,
        mediaDiscoveryViewModel: MediaDiscoveryContentViewModel?,
        warningViewModel: WarningViewModel?,
        upgradeEncouragementViewModel: UpgradeEncouragementViewModel?,
        config: NodeBrowserConfig,
        nodeSource: NodeSource,
        avatarViewModel: MyAvatarViewModel,
        // this is needed to check if given folder contains only visual media
        // so that we can automatically show media browser
        hasOnlyMediaNodesChecker: @escaping () async -> Bool,
        titleBuilder: @escaping (Bool, Int) -> String,
        onOpenUserProfile: @escaping () -> Void,
        onUpdateSearchBarVisibility: @escaping (Bool) -> Void,
        onBack: @escaping () -> Void
    ) {
        self.searchResultsViewModel = searchResultsViewModel
        
        self.mediaDiscoveryViewModel = mediaDiscoveryViewModel
        self.warningViewModel = warningViewModel
        self.upgradeEncouragementViewModel = upgradeEncouragementViewModel
        self.config = config
        self.nodeSource = nodeSource
        self.avatarViewModel = avatarViewModel
        self.titleBuilder = titleBuilder
        self.onOpenUserProfile = onOpenUserProfile
        self.hasOnlyMediaNodesChecker = hasOnlyMediaNodesChecker
        self.onUpdateSearchBarVisibility = onUpdateSearchBarVisibility
        self.onBack = onBack

        $viewMode
            .removeDuplicates()
            .sink { viewMode in
                if viewMode == .list {
                    searchResultsViewModel.layout = .list
                }
                if viewMode == .thumbnail {
                    searchResultsViewModel.layout = .thumbnail
                }

                onUpdateSearchBarVisibility(!self.isMediaDiscoveryShown(for: viewMode))
            }.store(in: &subscriptions)
        
        $editing
            .removeDuplicates()
            .sink { [weak self] editing in
                searchResultsViewModel.editing = editing
                mediaDiscoveryViewModel?.editMode = editing ? .active : .inactive
                if !editing {
                    self?.selected.removeAll()
                    // set here to go back from select mode of title to default title
                }
                self?.refreshTitle(isEditing: editing)
            }
            .store(in: &subscriptions)
        
        mediaContentDelegate?.isMediaDiscoverySelectionHandler = { [weak self] isSelectionHidden in
            self?.isSelectionHidden = isSelectionHidden
        }

        searchResultsViewModel.bridge.selectionChanged = { [weak self] selected in
            guard let self else { return }
            self.selected = selected
            self.refreshTitle()
        }

        searchResultsViewModel.bridge.editingChanged = { [weak self] editing in
            guard let self else { return }
            self.editing = editing
            self.refresh()
        }

        refresh()
    }
    
    @MainActor
    func viewTask() async {
        await determineIfHasVisualMediaIfNeeded()
        determineIfShowingAutomaticallyMediaDiscovery()
        onUpdateSearchBarVisibility(!isMediaDiscoveryShown(for: viewMode))
        encourageUpgradeIfNeeded()
    }
    
    private func determineIfShowingAutomaticallyMediaDiscovery() {
        mediaDiscoveryViewModel?
            .showAutoMediaDiscoveryBanner = shouldShowMediaDiscoveryAutomatically == true
    }
    
    @MainActor
    private func determineIfHasVisualMediaIfNeeded() async {
        guard config.mediaDiscoveryAutomaticDetectionEnabled() else {
            return
        }
        
        if shouldShowMediaDiscoveryAutomatically != nil {
            return
        }
        // first time we load view, we need to get
        // all nodes list to see if there are any media
        // in case we need to automatically show media discovery view
        shouldShowMediaDiscoveryAutomatically = await hasOnlyMediaNodesChecker()
    }

    private func isMediaDiscoveryShown(for viewMode: ViewModePreferenceEntity) -> Bool {
        shouldShowMediaDiscoveryAutomatically == true || viewMode == .mediaDiscovery
    }
    
    private func encourageUpgradeIfNeeded() {
        upgradeEncouragementViewModel?.encourageUpgradeIfNeeded()
    }

    private func refresh() {
        refreshViewState()
        refreshTitle()
    }

    private func refreshViewState() {
        viewState = editing ? .editing : .regular(showBackButton: isBackButtonShown)
    }

    // this is also triggered from outside when node folder is renamed
    func refreshTitle() {
        refreshTitle(isEditing: editing)
    }
    
    private func refreshTitle(isEditing: Bool) {
        title = titleBuilder(isEditing, selected.count)
    }

    // here we check the value of the automatic flag and also the actual variable that holds the state
    // which can be changed via the context menu
    var isMediaDiscoveryShown: Bool {
        isMediaDiscoveryShown(for: viewMode)
    }

    private var isBackButtonShown: Bool {
       guard let parentNode else { return false }
       return parentNode.nodeType != .root
    }

    private var parentNode: NodeEntity? {
        switch nodeSource {
        case .node(let parentNodeProvider):
            guard let parentNodeProvider = parentNodeProvider() else { return nil }
            return parentNodeProvider
        default:
            return nil
        }
    }

    func openUserProfile() {
        onOpenUserProfile()
    }

    func back() {
        onBack()
    }
    
    func toggleSelection() {
        editing.toggle()
    }
    
    func changeViewMode(_ viewMode: ViewModePreferenceEntity) {
        self.viewMode = viewMode
    }
    
    func selectAll() {
        // Connect select all action as a part of FM-1464
    }

    func stopEditing() {
        editing = false
        refresh()
        searchResultsViewModel.bridge.editingCancelled()
    }
}