import MEGADomain
import MEGAL10n
import UIKit

class BaseAction: NSObject {
    var title: String?
    var detail: String?
    var accessoryView: UIView?
    var image: UIImage?
    var style: UIAlertAction.Style = .default
    
    override var hash: Int {
        var hasher = Hasher()
        hasher.combine(title?.hash)
        hasher.combine(detail?.hash)
        hasher.combine(accessoryView?.hash)
        hasher.combine(image?.hash)
        hasher.combine(style.hashValue)
        return hasher.finalize()
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let otherObject = object as? BaseAction else { return false }
        return title == otherObject.title
            && detail == otherObject.detail
            && accessoryView == otherObject.accessoryView
            && image == otherObject.image
            && style == otherObject.style
    }
}

class ActionSheetAction: BaseAction {
    var actionHandler: () -> Void

    @objc init(title: String?, detail: String?, image: UIImage?, style: UIAlertAction.Style, actionHandler: @escaping () -> Void) {
        self.actionHandler = actionHandler
        super.init()
        self.title = title
        self.detail = detail
        self.image = image
        self.style = style
    }
    
    @objc init(title: String?, detail: String?, accessoryView: UIView?, image: UIImage?, style: UIAlertAction.Style, actionHandler: @escaping () -> Void) {
        self.actionHandler = actionHandler
        super.init()
        self.title = title
        self.detail = detail
        self.accessoryView = accessoryView
        self.image = image
        self.style = style
    }
}

class ActionSheetSwitchAction: ActionSheetAction {
    var switchView: UISwitch?
    
    @objc init(title: String?, detail: String?, switchView: UISwitch, image: UIImage?, style: UIAlertAction.Style, actionHandler: @escaping () -> Void) {
        super.init(title: title, detail: detail, image: image, style: style, actionHandler: actionHandler)
        self.switchView = switchView
    }
    
    @objc func change(state: Bool) {
        switchView?.isOn = state
    }
    
    @objc func switchStatus() -> Bool {
        switchView?.isOn ?? false
    }
}

class NodeAction: BaseAction {
    var type: MegaNodeActionType

    private init(title: String?, detail: String?, image: UIImage?, type: MegaNodeActionType) {
        self.type = type
        super.init()
        self.title = title
        self.detail = detail
        self.image = image
    }
    
    private init(title: String?, detail: String?, accessoryView: UIView?, image: UIImage?, type: MegaNodeActionType) {
        self.type = type
        super.init()
        self.title = title
        self.detail = detail
        self.accessoryView = accessoryView
        self.image = image
    }
}

final class ContextActionSheetAction: BaseAction {
    let identifier: String?
    let type: CMElementTypeEntity?
    var actionHandler: (ContextActionSheetAction) -> Void
    
    init(title: String?, detail: String?, image: UIImage?, identifier: String?, type: CMElementTypeEntity?, actionHandler: @escaping (ContextActionSheetAction) -> Void) {
        self.identifier = identifier
        self.type = type
        self.actionHandler = actionHandler
        super.init()
        self.title = title
        self.detail = detail
        self.image = image
    }
}

// MARK: - Node Actions Factory

extension NodeAction {
    class func exportFileAction(nodeCount: Int = 1) -> NodeAction {
        NodeAction(title: Strings.Localizable.General.MenuAction.ExportFile.title(nodeCount), detail: nil, image: UIImage.export, type: .exportFile)
    }
    
    class func shareFolderAction(nodeCount: Int = 1) -> NodeAction {
        NodeAction(title: Strings.Localizable.General.MenuAction.ShareFolder.title(nodeCount), detail: nil, image: UIImage.shareFolder, type: .shareFolder)
    }
    
    class func verifyContactAction(receiverDetail: String) -> NodeAction {
        NodeAction(title: Strings.Localizable.General.MenuAction.VerifyContact.title(receiverDetail), detail: nil, image: UIImage.verifyContact, type: .verifyContact)
    }
    
    class func manageFolderAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.manageShare, detail: nil, image: UIImage.shareFolder, type: .manageShare)
    }
    
    class func downloadAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.General.downloadToOffline, detail: nil, image: UIImage.offline, type: .download)
    }
    
    class func infoAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.info, detail: nil, image: UIImage.info, type: .info)
    }
    
    class func renameAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.rename, detail: nil, image: UIImage.rename, type: .rename)
    }
    
    class func copyAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.copy, detail: nil, image: UIImage.copy, type: .copy)
    }
    
    class func moveAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.move, detail: nil, image: UIImage.move, type: .move)
    }
    
    class func moveToRubbishBinAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.General.MenuAction.moveToRubbishBin, detail: nil, image: UIImage.rubbishBin, type: .moveToRubbishBin)
    }
    
    class func removeAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.General.MenuAction.deletePermanently, detail: nil, image: UIImage.rubbishBin, type: .remove)
    }
    
    class func leaveSharingAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.leaveFolder, detail: nil, image: UIImage.leaveShare, type: .leaveSharing)
    }
    
    class func shareLinkAction(nodeCount: Int = 1) -> NodeAction {
        NodeAction(title: Strings.Localizable.General.MenuAction.ShareLink.title(nodeCount), detail: nil, image: UIImage.link, type: .shareLink)
    }
    
    class func retryAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.retry, detail: nil, image: Asset.Images.Generic.link.image, type: .retry)
    }
    
    class func manageLinkAction(nodeCount: Int = 1) -> NodeAction {
        NodeAction(title: Strings.Localizable.General.MenuAction.ManageLink.title(nodeCount), detail: nil, image: UIImage.link, type: .manageLink)
    }
    
    class func removeLinkAction(nodeCount: Int = 1) -> NodeAction {
        NodeAction(title: Strings.Localizable.General.MenuAction.RemoveLink.title(nodeCount), detail: nil, image: UIImage.removeLink, type: .removeLink)
    }
    
    class func removeSharingAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.removeSharing, detail: nil, image: UIImage.removeShare, type: .removeSharing)
    }
    
    class func viewInFolderAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.viewInFolder, detail: nil, image: UIImage.search, type: .viewInFolder)
    }
    
    class func clearAction() -> NodeAction {
        let action = NodeAction(title: Strings.Localizable.clear, detail: nil, image: UIImage.cancelTransfers, type: .clear)
        action.style = .destructive
        return action
    }
    
    class func importAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.importToCloudDrive, detail: nil, image: UIImage.import, type: .import)
    }
    
    class func viewVersionsAction(versionCount: Int) -> NodeAction {
        NodeAction(title: Strings.Localizable.versions, detail: String(versionCount), image: UIImage.versions, type: .viewVersions)
    }
    
    class func revertVersionAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.revert, detail: nil, image: UIImage.history, type: .revertVersion)
    }
    
    class func removeVersionAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.delete, detail: nil, image: UIImage.delete, type: .remove)
    }
    
    class func selectAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.select, detail: nil, image: UIImage(named: "select"), type: .select)
    }
    
    class func restoreAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.restore, detail: nil, image: UIImage.restore, type: .restore)
    }
    
    class func saveToPhotosAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.saveToPhotos, detail: nil, image: UIImage.saveToPhotos, type: .saveToPhotos)
    }
    
    class func sendToChatAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.General.sendToChat, detail: nil, image: UIImage.sendToChat, type: .sendToChat)
    }
    
    class func pdfPageViewAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.pageView, detail: nil, image: UIImage.pageView, type: .pdfPageView)
    }
    
    class func pdfThumbnailViewAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.thumbnailView, detail: nil, image: UIImage(named: "thumbnailsThin"), type: .pdfThumbnailView)
    }
    
    class func textEditorAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.edit, detail: nil, image: UIImage.edittext, type: .editTextFile)
    }
    
    class func forwardAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.forward, detail: nil, image: UIImage.forwardToolbar, type: .forward)
    }
    
    class func searchAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.search, detail: nil, image: UIImage.search, type: .search)
    }
    
    class func favouriteAction(isFavourite: Bool) -> NodeAction {
        NodeAction(title: isFavourite ? Strings.Localizable.removeFavourite : Strings.Localizable.favourite, detail: nil, image: isFavourite ? UIImage.removeFavourite : UIImage.favourite, type: .favourite)
    }
    
    class func labelAction(label: MEGANodeLabel) -> NodeAction {
        let labelString = MEGANode.string(for: label)
        let detailText = Strings.localized(labelString!, comment: "")
        let image = UIImage(named: labelString!)
        
        return NodeAction(title: Strings.Localizable.CloudDrive.Sort.label, detail: (label != .unknown ? detailText : nil), accessoryView: (label != .unknown ? UIImageView(image: image) : UIImageView(image: UIImage.standardDisclosureIndicator)), image: UIImage.label, type: .label)
    }
    
    class func listAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.listView, detail: nil, image: UIImage(named: "gridThin"), type: .list)
    }
    
    class func thumbnailAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.thumbnailView, detail: nil, image: UIImage(named: "thumbnailsThin"), type: .thumbnail)
    }
    
    class func sortAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.sortTitle, detail: nil, image: UIImage(named: "sort"), type: .sort)
    }
    
    class func disputeTakedownAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.disputeTakedown, detail: nil, image: UIImage.disputeTakedown, type: .disputeTakedown)
    }
    
    class func restoreBackupAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.restore, detail: nil, image: UIImage.restore, type: .restoreBackup)
    }
    
    class func mediaDiscoveryAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.CloudDrive.Menu.MediaDiscovery.title, detail: nil,
                   image: UIImage.mediaDiscovery, type: .mediaDiscovery)
    }
}
