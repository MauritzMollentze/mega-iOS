import ContentLibraries
import Foundation
import MEGAAppSDKRepo
import MEGADomain
import MEGARepo

extension AppDelegate {
    @objc func initializeCameraUploadsNode() {
        CameraUploadNodeAccess.shared.loadNode()
    }
    
    @objc func postNodeUpdatesNotifications(for nodeList: MEGANodeList) {
        let nodes = nodeList.toNodeArray()
        postFavouriteUpdatesNotification(for: nodes)
    }
    
    @objc func removeCachedFilesIfNeeded(for nodeList: MEGANodeList) {
        let removedNodes = nodeList.toNodeEntities().filter { $0.isRemoved }
        if removedNodes.isNotEmpty {
            let nodesRemovedUseCase = NodesRemovedUseCase(
                thumbnailRepository: ThumbnailRepository.newRepo,
                fileRepository: FileSystemRepository.sharedRepo,
                removedNodes: removedNodes
            )
            Task {
                await nodesRemovedUseCase.removeCachedFiles()
            }
        }
    }
    
    @objc func enableRequestStatusMonitor() {
        let useCase = RequestStatusMonitorUseCase(repo: RequestStatusMonitorRepository.newRepo)
        useCase.enableRequestStatusMonitor(true)
    }
    
    private func postFavouriteUpdatesNotification(for nodes: [MEGANode]) {
        let updatedNodes = nodes.modifiedFavourites().toNodeEntities()
        if !updatedNodes.isEmpty {
            NotificationCenter.default.post(name: .didPhotoFavouritesChange, object: updatedNodes)
        }
    }
}
