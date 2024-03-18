import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGASDKRepo
import MEGASwift
import SwiftUI
import UIKit

extension PhotosViewController {
    private func contextMenuConfiguration() -> CMConfigEntity? {
        return CMConfigEntity(
            menuType: .menu(type: .timeline),
            sortType: viewModel.cameraUploadExplorerSortOrderType.megaSortOrderType.toSortOrderEntity(),
            isCameraUploadExplorer: true,
            isFilterEnabled: true,
            isSelectHidden: viewModel.isSelectHidden,
            isEmptyState: viewModel.mediaNodes.isEmpty,
            isFilterActive: viewModel.isFilterActive
        )
    }
    
    @objc func configureContextMenuManager() {
        contextMenuManager = ContextMenuManager(
            displayMenuDelegate: self,
            createContextMenuUseCase: CreateContextMenuUseCase(repo: CreateContextMenuRepository.newRepo)
        )
    }
    
    @objc func makeFilterActiveBarButton() -> UIBarButtonItem {
        UIBarButtonItem(image: UIImage(resource: .filterActive).withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(onFilter))
    }
    
    @objc func makeContextMenuBarButton() -> UIBarButtonItem? {
        guard let config = contextMenuConfiguration(), let menu = contextMenuManager?.contextMenu(with: config) else { return nil }
        
        let button = UIBarButtonItem(
            image: UIImage(resource: viewModel.isFilterActive ? .moreActionActiveNavigationBar : .moreNavigationBar),
            menu: menu)
        
        if UIColor.isDesignTokenEnabled() {
            button.tintColor = TokenColors.Icon.primary
        }
        
        return button
    }
    
    @objc func setupNavigationBarButtons() {
        setupLeftNavigationBarButtons()
        setupRightNavigationBarButtons()
    }
    
    func setupLeftNavigationBarButtons() {
        if isEditing {
            self.objcWrapper_parent.navigationItem.setLeftBarButton(selectAllBarButtonItem, animated: false)
        } else {
            self.objcWrapper_parent.navigationItem.setLeftBarButton(self.myAvatarManager?.myAvatarBarButton, animated: false)
        }
    }
    
    @objc func setupRightNavigationBarButtons() {
        if isEditing {
            self.objcWrapper_parent.navigationItem.setRightBarButtonItems([cancelBarButtonItem], animated: true)
        } else {
            var rightButtons = [UIBarButtonItem]()
            if let barButton = makeContextMenuBarButton() {
                rightButtons.append(barButton)
            }
            if let cameraUploadStatusBarButtonItem {
                rightButtons.append(cameraUploadStatusBarButtonItem)
            }
            if objcWrapper_parent.navigationItem.rightBarButtonItems !~ rightButtons {
                objcWrapper_parent.navigationItem.setRightBarButtonItems(rightButtons, animated: true)
            }
        }
    }
    
    @objc func makeCancelBarButton() -> UIBarButtonItem {
        UIBarButtonItem(title: Strings.Localizable.cancel, style: .done, target: self, action: #selector(toggleEditing))
    }
    
    @objc func makeEditBarButton() -> UIBarButtonItem {
        UIBarButtonItem(image: UIImage(resource: .selectAllItems), style: .plain, target: self, action: #selector(toggleEditing))
    }
    
    @objc func makeCameraUploadStatusBarButton() -> UIBarButtonItem {
        let statusButtonView = CameraUploadStatusButtonView(viewModel: viewModel.cameraUploadStatusButtonViewModel)
        let cameraStatusViewController = UIHostingController(rootView: statusButtonView)
        cameraStatusViewController.view.backgroundColor = .clear
        return UIBarButtonItem(customView: cameraStatusViewController.view)
    }
    
    @objc func toggleEditing() {
        setEditing(!isEditing, animated: true)
        setupNavigationBarButtons()
    }
    
    @objc private func onFilter() {
        photoLibraryContentViewModel.showFilter.toggle()
    }
}

// MARK: - DisplayMenuDelegate
extension PhotosViewController: DisplayMenuDelegate {
    func displayMenu(didSelect action: DisplayActionEntity, needToRefreshMenu: Bool) {
        if action == .select {
            toggleEditing()
        } else if action == .filter || action == .filterActive {
            onFilter()
        }
    }
    
    func sortMenu(didSelect sortType: SortOrderType) {
        viewModel.update(sortOrderType: sortType)
        setupNavigationBarButtons()
    }
}
