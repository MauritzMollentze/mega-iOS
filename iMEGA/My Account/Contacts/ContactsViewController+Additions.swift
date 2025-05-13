import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADesignToken
import MEGADomain
import MEGAFoundation
import MEGAL10n
import SwiftUI

extension ContactsViewController {
    
    func setBannerConfig(_ config: BannerView.Config?) {
        viewModel.bannerConfig = config
    }
    
    private static let throttler = Throttler(timeInterval: 0.5, dispatchQueue: .main)
    
    func selectUsers(_ users: [MEGAUser]) {
        guard users.count > 0 else { return }
        selectedUsersArray.addObjects(from: users)
        addItems(toList: users.map { ItemListModel(user: $0) })
        tableView.reloadData()
    }
    
    private var pageTitle: String {
        switch contactsMode {
        case .default:
            return Strings.Localizable.contactsTitle
        case .shareFoldersWith:
            return Strings.Localizable.shareWith
        case .folderSharedWith:
            return Strings.Localizable.sharedWith
        case .chatStartConversation:
            return Strings.Localizable.Chat.NewChat.title
        case .scheduleMeeting, .chatAddParticipant:
            return Strings.Localizable.addParticipants
        case .chatAttachParticipant:
            return Strings.Localizable.sendContact
        case .chatCreateGroup:
            return Strings.Localizable.addParticipants
        case .chatNamingGroup:
            return Strings.Localizable.newGroupChat
        case .inviteParticipants:
            return Strings.Localizable.Meetings.Panel.inviteParticipants
        @unknown default:
            return ""
        }
    }
    
    @objc
    func setNavigationBarTitles() {
        let title = pageTitle
        self.navigationItem.title = title
    }
    
    @objc
    func setNavigationItemStackedPlacement() {
        navigationItem.preferredSearchBarPlacement = .stacked
    }
    
    @objc
    func setupWarningHeader() {
        // reuse hostingViewUIView for warnings about
        // participant limits and unverified users
        var hostingViewUIView: UIView?
        if var bannerConfig = viewModel.bannerConfig {
            if bannerConfig.closeAction != nil {
                let storedAction = bannerConfig.closeAction!
                bannerConfig.closeAction = { [weak self] in
                    storedAction()
                    self?.dismissBanner()
                }
            }
            let hostingView = UIHostingController(rootView: BannerView(config: bannerConfig).font(.footnote))
            hostingViewUIView = hostingView.view
            
        }
        
        if hostingViewUIView == nil {
            hostingViewUIView = UIHostingController(rootView: WarningBannerView(viewModel: .init(warningType: .contactsNotVerified))).view
        }
        
        guard let hostingViewUIView else { return }
        
        hostingViewUIView.backgroundColor = UIColor.yellowFED429
        
        contactsNotVerifiedView.isHidden = true
        contactsNotVerifiedView.addSubview(hostingViewUIView)
        hostingViewUIView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            hostingViewUIView.topAnchor.constraint(equalTo: contactsNotVerifiedView.topAnchor),
            hostingViewUIView.leadingAnchor.constraint(equalTo: contactsNotVerifiedView.leadingAnchor),
            hostingViewUIView.trailingAnchor.constraint(equalTo: contactsNotVerifiedView.trailingAnchor),
            hostingViewUIView.bottomAnchor.constraint(equalTo: contactsNotVerifiedView.bottomAnchor)
        ])
    }
    
    func goToInvite() {
        self.inviteContactTouchUp(inside: nil)
    }
    
    // in new chat empty screens [MEET-4054] we are hiding the tool bar
    // and simplifying UI when users have no contacts
    @objc
    func hideToolbar(_ isEmpty: Bool) {
        // reuse shouldShowInviteToolbarButton as they should be both hidden/shown at the same time
        navigationController?.isToolbarHidden = !shouldShowInviteToolbarButton(isEmpty: isEmpty)
    }
    
    @objc
    var newEmptyChatScreenMode: Bool {
        contactsMode == .chatStartConversation
    }
    
    @objc
    func hideRecentsSectionHeader(isEmpty: Bool) -> Bool {
        newEmptyChatScreenMode && isEmpty
    }
    
    @objc
    func shouldShowInviteToolbarButton(isEmpty: Bool) -> Bool {
        !newEmptyChatScreenMode || !isEmpty
    }
    
    func createNewEmptyView() -> UIView? {
        let state = ChatRoomsEmptyViewStateFactory()
            .newChatContactsEmptyScreen(
                goToInvite: { [weak self] in
                    self?.goToInvite()
                }
            )
        let view = NewChatRoomsEmptyView(
            state: state,
            topPadding: 55.0
        )
        let hostingVC = UIHostingController(rootView: view)
        hostingVC.view.backgroundColor = .clear
        hostingVC.view.translatesAutoresizingMaskIntoConstraints = false
        return hostingVC.view
    }
    
    @objc
    func layoutFooter() {
        guard let footerView = tableView.tableFooterView else { return }
        let width = self.tableView.bounds.size.width
        let size = footerView.systemLayoutSizeFitting(
            CGSize(
                width: width,
                height: UIView.layoutFittingCompressedSize.height
            )
        )
        if footerView.frame.size.height != size.height {
            footerView.frame.size.height = size.height
            tableView.tableFooterView = footerView
        }
    }
    
    @objc
    func showEmptyScreen(_ show: Bool) {
        if show {
            tableView.tableFooterView = tableViewFooter
            if newEmptyChatScreenMode {
                tableViewFooter.subviews.forEach {
                    $0.isHidden = true
                }
                if let newEmptyView = createNewEmptyView() {
                    self.createNewChatEmptyView = newEmptyView
                    let view = UIView()
                    view.wrap(newEmptyView, excludeConstraints: [])
                    tableView.tableFooterView = view
                    layoutFooter()
                }
            } else {
                tableViewFooter.subviews.forEach {
                    $0.isHidden = false
                }
                if self.createNewChatEmptyView != nil {
                    self.createNewChatEmptyView.removeFromSuperview()
                }
            }
        } else {
            tableView.tableFooterView = UIView()
        }
    }
    
    func dismissBanner() {
        viewModel.dismissedBannerWarning = true
        handleContactsNotVerifiedHeaderVisibility()
    }
    
    @objc
    func handleContactsNotVerifiedHeaderVisibility() {
        let showUnverifiedBanner = viewModel.shouldShowUnverifiedContactsBanner(
            contactsMode: contactsMode,
            selectedUsersArray: selectedUsersArray,
            visibleUsersArray: visibleUsersArray
        )
        
        let showParticipantLimitBanner = viewModel.shouldShowBannerWarning(
            selectedUsersCount: selectedUsersArray?.count ?? 0
        )
        let showTopBanner = showUnverifiedBanner || showParticipantLimitBanner
        contactsNotVerifiedView.isHidden = !showTopBanner
    }
    
    @objc
    func createViewModel() {
        self.viewModel = ContactsViewModel(
            sdk: MEGASdk.shared,
            contactsMode: contactsMode,
            shareUseCase: ShareUseCase(
                shareRepository: ShareRepository.newRepo,
                filesSearchRepository: FilesSearchRepository.newRepo,
                nodeRepository: NodeRepository.newRepo)
        )
    }
    
    @objc
    func extractEmails(_ contacts: [CNContact]) -> [NSString] {
        let emails = contacts.extractEmails()
        return emails.map { NSString(string: $0) }
    }
    
    @objc
    func setupColors() {
        let bgColor = TokenColors.Background.page
        view.backgroundColor = bgColor
        tableView.backgroundColor = bgColor
        
        tableView.separatorColor = TokenColors.Border.strong
        tableView.sectionIndexColor = TokenColors.Text.primary
        
        switch contactsMode {
        case .chatAddParticipant, .inviteParticipants, .scheduleMeeting:
            itemListView.backgroundColor = TokenColors.Background.page
        case .chatNamingGroup:
            [chatNamingGroupTableViewHeader, enterGroupNameView, encryptedKeyRotationView, getChatLinkView, allowNonHostToAddParticipantsView].forEach {
                $0.backgroundColor = TokenColors.Background.page
            }
            
            [enterGroupNameBottomSeparatorView, encryptedKeyRotationTopSeparatorView, encryptedKeyRotationBottomSeparatorView, getChatLinkTopSeparatorView, getChatLinkBottomSeparatorView, allowNonHostToAddParticipantsTopSeparatorView, allowNonHostToAddParticipantsBottomSeparatorView].forEach {
                $0.backgroundColor = TokenColors.Border.strong
            }
            
            addGroupAvatarImageView.image = UIImage.groupAvatar
        default:
            break
        }
    }
    
    @objc func setupSubscriptions() {
        subscriptions = [
            viewModel.$alertModel
                .compactMap { $0 }
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in self?.showAlert(alertModel: $0) },
            viewModel.$isLoading
                .dropFirst()
                .removeDuplicates()
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in self?.handleLoading($0) },
            viewModel.dismissViewSubject
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in self?.dismiss(animated: true) }
        ]
    }
    
    private func showAlert(alertModel: AlertModel) {
        present(UIAlertController(model: alertModel), animated: true)
    }
    
    private func handleLoading(_ isLoading: Bool) {
        if isLoading {
            SVProgressHUD.setDefaultMaskType(.clear)
            SVProgressHUD.show()
        } else {
            SVProgressHUD.setDefaultMaskType(.none)
            SVProgressHUD.dismiss()
        }
    }
}

// MARK: - MEGARequestDelegate

extension ContactsViewController: MEGARequestDelegate {
    public func onRequestFinish(_ api: MEGASdk, request: MEGARequest, error: MEGAError) {
        guard error.type == .apiOk else { return }
        switch request.type {
        case .MEGARequestTypeGetAttrUser:
            let userAttribute = UserAttributeEntity(rawValue: request.paramType)
            guard userAttribute == .firstName || userAttribute == .lastName else { return }
            Self.throttler.start { [weak self] in
                Task { @MainActor in
                    self?.reloadUI()
                }
            }
        default:
            return
        }
    }
}

// MARK: - BottomOverlayPresenterProtocol

extension ContactsViewController: BottomOverlayPresenterProtocol {
    public func updateContentView(_ height: CGFloat) {
        additionalSafeAreaInsets = .init(top: 0, left: 0, bottom: height, right: 0)
    }
    
    public func hasUpdatedContentView() -> Bool {
        additionalSafeAreaInsets.bottom != 0
    }
}
