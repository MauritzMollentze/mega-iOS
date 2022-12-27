import MEGADomain
import Combine

protocol MeetingInfoRouting {
    func showSharedFiles(for chatRoom: ChatRoomEntity)
    func showManageChatHistory(for chatRoom: ChatRoomEntity)
    func showEnableKeyRotation(for chatRoom: ChatRoomEntity)
    func closeMeetingInfoView()
    func showLeaveChatAlert(leaveAction: @escaping(() -> Void))
    func showShareActivity(_ link: String, title: String?, description: String?)
    func showSendToChat(_ link: String)
    func showLinkCopied()
    func showParticipantDetails(email: String, userHandle: HandleEntity, chatRoom: ChatRoomEntity)
    func inviteParticipants(
        withParticipantsAddingViewFactory participantsAddingViewFactory: ParticipantsAddingViewFactory,
        excludeParticpantsId: Set<HandleEntity>,
        selectedUsersHandler: @escaping (([HandleEntity]) -> Void)
    )
    func showAllContactsAlreadyAddedAlert(withParticipantsAddingViewFactory participantsAddingViewFactory: ParticipantsAddingViewFactory)
    func showNoAvailableContactsAlert(withParticipantsAddingViewFactory participantsAddingViewFactory: ParticipantsAddingViewFactory)
}

final class MeetingInfoViewModel: ObservableObject {
    private let scheduledMeeting: ScheduledMeetingEntity
    private var chatRoomUseCase: ChatRoomUseCaseProtocol
    private var userImageUseCase: UserImageUseCaseProtocol
    private let chatUseCase: ChatUseCaseProtocol
    private let userUseCase: UserUseCaseProtocol
    private var chatLinkUseCase: ChatLinkUseCaseProtocol
    private let router: MeetingInfoRouting
    @Published var isAllowNonHostToAddParticipantsOn = true
    @Published var isPublicChat = true
    @Published var isUserInChat = true
    @Published var isModerator = false

    private var chatRoom: ChatRoomEntity?
    private var subscriptions = Set<AnyCancellable>()

    var chatRoomNotificationsViewModel: ChatRoomNotificationsViewModel?
    let chatRoomAvatarViewModel: ChatRoomAvatarViewModel?
    @Published var chatRoomLinkViewModel: ChatRoomLinkViewModel?
    var chatRoomParticipantsListViewModel: ChatRoomParticipantsListViewModel?

    var meetingLink: String?
    
    var title: String {
        scheduledMeeting.title
    }
    
    var subtitle: String {
        if scheduledMeeting.startDate < Date(), let chatRoom {
            return Strings.Localizable.Meetings.Panel.participantsCount(chatRoom.peers.count + 1)
        } else {
            var dateFormatter = DateFormatter.timeShort()
            let start = dateFormatter.localisedString(from: scheduledMeeting.startDate)
            let end = dateFormatter.localisedString(from: scheduledMeeting.endDate)
            dateFormatter = DateFormatter.dateMedium()
            let fullDate = dateFormatter.localisedString(from: scheduledMeeting.startDate)
            return "\(fullDate) · \(start) - \(end)"
        }
    }
    
    var description: String {
        scheduledMeeting.description
    }
    
    init(scheduledMeeting: ScheduledMeetingEntity,
         router: MeetingInfoRouting,
         chatRoomUseCase: ChatRoomUseCaseProtocol,
         userImageUseCase: UserImageUseCaseProtocol,
         chatUseCase: ChatUseCaseProtocol,
         userUseCase: UserUseCaseProtocol,
         chatLinkUseCase: ChatLinkUseCaseProtocol
    ) {
        self.scheduledMeeting = scheduledMeeting
        self.router = router
        self.chatRoomUseCase = chatRoomUseCase
        self.userImageUseCase = userImageUseCase
        self.chatUseCase = chatUseCase
        self.userUseCase = userUseCase
        self.chatLinkUseCase = chatLinkUseCase
        self.chatRoom = chatRoomUseCase.chatRoom(forChatId: scheduledMeeting.chatId)
        
        if let chatRoom {
            self.chatRoomAvatarViewModel = ChatRoomAvatarViewModel(
                title: chatRoom.title ?? "",
                peerHandle: .invalid,
                chatRoomEntity: chatRoom,
                chatRoomUseCase: chatRoomUseCase,
                userImageUseCase: userImageUseCase,
                chatUseCase: chatUseCase,
                userUseCase: userUseCase
            )
            self.isModerator = chatRoom.ownPrivilege.toChatRoomParticipantPrivilege() == .moderator
        } else {
            self.chatRoomAvatarViewModel = nil
        }

        initSubscriptions()
        fetchInitialValues()
    }
    
    private func fetchInitialValues() {
        guard let chatRoom else { return }
        isAllowNonHostToAddParticipantsOn = chatRoom.isOpenInviteEnabled
        isPublicChat = chatRoom.isPublicChat
        self.isUserInChat = chatRoom.ownPrivilege.isUserInChat
        chatLinkUseCase.queryChatLink(for: chatRoom)
        chatRoomNotificationsViewModel = ChatRoomNotificationsViewModel(chatRoom: chatRoom)
        if chatRoom.ownPrivilege == .moderator {
            chatRoomLinkViewModel = chatRoomLinkViewModel(for: chatRoom)
        } else {
            Task {
                do {
                    _ = try await chatLinkUseCase.queryChatLink(for: chatRoom)
                    chatRoomLinkViewModel = chatRoomLinkViewModel(for: chatRoom)
                } catch { }
            }
        }
        
        chatRoomParticipantsListViewModel = ChatRoomParticipantsListViewModel(router: router, chatRoomUseCase: chatRoomUseCase, chatUseCase: chatUseCase, chatRoom: chatRoom)
    }
    
    private func chatRoomLinkViewModel(for chatRoom: ChatRoomEntity) -> ChatRoomLinkViewModel {
        ChatRoomLinkViewModel(
            router: router,
            chatRoom: chatRoom,
            scheduledMeeting: scheduledMeeting,
            chatLinkUseCase: chatLinkUseCase,
            subtitle: subtitle)
    }
    
    private func initSubscriptions() {
        chatRoomUseCase.allowNonHostToAddParticipantsValueChanged(forChatId: scheduledMeeting.chatId)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { error in
                MEGALogError("error fetching allow host to add participants with error \(error)")
            }, receiveValue: { [weak self] handle in
                guard let self = self,
                      let chatRoom = self.chatRoomUseCase.chatRoom(forChatId: self.scheduledMeeting.chatId) else {
                    return
                }
                self.chatRoom = chatRoom
                self.isAllowNonHostToAddParticipantsOn = chatRoom.isOpenInviteEnabled
            })
            .store(in: &subscriptions)
        
        chatUseCase
            .monitorChatPrivateModeUpdate(forChatId: scheduledMeeting.chatId)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { error in
                MEGALogError("error fetching private mode \(error)")
            }, receiveValue: { [weak self] chatRoom in
                self?.chatRoom = chatRoom
                self?.isPublicChat = chatRoom.isPublicChat
            })
            .store(in: &subscriptions)
        
        chatRoomUseCase.ownPrivilegeChanged(forChatId: scheduledMeeting.chatId)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { error in
                MEGALogDebug("error fetching the changed privilege \(error)")
            }, receiveValue: { [weak self] handle in
                guard  let self,
                       let chatRoom = self.chatRoomUseCase.chatRoom(forChatId: self.scheduledMeeting.chatId) else {
                    return
                }
                self.chatRoom = chatRoom
                self.isModerator = chatRoom.ownPrivilege.toChatRoomParticipantPrivilege() == .moderator
                self.isUserInChat = chatRoom.ownPrivilege.isUserInChat
            })
            .store(in: &subscriptions)
    }
}

extension MeetingInfoViewModel{
    //MARK: - Open Invite
    
    @MainActor func allowNonHostToAddParticipantsValueChanged(to enabled: Bool) {
        Task{
            do {
                isAllowNonHostToAddParticipantsOn = try await chatRoomUseCase.allowNonHostToAddParticipants(enabled: isAllowNonHostToAddParticipantsOn, chatId: scheduledMeeting.chatId)
            } catch {
                
            }
        }
    }
    
    //MARK: - SharedFiles
    func sharedFilesViewTapped() {
        guard let chatRoom else {
            return
        }
        router.showSharedFiles(for: chatRoom)
    }
    
    //MARK: - Chat History
    func manageChatHistoryViewTapped() {
        guard let chatRoom else {
            return
        }
        router.showManageChatHistory(for: chatRoom)
    }
    
    //MARK: - Key Rotation
    func enableEncryptionKeyRotationViewTapped() {
        guard let chatRoom else {
            return
        }
        router.showEnableKeyRotation(for: chatRoom)
    }
    
    //MARK: - Share link non host
    func shareMeetingLinkViewTapped() {
        guard let chatRoomLinkViewModel else {
            return
        }
        chatRoomLinkViewModel.showShareMeetingLinkOptions = true
    }
    
    //MARK: - Leave group
    func leaveGroupViewTapped() {
        guard let chatRoom else {
            return
        }
        
        if chatRoom.isPreview {
            chatRoomUseCase.closeChatRoomPreview(chatRoom: chatRoom)
            router.closeMeetingInfoView()
        } else {
            router.showLeaveChatAlert { [weak self] in
                guard let self = self, let stringChatId = MEGASdk.base64Handle(forUserHandle: chatRoom.chatId) else {
                    return
                }
                MEGALinkManager.joiningOrLeavingChatBase64Handles.add(stringChatId)
                Task {
                    let success = await self.chatRoomUseCase.leaveChatRoom(chatRoom: chatRoom)
                    if success {
                        MEGALinkManager.joiningOrLeavingChatBase64Handles.remove(stringChatId)
                    }
                }
                self.router.closeMeetingInfoView()
            }
        }
    }
    
    func isChatPreview() -> Bool {
        chatRoom?.isPreview ?? false
    }
}
