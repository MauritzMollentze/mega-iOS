import MEGAL10n
import Search
import MEGASwiftUI
import SwiftUI

struct NodeBrowserView: View {
    
    @StateObject var viewModel: NodeBrowserViewModel

    var body: some View {
        content
            .toolbar {
                ToolbarItemGroup(placement: .topBarLeading) {
                    leftToolbarContent
                }
                
                toolbarNavigationTitle
                
                ToolbarItemGroup(placement: .topBarTrailing) {
                    rightToolbarContent
                }
            }.navigationBarBackButtonHidden(viewModel.hidesBackButton)
    }
    
    private var content: some View {
        VStack {
            if let warningViewModel = viewModel.warningViewModel {
                WarningView(viewModel: warningViewModel)
            }
            if let mediaDiscoveryViewModel = viewModel.viewModeAwareMediaDiscoveryViewModel {
                MediaDiscoveryContentView(viewModel: mediaDiscoveryViewModel)
            } else {
                SearchResultsView(viewModel: viewModel.searchResultsViewModel)
            }
        }
        .designTokenBackground(true)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.onViewAppear() }
        .onLoad { viewModel.onLoadTask() }
    }

    @ToolbarContentBuilder
    private var toolbarContentEditing: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button(
                action: { viewModel.selectAll() },
                label: { Image(.selectAllItems) }
            )
        }

        ToolbarItem(placement: .topBarTrailing) {
            Button(Strings.Localizable.cancel) { viewModel.stopEditing() }
        }

        ToolbarItem(placement: .principal) {
            Text(viewModel.title).font(.headline)
        }
    }

    // Note: Here we temporarily disabled this block of code because we cannot use them due to iOS15 API shortcomings for using if-else inside `.toolbar { }`.
    // When we finall drop iOS15, we can uncomment these code and use them again
//    @ToolbarContentBuilder
//    private var toolbarContent: some ToolbarContent {
//        toolbarNavigationTitle
//        toolbarTrailingNonEditingContent
//    }
//
//    @ToolbarContentBuilder
//    private var toolbarContentWithLeadingAvatar: some ToolbarContent {
//        toolbarLeadingAvatarImage
//        toolbarNavigationTitle
//        toolbarTrailingNonEditingContent
//    }
//    @ToolbarContentBuilder
//    private var toolbarLeadingAvatarImage: some ToolbarContent {
//        ToolbarItem(placement: .topBarLeading) {
//            MyAvatarIconView(
//                viewModel: .init(
//                    avatarObserver: viewModel.avatarViewModel,
//                    onAvatarTapped: { viewModel.openUserProfile() }
//                )
//            )
//        }
//    }
//    @ToolbarContentBuilder
//    private var toolbarTrailingNonEditingContent: some ToolbarContent {
//        ToolbarItemGroup(placement: .topBarTrailing) {
//            viewModel.contextMenuViewFactory?.makeAddMenuWithButtonView()
//            viewModel.contextMenuViewFactory?.makeContextMenuWithButtonView()
//        }
//    }
    
    @ViewBuilder
    private var leftToolbarContent: some View {
        switch viewModel.viewState {
        case .editing:
            Button(
                action: { viewModel.selectAll() },
                label: { Image(.selectAllItems) }
            )
        case .regular(let isBackButtonShown):
            if isBackButtonShown {
                EmptyView()
            } else {
                MyAvatarIconView(
                    viewModel: .init(
                        avatarObserver: viewModel.avatarViewModel,
                        onAvatarTapped: { viewModel.openUserProfile() }
                    )
                )
            }
        }
    }
    
    @ViewBuilder
    private var rightToolbarContent: some View {
        switch viewModel.viewState {
        case .editing:
            Button(Strings.Localizable.cancel) { viewModel.stopEditing() }
        case .regular:
            viewModel.contextMenuViewFactory?.makeAddMenuWithButtonView()
            viewModel.contextMenuViewFactory?.makeContextMenuWithButtonView()
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarNavigationTitle: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text(viewModel.title)
                .font(.headline)
                .lineLimit(1)
        }
    }
}
