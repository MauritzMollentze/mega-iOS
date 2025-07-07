import MEGAAppSDKRepo
import MEGADomain

extension MEGANode {
    @MainActor
    @objc func pushCloudDriveForNode(_ node: MEGANode, displayMode: DisplayMode, navigationController: UINavigationController) {
        let factory = CloudDriveViewControllerFactory.make(
            nc: navigationController
        )
        let vc = factory.buildBare(
            parentNode: node.toNodeEntity(),
            config: .init(
                displayMode: displayMode
            )
        )
        guard let vc else { return }
        navigationController.pushViewController(vc, animated: false)
    }

    @MainActor
    @objc func navigateToParentAndPresentForNavigationRevamp() {
        guard let mainTBC = UIApplication.mainTabBarRootViewController() as? MainTabBarController,
        let navigationController = mainTBC.selectedViewController as? UINavigationController else {
            return
        }

        if MEGASdk.shared.accessLevel(for: self) != .accessOwner {
            navigateToSharedItems(in: mainTBC)
        } else {
            mainTBC.selectedIndex = TabManager.driveTabIndex()
            navigationController.popToRootViewController(animated: false)
        }

        let parentTreeArray = mnz_parentTreeArray() as? [MEGANode] ?? []
        var backupsRootNode: MEGANode? = BackupRootNodeAccess.shared.isTargetNode(for: self) ? self : nil

        if backupsRootNode == nil {
            for node in parentTreeArray where BackupRootNodeAccess.shared.isTargetNode(for: node) {
                backupsRootNode = node
                break
            }
        }

        let isBackupNode = backupsRootNode != nil

        for node in parentTreeArray where node.handle != backupsRootNode?.parentHandle {
            pushCloudDriveForNode(
                node,
                displayMode: isBackupNode ? .backup : .cloudDrive,
                navigationController: navigationController
            )
        }

        // Only `.folder` is properly handled in Navigation Revamp, the rest are to be addressed and thoroughly tested in [IOS-10134]
        switch type {
        case .folder, .rubbish:
            let displayMode: DisplayMode
            if isBackupNode {
                displayMode = .backup
            } else {
                displayMode = type == .rubbish ? .rubbishBin : .cloudDrive
            }
            pushCloudDriveForNode(self, displayMode: displayMode, navigationController: navigationController)
            UIApplication.mnz_presentingViewController().dismiss(animated: true)

        case .file:
            if FileExtensionGroupOCWrapper.verify(isVisualMedia: name) {
                guard let parentNode = MEGASdk.shared.node(forHandle: parentHandle) else { return }
                let nodeList = MEGASdk.shared.children(forParent: parentNode)
                let mediaNodesArray = nodeList.mnz_mediaNodesMutableArrayFromNodeList()

                let displayMode: DisplayMode = {
                    if isBackupNode {
                        return .backup
                    } else if MEGASdk.shared.accessLevel(for: self) == .accessOwner {
                        return .cloudDrive
                    } else {
                        return .sharedItem
                    }
                }()

                let photoBrowserVC = MEGAPhotoBrowserViewController.photoBrowser(
                    withMediaNodes: NSMutableArray(array: mediaNodesArray ?? []),
                    api: MEGASdk.shared,
                    displayMode: displayMode,
                    isFromSharedItem: false,
                    presenting: self
                )

                navigationController.present(photoBrowserVC, animated: true)
            } else {
                mnz_open(in: navigationController,
                              folderLink: false,
                              fileLink: nil,
                              messageId: nil,
                              chatId: nil,
                              isFromSharedItem: false,
                              allNodes: nil)
            }

        default:
            UIApplication.mnz_presentingViewController().dismiss(animated: true)
        }
    }

    @MainActor
    private func navigateToSharedItems(in mainTBC: MainTabBarController) {
        mainTBC.selectedIndex = TabManager.menuTabIndex()
        guard let presenter = mainTBC.selectedViewController as? (any SharedItemsPresenting) else {
            return assertionFailure("Trying to navigate to SharedItems screen but selected view controller is not of type SharedItemsPresenting")
        }
        presenter.showSharedItems()
    }
}
