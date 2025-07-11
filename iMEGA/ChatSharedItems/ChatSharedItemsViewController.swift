import ChatRepo
import MEGAAppSDKRepo
import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGAPermissions
import UIKit

class ChatSharedItemsViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    private var attachmentsLoaded = false
    private var attachmentsLoading = false

    private var chatRoom = MEGAChatRoom()
    private lazy var messagesArray = [MEGAChatMessage]()
    
    private var requestedParticipantsMutableSet = Set<UInt64>()

    private lazy var cancelBarButton: UIBarButtonItem = UIBarButtonItem(title: Strings.Localizable.cancel, style: .plain, target: self, action: #selector(cancelSelectTapped)
    )
    
    private lazy var selectBarButton: UIBarButtonItem = UIBarButtonItem(title: Strings.Localizable.select, style: .plain, target: self, action: #selector(selectTapped)
    )
    
    private lazy var selectAllBarButton: UIBarButtonItem = UIBarButtonItem(image: MEGAAssets.UIImage.selectAllItems, style: .plain, target: self, action: #selector(selectAllTapped)
    )
    
    private lazy var forwardBarButton: UIBarButtonItem = UIBarButtonItem(image: MEGAAssets.UIImage.forwardToolbar, style: .plain, target: self, action: #selector(forwardTapped)
    )
    
    private lazy var downloadBarButton: UIBarButtonItem = UIBarButtonItem(image: MEGAAssets.UIImage.offline, style: .plain, target: self, action: #selector(downloadTapped)
    )
    
    private lazy var importBarButton: UIBarButtonItem = UIBarButtonItem(image: MEGAAssets.UIImage.import, style: .plain, target: self, action: #selector(importTapped)
    )
    
    private lazy var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView(style: .medium)
    
    var permissionHandler: any DevicePermissionsHandling {
        DevicePermissionsHandler.makeHandler()
    }
    
    var permissionRouter: some PermissionAlertRouting {
        PermissionAlertRouter.makeRouter(deviceHandler: permissionHandler)
    }

    // MARK: - Init methods
    
    @objc class func instantiate(with chatRoom: MEGAChatRoom) -> ChatSharedItemsViewController {
        let controller = UIStoryboard(name: "ChatSharedItems", bundle: nil).instantiateViewController(withIdentifier: "ChatSharedItemsID") as! ChatSharedItemsViewController
        controller.chatRoom = chatRoom
        return controller
    }
    
    // MARK: - View controller Lifecycle methods.
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = Strings.Localizable.sharedFiles
        
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: CGFloat.leastNormalMagnitude))
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.backgroundColor = TokenColors.Background.page
        tableView.separatorColor = TokenColors.Border.strong
        
        MEGAChatSdk.shared.openNodeHistory(forChat: chatRoom.chatId, delegate: self)
        
        loadMoreFiles()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        MEGAChatSdk.shared.closeNodeHistory(forChat: chatRoom.chatId, delegate: self)

        super.viewWillDisappear(animated)
    }
    
    // MARK: - Actions
    
    @IBAction func actionsTapped(_ sender: UIButton) {
        let position = sender.convert(CGPoint.zero, to: tableView)
        guard let indexPath = tableView.indexPathForRow(at: position), let node = messagesArray[indexPath.row].nodeList?.node(at: 0) else {
            return
        }
        
        let backupsUC = BackupsUseCase(backupsRepository: BackupsRepository.newRepo, nodeRepository: NodeRepository.newRepo)
        let isBackupNode = backupsUC.isBackupNode(node.toNodeEntity())
        let nodeActions = NodeActionViewController(node: node, delegate: self, displayMode: .chatSharedFiles, isBackupNode: isBackupNode, sender: sender)
        present(nodeActions, animated: true, completion: nil)
    }
    
    @objc private func selectTapped() {
        title = Strings.Localizable.selectTitle
        tableView.setEditing(true, animated: true)
        navigationItem.leftBarButtonItem = selectAllBarButton
        navigationItem.rightBarButtonItem = cancelBarButton
        
        let flexibleSpaceBarButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        setToolbarItems([forwardBarButton, flexibleSpaceBarButton, downloadBarButton, flexibleSpaceBarButton, importBarButton], animated: true)
        navigationController?.setToolbarHidden(false, animated: true)
        updateToolbarButtonsState()
    }
    
    @objc private func cancelSelectTapped() {
        if tableView.isEditing {
            title = Strings.Localizable.sharedItems
            tableView.setEditing(false, animated: true)
            navigationItem.leftBarButtonItem = nil
            navigationItem.rightBarButtonItem = selectBarButton
            
            navigationController?.setToolbarHidden(true, animated: true)
        }
    }
    
    @objc private func selectAllTapped() {
        let numberOfRows = tableView.numberOfRows(inSection: 0)
        if messagesArray.count == tableView.indexPathsForSelectedRows?.count {
            for row in 0..<numberOfRows {
                tableView.deselectRow(at: IndexPath(row: row, section: 0), animated: false)
            }
        } else {
            for row in 0..<numberOfRows {
                tableView.selectRow(at: IndexPath(row: row, section: 0), animated: false, scrollPosition: .none)
            }
        }
        updateSelectCountTitle()
        updateToolbarButtonsState()
    }
    
    @objc private func forwardTapped() {
        guard let selectedMessages = selectedMessages() else {
            return
        }
        forwardMessages(selectedMessages)
    }
    
    @objc private func downloadTapped() {
        guard let selectedMessages = selectedMessages() else {
            return
        }
        var transfers = [CancellableTransfer]()
        selectedMessages.forEach { message in
            if let node = message.nodeList?.node(at: 0) {
                transfers.append(CancellableTransfer(handle: node.handle, messageId: message.messageId, chatId: chatRoom.chatId, name: nil, appData: nil, priority: false, type: .downloadChat))
            }
        }
        CancellableTransferRouter(presenter: self, transfers: transfers, transferType: .downloadChat).start()
        cancelSelectTapped()
    }
    
    @objc private func importTapped() {
        guard let selectedMessages = selectedMessages() else {
            return
        }
        
        importNodes(selectedMessages.compactMap {$0.nodeList?.node(at: 0)})
    }
    
    // MARK: - Private methods
    
    private func selectedMessages() -> [MEGAChatMessage]? {
        guard let selectedMessagesIndexPaths = tableView.indexPathsForSelectedRows else {
            return nil
        }
        let selectedIndexes = selectedMessagesIndexPaths.map { $0.row }
        return selectedIndexes.map { messagesArray[$0] }
    }
    
    private func updateToolbarButtonsState() {
        if let selectedMessages = tableView.indexPathsForSelectedRows {
            toolbarItems?.forEach { $0.isEnabled = selectedMessages.isNotEmpty }
        } else {
            toolbarItems?.forEach { $0.isEnabled = false }
        }
    }
    
    private func updateSelectCountTitle() {
        guard let selectedCount = tableView.indexPathsForSelectedRows?.count else {
            title = Strings.Localizable.selectTitle
            return
        }
        title = Strings.Localizable.General.Format.itemsSelected(selectedCount)
    }
    
    private func loadMoreFiles() {
        let source = MEGAChatSdk.shared.loadAttachments(forChat: chatRoom.chatId, count: 16)
        
        switch source {
        case .invalidChat:
            MEGALogError("[ChatSharedFiles] not available chat with the given chatid")
        case .error:
            MEGALogError("[ChatSharedFiles] Error fetching chat files because we are not logged in yet")
        case .none:
            MEGALogDebug("[ChatSharedFiles] No more files available")
            attachmentsLoaded = true
            activityIndicator.stopAnimating()
        case .local:
            MEGALogDebug("[ChatSharedFiles] Files will be fetched locally")
            attachmentsLoading = true
        case .remote:
            MEGALogDebug("[ChatSharedFiles] Files will be fetched remotely")
            attachmentsLoading = true
        @unknown default:
            MEGALogDebug("[ChatSharedFiles] Unnknown error")
        }
    }
    
    private func forwardMessages(_ messages: [MEGAChatMessage]) {
        let sendToNC = UIStoryboard(name: "Chat", bundle: nil).instantiateViewController(withIdentifier: "SendToNavigationControllerID") as! UINavigationController
        let sendToVC = sendToNC.viewControllers.first as! SendToViewController
        sendToVC.sendMode = .forward
        sendToVC.messages = messages
        sendToVC.sourceChatId = chatRoom.chatId
        sendToVC.completion = { [weak self] _, _ in
            if messages.count == 1 {
                SVProgressHUD.showSuccess(withStatus: Strings.Localizable.Chat.forwardedMessage)
            } else {
                SVProgressHUD.showSuccess(withStatus: Strings.Localizable.Chat.forwardedMessages)
            }
            self?.cancelSelectTapped()
        }
        present(sendToNC, animated: true, completion: nil)
    }
    
    private func importNodes(_ nodes: [MEGANode]) {
        let browserNavigation = UIStoryboard(name: "Cloud", bundle: nil).instantiateViewController(withIdentifier: "BrowserNavigationControllerID") as! MEGANavigationController
        present(browserNavigation, animated: true, completion: nil)
        let browserController = browserNavigation.viewControllers.first as! BrowserViewController
        browserController.selectedNodesArray = nodes
        browserController.browserAction = .import
        
        cancelSelectTapped()
    }
    
    @objc private func loadVisibleParticipants() {
        guard let indexPaths = tableView.indexPathsForVisibleRows else {
            return
        }
        
        var userHandles = [UInt64]()
        for indexPath in indexPaths {
            if indexPath.row >= messagesArray.count {
                continue
            }
            let handle = messagesArray[indexPath.row].userHandle
            if MEGAChatSdk.shared.userFullnameFromCache(byUserHandle: handle) == nil && !requestedParticipantsMutableSet.contains(handle) {
                userHandles.append(handle)
                requestedParticipantsMutableSet.insert(handle)
            }
        }
        
        if userHandles.isNotEmpty {
            MEGAChatSdk.shared.loadUserAttributes(forChatId: chatRoom.chatId, usersHandles: userHandles as [NSNumber], delegate: self)
        }
    }
}

// MARK: - MEGAChatNodeHistoryDelegate.

extension ChatSharedItemsViewController: MEGAChatNodeHistoryDelegate {
    
    func onAttachmentLoaded(_ api: MEGAChatSdk, message: MEGAChatMessage?) {
        MEGALogDebug("[ChatSharedFiles] onAttachmentLoaded messageId: \(String(describing: message?.messageId)), node handle: \(String(describing: message?.nodeList?.node(at: 0)?.handle)), node name: \(String(describing: message?.nodeList?.node(at: 0)?.name))")
        
        guard let message = message else {
            attachmentsLoading = false
            activityIndicator.stopAnimating()
            return
        }
        
        if messagesArray.isEmpty {
            navigationItem.rightBarButtonItem = selectBarButton
        }
        
        tableView.performBatchUpdates {
            self.messagesArray.append(message)
            if self.tableView.isEmptyDataSetVisible {
                self.tableView.reloadEmptyDataSet()
            }
            self.tableView.insertRows(at: [IndexPath(row: self.messagesArray.count - 1, section: 0)], with: .automatic)
        }
    }
    
    func onAttachmentReceived(_ api: MEGAChatSdk, message: MEGAChatMessage) {
        MEGALogDebug("[ChatSharedFiles] onAttachmentReceived messageId: \(String(describing: message.messageId)), node handle: \(String(describing: message.nodeList?.node(at: 0)?.handle)), node name: \(String(describing: message.nodeList?.node(at: 0)?.name))")
        
        if messagesArray.isEmpty {
            navigationItem.rightBarButtonItem = selectBarButton
        }
    
        tableView.performBatchUpdates {
            self.messagesArray.insert(message, at: 0)
            self.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
        } completion: { _ in
            if self.tableView.isEmptyDataSetVisible {
                self.tableView.reloadEmptyDataSet()
            }
        }
    }
    
    func onAttachmentDeleted(_ api: MEGAChatSdk, messageId: UInt64) {
        MEGALogDebug("[ChatSharedFiles] onAtonAttachmentReceivedtachmentLoaded \(messageId)")
        guard let message = messagesArray.first(where: { $0.messageId == messageId }) else {
            return
        }
        
        guard let index = messagesArray.firstIndex(of: message) else {
            return
        }
        
        tableView.performBatchUpdates {
            self.tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
            self.messagesArray.remove(at: index)
        } completion: { _ in
            if self.messagesArray.isEmpty {
                self.navigationItem.rightBarButtonItem = nil
                self.tableView.reloadEmptyDataSet()
            }
        }
    }
    
    func onTruncate(_ api: MEGAChatSdk, messageId: UInt64) {
        MEGALogDebug("[ChatSharedFiles] onTruncate")
        messagesArray.removeAll()
        tableView.reloadData()
        navigationItem.rightBarButtonItem = nil
    }
}

// MARK: - UITableViewDataSource

extension ChatSharedItemsViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messagesArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let node = self.messagesArray[indexPath.row].nodeList?.node(at: 0) else { return UITableViewCell() }
        let cell = tableView.dequeueReusableCell(withIdentifier: "sharedItemCell", for: indexPath) as! ChatSharedItemTableViewCell
        
        let message = self.messagesArray[indexPath.row]
        cell.configure(for: node, ownerHandle: message.userHandle, chatRoom: chatRoom)
        if cell.ownerNameLabel.text == nil {
            debounce(#selector(loadVisibleParticipants), delay: 0.3)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if !attachmentsLoaded && !attachmentsLoading {
            let bottomView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 60))
            activityIndicator.center = bottomView.center
            activityIndicator.startAnimating()
            activityIndicator.hidesWhenStopped = true
            bottomView.addSubview(activityIndicator)
            return bottomView
        }
        
        return nil
    }
    
    func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        if !attachmentsLoaded && !attachmentsLoading {
            loadMoreFiles()
        }
    }
}

// MARK: - UITableViewDelegate

extension ChatSharedItemsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.isEditing {
            updateSelectCountTitle()
            updateToolbarButtonsState()
        } else {
            guard let selectedNode = messagesArray[indexPath.row].nodeList?.node(at: 0) else {
                return
            }
            
            if let selectedNodeName = selectedNode.name, selectedNodeName.fileExtensionGroup.isVisualMedia {
                let nodes = NSMutableArray()
                messagesArray.forEach { message in
                    guard let node = message.nodeList?.node(at: 0),
                          let name = node.name else {
                              return
                          }
                    
                    if name.fileExtensionGroup.isVisualMedia {
                        if chatRoom.isPreview {
                            guard let authorizationToken = chatRoom.authorizationToken,
                                  let authNode = MEGASdk.shared.authorizeChatNode(selectedNode, cauth: authorizationToken)
                            else { return }
                            nodes.add(authNode)
                        } else {
                            nodes.add(node)
                        }
                    }
                }
                
                let photoBrowserVC = MEGAPhotoBrowserViewController.photoBrowser(
                    withMediaNodes: nodes,
                    api: MEGASdk.shared,
                    displayMode: .chatSharedFiles,
                    isFromSharedItem: false,
                    presenting: selectedNode
                )
                photoBrowserVC.configureMediaAttachment(
                    inChatId: chatRoom.chatId,
                    messages: messagesArray
                )
                navigationController?.present(photoBrowserVC, animated: true, completion: nil)
            } else {
                if chatRoom.isPreview {
                    guard let authorizationToken = chatRoom.authorizationToken,
                          let authNode = MEGASdk.shared.authorizeChatNode(selectedNode, cauth: authorizationToken)
                    else { return }
                    
                    authNode.mnz_open(in: navigationController, folderLink: false, fileLink: nil, messageId: nil, chatId: nil, isFromSharedItem: false, allNodes: nil)
                } else {
                    selectedNode.mnz_open(in: navigationController, folderLink: false, fileLink: nil, messageId: nil, chatId: nil, isFromSharedItem: false, allNodes: nil)
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if tableView.isEditing {
            updateSelectCountTitle()
            updateToolbarButtonsState()
        }
    }
    
    func tableView(_ tableView: UITableView, shouldBeginMultipleSelectionInteractionAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, didBeginMultipleSelectionInteractionAt indexPath: IndexPath) {
        selectTapped()
    }
}

// MARK: - DZNEmptyDataSetSource

extension ChatSharedItemsViewController: DZNEmptyDataSetSource {
    
    func customView(forEmptyDataSet scrollView: UIScrollView) -> UIView? {
        return EmptyStateView(image: imageForEmptyState(), title: titleForEmtyState(), description: nil, buttonTitle: nil)
    }
    
// MARK: - Empty State
    
    func titleForEmtyState() -> String {
        if MEGAReachabilityManager.isReachable() {
            return Strings.Localizable.noSharedFiles
        } else {
            return Strings.Localizable.noInternetConnection
        }
    }
    
    func imageForEmptyState() -> UIImage {
        if MEGAReachabilityManager.isReachable() {
            return MEGAAssets.UIImage.sharedFilesEmptyState
        } else {
            return MEGAAssets.UIImage.noInternetEmptyState
        }
    }
}

// MARK: - NodeActionViewControllerDelegate

extension ChatSharedItemsViewController: NodeActionViewControllerDelegate {
    func nodeAction(_ nodeAction: NodeActionViewController, didSelect action: MegaNodeActionType, for node: MEGANode, from sender: Any) {
        switch action {
        case .forward:
            guard let message = messagesArray.first(where: { $0.nodeList?.node(at: 0)?.handle == node.handle }) else {
                return
            }
            forwardMessages([message])
            
        case .saveToPhotos:
            Task(priority: .userInitiated) {
                await saveToPhotos(node)
            }
        case .download:
            guard let message = messagesArray.first(where: { $0.nodeList?.node(at: 0)?.handle == node.handle }) else {
                return
            }
            let transfer = CancellableTransfer(handle: node.handle, messageId: message.messageId, chatId: chatRoom.chatId, name: nil, appData: nil, priority: false, isFile: node.isFile(), type: .downloadChat)
            CancellableTransferRouter(presenter: self, transfers: [transfer], transferType: .downloadChat).start()
            cancelSelectTapped()
            
        case .import:
            importNodes([node])
            
        case .exportFile:
            guard let message = messagesArray.first(where: { $0.nodeList?.node(at: 0)?.handle == node.handle }) else {
                return
            }
            ExportFileRouter(presenter: self, sender: sender).exportMessage(node: node, messageId: message.messageId, chatId: chatRoom.chatId)
            
        default: break
        }
    }
    
    private func saveToPhotos(_ node: MEGANode) async {
        guard let message = messagesArray.first(where: { $0.nodeList?.node(at: 0)?.handle == node.handle }) else {
            return
        }
        SaveToPhotosCoordinator
            .customProgressSVGErrorMessageDisplay(configureProgress: {
                TransfersWidgetViewController.sharedTransfer().bringProgressToFrontKeyWindowIfNeeded()
            })
            .saveToPhotosChatNode(handle: node.handle, messageId: message.messageId, chatId: chatRoom.chatId)
    }
}

// MARK: - MEGAChatRequestDelegate

extension ChatSharedItemsViewController: MEGAChatRequestDelegate {
    func onChatRequestFinish(_ api: MEGAChatSdk, request: MEGAChatRequest, error: MEGAChatError) {
        chatRoom = api.chatRoom(forChatId: chatRoom.chatId) ?? chatRoom
        
        if error.type != .MEGAChatErrorTypeOk {
            return
        }
        
        if request.type == .getPeerAttributes {
            guard let handleList = request.megaHandleList, let indexPaths = tableView.indexPathsForVisibleRows else {
                return
            }
            
            var indexPathsToReload = [IndexPath]()
            for i in 0 ..< handleList.size {
                let handle = handleList.megaHandle(at: i)
                for indexPath in indexPaths {
                    if indexPath.row >= messagesArray.count {
                        continue
                    }
                    let message = messagesArray[indexPath.row]
                    if message.userHandle == handle {
                        indexPathsToReload.append(indexPath)
                    }
                }
            }
            
            tableView.reloadRows(at: indexPathsToReload, with: .none)
        }
    }
}
