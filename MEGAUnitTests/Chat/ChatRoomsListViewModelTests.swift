import Combine
@testable import MEGA
import MEGAAnalyticsiOS
import MEGADomain
import MEGADomainMock
import MEGAL10n
import MEGAPermissions
import MEGAPermissionsMock
import MEGAPresentation
import MEGAPresentationMock
import MEGATest
import XCTest

final class ChatRoomsListViewModelTests: XCTestCase {
    var subscription: AnyCancellable?
    let chatsListMock = [ChatListItemEntity(chatId: 1, title: "Chat1"),
                         ChatListItemEntity(chatId: 3, title: "Chat2"),
                         ChatListItemEntity(chatId: 67, title: "Chat3")]
    let meetingsListMock = [ChatListItemEntity(chatId: 11, title: "Meeting 1", meeting: true),
                            ChatListItemEntity(chatId: 14, title: "Meeting 2", meeting: true),
                            ChatListItemEntity(chatId: 51, title: "Meeting 3", meeting: true)]
    
    func test_remoteChatStatusChange() {
        let userHandle: HandleEntity = 100
        let chatUseCase = MockChatUseCase(myUserHandle: userHandle)
        let viewModel = makeChatRoomsListViewModel(chatUseCase: chatUseCase, accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100)))
        viewModel.loadChatRoomsIfNeeded()
        
        let expectation = expectation(description: "Awaiting publisher")
        
        subscription = viewModel
            .$chatStatus
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
        
        let chatStatus = ChatStatusEntity.allCases.randomElement()!
        chatUseCase.statusChangePublisher.send((userHandle, chatStatus))
        
        waitForExpectations(timeout: 10)
        
        XCTAssert(viewModel.chatStatus == chatStatus)
        subscription = nil
    }
    
    func testAction_networkNotReachable() {
        let networkUseCase = MockNetworkMonitorUseCase(connected: false)
        let viewModel = makeChatRoomsListViewModel(
            networkMonitorUseCase: networkUseCase
        )
        
        networkUseCase.networkPathChanged(completion: { _ in
            XCTAssert(viewModel.isConnectedToNetwork == networkUseCase.isConnected())
        })
    }
    
    func testAction_addChatButtonTapped() {
        let router = MockChatRoomsListRouter()
        let viewModel = makeChatRoomsListViewModel(router: router)
        
        viewModel.addChatButtonTapped()
        
        XCTAssert(router.presentStartConversation_calledTimes == 1)
    }
    
    func testSelectChatMode_inviteContactNow_shouldMatch() throws {
        assertContactsOnMegaViewStateWhenSelectedChatMode(description: Strings.Localizable.inviteContactNow)
    }
    
    func testSelectChatsMode_inputAsChats_viewModelsShouldMatch() {
        let mockList = chatsListMock
        let viewModel = makeChatRoomsListViewModel(
            chatUseCase: MockChatUseCase(items: mockList),
            chatViewMode: .meetings
        )
        viewModel.loadChatRoomsIfNeeded()
        
        let expectation = expectation(description: "Compare the past meetings")
        subscription = viewModel
            .$displayChatRooms
            .dropFirst()
            .sink {
                XCTAssert(mockList.map { ChatRoomViewModelFactory.make(chatListItem: $0) } == $0)
                expectation.fulfill()
            }
        
        viewModel.selectChatMode(.chats)
        wait(for: [expectation], timeout: 6)
    }
    
    func testSelectChatsMode_inputAsMeeting_viewModelsShouldMatch() {
        let mockList = meetingsListMock
        let viewModel = makeChatRoomsListViewModel(
            chatUseCase: MockChatUseCase(items: mockList),
            chatViewMode: .chats
        )
        viewModel.loadChatRoomsIfNeeded()
        
        let expectation = expectation(description: "Compare the past meetings")
        subscription = viewModel
            .$displayPastMeetings
            .filter { $0?.count == 3 }
            .prefix(1)
            .sink { _ in
                expectation.fulfill()
            }
        
        viewModel.selectChatMode(.meetings)
        wait(for: [expectation], timeout: 10)
        XCTAssertEqual(mockList.map { ChatRoomViewModelFactory.make(chatListItem: $0) }, viewModel.displayPastMeetings)
    }
    
    func test_EmptyChatsList() {
        let viewModel = makeChatRoomsListViewModel()
        XCTAssert(viewModel.displayChatRooms == nil)
    }
    
    func test_ChatListWithoutViewOnScreen() {
        let viewModel = makeChatRoomsListViewModel()
        XCTAssert(viewModel.displayChatRooms == nil)
    }
    
    func testDisplayFutureMeetings_whenEmpty_shouldMatch() throws {
        let chatUseCase = MockChatUseCase(currentChatConnectionStatus: .online)
        let yesterday = try XCTUnwrap(futureDate(byAddingDays: -1))
        let scheduleMeeting = ScheduledMeetingEntity(chatId: 1, endDate: yesterday)
        let scheduleMeetingUseCase = MockScheduledMeetingUseCase(scheduledMeetingsList: [scheduleMeeting])
        let viewModel = makeChatRoomsListViewModel(chatUseCase: chatUseCase, scheduledMeetingUseCase: scheduleMeetingUseCase, chatViewMode: .meetings)
        viewModel.loadChatRoomsIfNeeded()
        
        let predicate = NSPredicate { _, _ in
            viewModel.displayFutureMeetings != nil && viewModel.displayFutureMeetings != []
        }
        let exception = expectation(for: predicate, evaluatedWith: nil)
        exception.isInverted = true
        wait(for: [exception], timeout: 5)
    }
    
    func testDisplayFutureMeetings_containsMultipleSections_shouldMatch() throws {
        let chatUseCase = MockChatUseCase(currentChatConnectionStatus: .online)
        let tomorrow = try XCTUnwrap(futureDate(byAddingDays: 1))
        let scheduleMeeting = ScheduledMeetingEntity(chatId: 1, scheduledId: 100, endDate: tomorrow)
        let scheduleMeetingUseCase = MockScheduledMeetingUseCase(scheduledMeetingsList: [scheduleMeeting], upcomingOccurrences: [100: ScheduledMeetingOccurrenceEntity()])
        let viewModel = makeChatRoomsListViewModel(chatUseCase: chatUseCase, scheduledMeetingUseCase: scheduleMeetingUseCase, chatViewMode: .meetings)
        viewModel.loadChatRoomsIfNeeded()
        
        let predicate = NSPredicate { _, _ in
            viewModel.displayFutureMeetings?.first?.items.first?.scheduledMeeting.chatId == 1
        }
        let exception = expectation(for: predicate, evaluatedWith: nil)
        wait(for: [exception], timeout: 10)
    }
    
    func testDisplayFutureMeetings_containsScheduledMeetingWithNoOccurrence_shouldNotContainFutureMetting() throws {
        let chatUseCase = MockChatUseCase(currentChatConnectionStatus: .online)
        let twoHourAgo = try XCTUnwrap(pastDate(bySubtractHours: 2))
        let oneHourAgo = try XCTUnwrap(pastDate(bySubtractHours: 1))
        let oneHourLater = try XCTUnwrap(futureDate(byAddingHours: 1))
        let scheduleMeetingWithNoOccurrence = ScheduledMeetingEntity(chatId: 1, scheduledId: 100, startDate: twoHourAgo, endDate: oneHourAgo, rules: ScheduledMeetingRulesEntity(frequency: .daily, until: oneHourLater))
        let scheduleMeetingUseCase = MockScheduledMeetingUseCase(scheduledMeetingsList: [scheduleMeetingWithNoOccurrence], upcomingOccurrences: [:])
        let viewModel = makeChatRoomsListViewModel(chatUseCase: chatUseCase, scheduledMeetingUseCase: scheduleMeetingUseCase, chatViewMode: .meetings)
        viewModel.loadChatRoomsIfNeeded()
        
        let predicate = NSPredicate { _, _ in
            viewModel.displayFutureMeetings != nil && viewModel.displayFutureMeetings != []
        }
        let expectation = expectation(for: predicate, evaluatedWith: nil)
        expectation.isInverted = true
        wait(for: [expectation], timeout: 5)
    }
    
    func testDisplayFutureMeetings_containsScheduledMeetingWithOneOccurrence_shouldMatch() throws {
        let chatUseCase = MockChatUseCase(currentChatConnectionStatus: .online)
        let tomorrow = try XCTUnwrap(futureDate(byAddingDays: 1))
        let scheduleMeetingWithOnOccurrence = ScheduledMeetingEntity(chatId: 1, scheduledId: 100, endDate: tomorrow, rules: ScheduledMeetingRulesEntity(frequency: .daily, until: tomorrow))
        let scheduleMeetingUseCase = MockScheduledMeetingUseCase(scheduledMeetingsList: [scheduleMeetingWithOnOccurrence], upcomingOccurrences: [100: ScheduledMeetingOccurrenceEntity()])
        let viewModel = makeChatRoomsListViewModel(chatUseCase: chatUseCase, scheduledMeetingUseCase: scheduleMeetingUseCase, chatViewMode: .meetings)
        viewModel.loadChatRoomsIfNeeded()
        
        let predicate = NSPredicate { _, _ in
            viewModel.displayFutureMeetings?.first?.items.first?.scheduledMeeting.chatId == 1
        }
        let expectation = expectation(for: predicate, evaluatedWith: nil)
        wait(for: [expectation], timeout: 10)
    }
    
    @MainActor
    func testAskForNotificationsPermissionsIfNeeded_IfPermissionHandlerReturnsTrue_asksForNotificationPermissions() async {
        let permissionHandler = MockDevicePermissionHandler()
        let permissionRouter = MockPermissionAlertRouter()
        permissionHandler.shouldAskForNotificationPermissionsValueToReturn = true
        let viewModel = makeChatRoomsListViewModel(
            permissionHandler: permissionHandler,
            permissionAlertRouter: permissionRouter
        )
        await viewModel.askForNotificationsPermissionsIfNeeded()
        XCTAssertEqual(permissionRouter.presentModalNotificationsPermissionPromptCallCount, 1)
    }
    
    @MainActor
    func testAskForNotificationsPermissionsIfNeeded_IfPermissionHandlerReturnsFalse_doesNotAskForNotificationPermissions() async {
        let permissionHandler = MockDevicePermissionHandler()
        let permissionRouter = MockPermissionAlertRouter()
        permissionHandler.shouldAskForNotificationPermissionsValueToReturn = false
        let viewModel = makeChatRoomsListViewModel(
            permissionHandler: permissionHandler,
            permissionAlertRouter: permissionRouter
        )
        await viewModel.askForNotificationsPermissionsIfNeeded()
        XCTAssertEqual(permissionRouter.presentModalNotificationsPermissionPromptCallCount, 0)
    }
    
    func testMeetingTip_meetingListNotShown_shouldNotShowMeetingTip() {
        let sut = makeChatRoomsListViewModel()
        
        sut.loadChatRoomsIfNeeded()
        
        let predicate = NSPredicate { _, _ in
            sut.presentingCreateMeetingTip == true ||
            sut.presentingStartMeetingTip == true ||
            sut.presentingRecurringMeetingTip == true
        }
        let exception = expectation(for: predicate, evaluatedWith: nil)
        exception.isInverted = true
        wait(for: [exception], timeout: 2)
    }
    
    func testCreateMeetingTip_meetingListIsFirstShown_shouldShowCreateMeetingTip() {
        let sut = makeChatRoomsListViewModel(chatViewMode: .meetings)
        
        sut.loadChatRoomsIfNeeded()
        
        let predicate = NSPredicate { _, _ in
            sut.presentingCreateMeetingTip == true
        }
        let exception = expectation(for: predicate, evaluatedWith: nil)
        wait(for: [exception], timeout: 5)
    }
    
    func testStartMeetingTip_meetingTipRecordIsCreateMeeting_shouldNotShowStartMeetingTip() {
        let scheduleMeetingOnboarding = createScheduledMeetingOnboardingEntity(.createMeeting)
        let userAttributeUseCase = MockUserAttributeUseCase(scheduleMeetingOnboarding: scheduleMeetingOnboarding)
        let sut = makeChatRoomsListViewModel(userAttributeUseCase: userAttributeUseCase, chatViewMode: .meetings)
        
        sut.loadChatRoomsIfNeeded()
        sut.startMeetingTipOffsetY = 100
        
        let predicate = NSPredicate { _, _ in
            sut.presentingStartMeetingTip == true
        }
        let exception = expectation(for: predicate, evaluatedWith: nil)
        exception.isInverted = true
        wait(for: [exception], timeout: 2)
    }
    
    func testStartMeetingTip_meetingTipRecordIsStartMeeting_shouldShowStartMeetingTip() {
        let scheduleMeetingOnboarding = createScheduledMeetingOnboardingEntity(.startMeeting)
        let userAttributeUseCase = MockUserAttributeUseCase(scheduleMeetingOnboarding: scheduleMeetingOnboarding)
        let sut = makeChatRoomsListViewModel(userAttributeUseCase: userAttributeUseCase, chatViewMode: .meetings)
        
        sut.loadChatRoomsIfNeeded()
        sut.startMeetingTipOffsetY = 100
        
        let predicate = NSPredicate { _, _ in
            sut.presentingStartMeetingTip == true
        }
        let exception = expectation(for: predicate, evaluatedWith: nil)
        wait(for: [exception], timeout: 5)
    }
    
    func testStartMeetingTip_meetingTipRecordIsStartMeetingAndScrollingList_shouldNotShowStartMeetingTip() {
        let scheduleMeetingOnboarding = createScheduledMeetingOnboardingEntity(.startMeeting)
        let userAttributeUseCase = MockUserAttributeUseCase(scheduleMeetingOnboarding: scheduleMeetingOnboarding)
        let sut = makeChatRoomsListViewModel(userAttributeUseCase: userAttributeUseCase, chatViewMode: .meetings)
        
        sut.loadChatRoomsIfNeeded()
        sut.startMeetingTipOffsetY = 100
        sut.isMeetingListScrolling = true
        
        let predicate = NSPredicate { _, _ in
            sut.presentingStartMeetingTip == true
        }
        let exception = expectation(for: predicate, evaluatedWith: nil)
        exception.isInverted = true
        wait(for: [exception], timeout: 2)
    }
    
    func testStartMeetingTip_meetingTipRecordIsStartMeetingAndTipIsNotVisiable_shouldNotShowStartMeetingTip() {
        let scheduleMeetingOnboarding = createScheduledMeetingOnboardingEntity(.startMeeting)
        let userAttributeUseCase = MockUserAttributeUseCase(scheduleMeetingOnboarding: scheduleMeetingOnboarding)
        let sut = makeChatRoomsListViewModel(userAttributeUseCase: userAttributeUseCase, chatViewMode: .meetings)
        
        sut.loadChatRoomsIfNeeded()
        sut.startMeetingTipOffsetY = nil
        
        let predicate = NSPredicate { _, _ in
            sut.presentingStartMeetingTip == true
        }
        let exception = expectation(for: predicate, evaluatedWith: nil)
        exception.isInverted = true
        wait(for: [exception], timeout: 2)
    }
    
    func testRecurringMeetingTip_meetingTipRecordIsStartMeeting_shouldNotShowRecurringMeetingTip() {
        let scheduleMeetingOnboarding = createScheduledMeetingOnboardingEntity(.startMeeting)
        let userAttributeUseCase = MockUserAttributeUseCase(scheduleMeetingOnboarding: scheduleMeetingOnboarding)
        let sut = makeChatRoomsListViewModel(userAttributeUseCase: userAttributeUseCase, chatViewMode: .meetings)
        
        sut.loadChatRoomsIfNeeded()
        sut.recurringMeetingTipOffsetY = 100
        
        let predicate = NSPredicate { _, _ in
            sut.presentingRecurringMeetingTip == true
        }
        let exception = expectation(for: predicate, evaluatedWith: nil)
        exception.isInverted = true
        wait(for: [exception], timeout: 2)
    }
    
    func testRecurringMeetingTip_meetingTipRecordIsStartMeeting_shouldShowRecurringMeetingTip() {
        let scheduleMeetingOnboarding = createScheduledMeetingOnboardingEntity(.recurringMeeting)
        let userAttributeUseCase = MockUserAttributeUseCase(scheduleMeetingOnboarding: scheduleMeetingOnboarding)
        let sut = makeChatRoomsListViewModel(userAttributeUseCase: userAttributeUseCase, chatViewMode: .meetings)
        
        sut.loadChatRoomsIfNeeded()
        sut.recurringMeetingTipOffsetY = 100
        
        let predicate = NSPredicate { _, _ in
            sut.presentingRecurringMeetingTip == true
        }
        let exception = expectation(for: predicate, evaluatedWith: nil)
        wait(for: [exception], timeout: 5)
    }
    
    func testArchivedChatsTapped_underTheChatListTab_shouldShowArchivedChatRooms() {
        let router = MockChatRoomsListRouter()
        let sut = makeChatRoomsListViewModel(router: router)
        
        sut.archivedChatsTapped()
        
        XCTAssertEqual(router.showArchivedChatRooms_calledTimes, 1)
    }
    
    func testLoadChatRoomsIfNeeded_onCall_shouldCallRetryPendingConnections() {
        let retryPendingConnectionsUseCase = MockRetryPendingConnectionsUseCase()
        let chatUseCase = MockChatUseCase()
        let sut = makeChatRoomsListViewModel(
            chatUseCase: chatUseCase,
            retryPendingConnectionsUseCase: retryPendingConnectionsUseCase
        )
        
        sut.loadChatRoomsIfNeeded()
        
        XCTAssertEqual(chatUseCase.retryPendingConnections_calledTimes, 1)
        XCTAssertEqual(retryPendingConnectionsUseCase.retryPendingConnections_calledTimes, 1)
    }
    
    func testShouldDisplayUnreadBadgeForChats_onChatsHasUnreadMessage_shouldBeTrue() {
        let chatUseCase = MockChatUseCase(
            items: [ChatListItemEntity(unreadCount: 1)],
            currentChatConnectionStatus: .online
        )
        let sut = makeChatRoomsListViewModel(
            chatUseCase: chatUseCase
        )
        
        sut.loadChatRoomsIfNeeded()
        
        evaluate {
            sut.shouldDisplayUnreadBadgeForChats == true
        }
    }
    
    func testShouldDisplayUnreadBadgeForChats_onChatsHasNoUnreadMessage_shouldBeFalse() {
        let chatUseCase = MockChatUseCase(
            items: [ChatListItemEntity(unreadCount: 0)],
            currentChatConnectionStatus: .online
        )
        let sut = makeChatRoomsListViewModel(
            chatUseCase: chatUseCase
        )
        
        sut.loadChatRoomsIfNeeded()
        
        evaluate {
            sut.shouldDisplayUnreadBadgeForChats == false
        }
    }
    
    func testShouldDisplayUnreadBadgeForMeetings_onMeetingsHasUnreadMessage_shouldBeTrue() {
        let chatUseCase = MockChatUseCase(
            items: [ChatListItemEntity(unreadCount: 1)],
            currentChatConnectionStatus: .online
        )
        let sut = makeChatRoomsListViewModel(
            chatUseCase: chatUseCase
        )
        
        sut.loadChatRoomsIfNeeded()
        
        evaluate {
            sut.shouldDisplayUnreadBadgeForMeetings == true
        }
    }
    
    func testShouldDisplayUnreadBadgeForMeetings_onMeetingsHasNoUnreadMessage_shouldBeFalse() {
        let chatUseCase = MockChatUseCase(
            items: [ChatListItemEntity(unreadCount: 0)],
            currentChatConnectionStatus: .online
        )
        let sut = makeChatRoomsListViewModel(
            chatUseCase: chatUseCase
        )
        
        sut.loadChatRoomsIfNeeded()
        
        evaluate {
            sut.shouldDisplayUnreadBadgeForMeetings == false
        }
    }
    
    func testShouldDisplayUnreadBadgeForMeetings_onChatConnectionStatusUpdateForNewUnreadMeetingMessage_shouldBeTrue() {
        let chatConnectionStatusUpdatePublisher = PassthroughSubject<ChatConnectionStatus, Never>()
        let chatUseCase = MockChatUseCase(
            chatConnectionStatusUpdatePublisher: chatConnectionStatusUpdatePublisher,
            items: [ChatListItemEntity(unreadCount: 1)]
        )
        let sut = makeChatRoomsListViewModel(
            chatUseCase: chatUseCase
        )
        
        sut.loadChatRoomsIfNeeded()
        chatConnectionStatusUpdatePublisher.send(.online)
        
        evaluate {
            sut.shouldDisplayUnreadBadgeForMeetings == true
        }
    }
    
    func test_addChatButtonTapped_tracksAnalyticsEvent() {
        let mockTracker = MockTracker()
        let viewModel = makeChatRoomsListViewModel(
            router: MockChatRoomsListRouter(),
            tracker: mockTracker
        )
        
        viewModel.addChatButtonTapped()
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: mockTracker.trackedEventIdentifiers,
            with: [
                ChatRoomsStartConversationMenuEvent()
            ]
        )
    }
    
    // MARK: - Private methods
    
    private func assertContactsOnMegaViewStateWhenSelectedChatMode(description: String, line: UInt = #line) {
        let router = MockChatRoomsListRouter()
        let viewModel = makeChatRoomsListViewModel(router: router, chatViewMode: .meetings)
        
        let expectation = expectation(description: "Waiting for contactsOnMegaViewState to be updated")
        
        subscription = viewModel
            .$contactsOnMegaViewState
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
        
        viewModel.selectChatMode(.chats)
        wait(for: [expectation], timeout: 10)
        XCTAssertEqual(viewModel.contactsOnMegaViewState?.description, description, line: line)
    }
    
    private func pastDate(bySubtractHours numberOfHours: Int) -> Date? {
        Calendar.current.date(byAdding: .day, value: -numberOfHours, to: Date())
    }
    
    private func futureDate(byAddingHours numberOfHours: Int) -> Date? {
        Calendar.current.date(byAdding: .day, value: numberOfHours, to: Date())
    }
    
    private func futureDate(byAddingDays numberOfDays: Int) -> Date? {
        Calendar.current.date(byAdding: .day, value: numberOfDays, to: Date())
    }
    
    private func createScheduledMeetingOnboardingEntity(_ tipType: ScheduledMeetingOnboardingTipType) -> ScheduledMeetingOnboardingEntity {
        ScheduledMeetingOnboardingEntity(ios: ScheduledMeetingOnboardingIos(record: ScheduledMeetingOnboardingRecord(currentTip: tipType)))
    }
    
    private func makeChatRoomsListViewModel(
        router: some ChatRoomsListRouting = MockChatRoomsListRouter(),
        chatUseCase: any ChatUseCaseProtocol = MockChatUseCase(),
        networkMonitorUseCase: any NetworkMonitorUseCaseProtocol = MockNetworkMonitorUseCase(),
        accountUseCase: any AccountUseCaseProtocol = MockAccountUseCase(),
        chatRoomUseCase: any ChatRoomUseCaseProtocol = MockChatRoomUseCase(),
        scheduledMeetingUseCase: any ScheduledMeetingUseCaseProtocol = MockScheduledMeetingUseCase(),
        userAttributeUseCase: any UserAttributeUseCaseProtocol = MockUserAttributeUseCase(),
        chatType: ChatViewType = .regular,
        chatViewMode: ChatViewMode = .chats,
        permissionHandler: some DevicePermissionsHandling = MockDevicePermissionHandler(),
        permissionAlertRouter: some PermissionAlertRouting = MockPermissionAlertRouter(),
        chatListItemCacheUseCase: some ChatListItemCacheUseCaseProtocol = MockChatListItemCacheUseCase(),
        retryPendingConnectionsUseCase: some RetryPendingConnectionsUseCaseProtocol = MockRetryPendingConnectionsUseCase(),
        tracker: some AnalyticsTracking = DIContainer.tracker,
        featureFlagProvider: some FeatureFlagProviderProtocol = MockFeatureFlagProvider(list: [:])
    ) -> ChatRoomsListViewModel {
        let sut = ChatRoomsListViewModel(
            router: router,
            chatUseCase: chatUseCase,
            chatRoomUseCase: chatRoomUseCase,
            networkMonitorUseCase: networkMonitorUseCase,
            accountUseCase: accountUseCase,
            scheduledMeetingUseCase: scheduledMeetingUseCase,
            userAttributeUseCase: userAttributeUseCase,
            chatType: chatType,
            chatViewMode: chatViewMode,
            permissionHandler: permissionHandler,
            permissionAlertRouter: permissionAlertRouter,
            chatListItemCacheUseCase: chatListItemCacheUseCase,
            retryPendingConnectionsUseCase: retryPendingConnectionsUseCase,
            tracker: tracker,
            featureFlagProvider: featureFlagProvider
        )
        return sut
    }
}

final class MockChatRoomsListRouter: ChatRoomsListRouting {
    var openCallView_calledTimes = 0
    var presentStartConversation_calledTimes = 0
    var presentMeetingAlreadyExists_calledTimes = 0
    var presentCreateMeeting_calledTimes = 0
    var presentEnterMeeting_calledTimes = 0
    var presentScheduleMeeting_calledTimes = 0
    var presentWaitingRoom_calledTimes = 0
    var showInviteContactScreen_calledTimes = 0
    var showContactsOnMegaScreen_calledTimes = 0
    var showDetails_calledTimes = 0
    var present_calledTimes = 0
    var presentMoreOptionsForChat_calledTimes = 0
    var showGroupChatInfo_calledTimes = 0
    var showMeetingInfo_calledTimes = 0
    var showMeetingOccurrences_calledTimes = 0
    var showContactDetailsInfo_calledTimes = 0
    var showArchivedChatRooms_calledTimes = 0
    var openChatRoom_calledTimes = 0
    var showErrorMessage_calledTimes = 0
    var showSuccessMessage_calledTimes = 0
    var editMeeting_calledTimes = 0
    
    var navigationController: UINavigationController?
    
    func presentStartConversation() {
        presentStartConversation_calledTimes += 1
    }
    
    func presentMeetingAlreadyExists() {
        presentMeetingAlreadyExists_calledTimes += 1
    }
    
    func presentCreateMeeting() {
        presentCreateMeeting_calledTimes += 1
    }
    
    func presentEnterMeeting() {
        presentEnterMeeting_calledTimes += 1
    }
    
    func presentScheduleMeeting() {
        presentScheduleMeeting_calledTimes += 1
    }
    
    func presentWaitingRoom(for scheduledMeeting: ScheduledMeetingEntity) {
        presentWaitingRoom_calledTimes += 1
    }
    
    func showInviteContactScreen() {
        showInviteContactScreen_calledTimes += 1
    }
    
    func showContactsOnMegaScreen() {
        showContactsOnMegaScreen_calledTimes += 1
    }
    
    func showDetails(forChatId chatId: HandleEntity) {
        showDetails_calledTimes += 1
    }
    
    func present(alert: UIAlertController, animated: Bool) {
        present_calledTimes += 1
    }
    
    func presentMoreOptionsForChat(withDNDEnabled dndEnabled: Bool, dndAction: @escaping () -> Void, markAsReadAction: (() -> Void)?, infoAction: @escaping () -> Void, archiveAction: @escaping () -> Void) {
        presentMoreOptionsForChat_calledTimes += 1
    }
    
    func showGroupChatInfo(forChatRoom chatRoom: ChatRoomEntity) {
        showGroupChatInfo_calledTimes += 1
    }
    
    func showMeetingInfo(for scheduledMeeting: ScheduledMeetingEntity) {
        showMeetingInfo_calledTimes += 1
    }
    
    func showMeetingOccurrences(for scheduledMeeting: ScheduledMeetingEntity) {
        showMeetingOccurrences_calledTimes += 1
    }
    
    func showContactDetailsInfo(forUseHandle userHandle: HandleEntity, userEmail: String) {
        showContactDetailsInfo_calledTimes += 1
    }
    
    func showArchivedChatRooms() {
        showArchivedChatRooms_calledTimes += 1
    }
    
    func openChatRoom(withChatId chatId: ChatIdEntity, publicLink: String?) {
        openChatRoom_calledTimes += 1
    }
    
    func openCallView(for call: CallEntity, in chatRoom: ChatRoomEntity) {
        openCallView_calledTimes += 1
    }
    
    func showErrorMessage(_ message: String) {
        showErrorMessage_calledTimes += 1
    }
    
    func showSuccessMessage(_ message: String) {
        showSuccessMessage_calledTimes += 1
    }
    
    func edit(scheduledMeeting: ScheduledMeetingEntity) {
        editMeeting_calledTimes += 1
    }
    
}
