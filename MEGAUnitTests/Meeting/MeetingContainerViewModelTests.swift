import Combine
@testable @preconcurrency import MEGA
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGADomain
import MEGADomainMock
@preconcurrency import XCTest

final class MeetingContainerViewModelTests: XCTestCase {
    
    @MainActor final class Harness {
        
        var sut: MeetingContainerViewModel
        let callUpdateUseCase: MockCallUpdateUseCase
        let tracker = MockTracker()
        let router = MockMeetingContainerRouter()
        let callController = MockCallController()
        let noUserJoinedUseCase = MockMeetingNoUserJoinedUseCase()
        let passcodeManager = MockPasscodeManager()
        
        init(
            chatRoom: ChatRoomEntity = ChatRoomEntity(),
            callUseCase: MockCallUseCase = MockCallUseCase(call: CallEntity()),
            callupdateUseCase: MockCallUpdateUseCase = MockCallUpdateUseCase(),
            chatRoomUseCase: MockChatRoomUseCase = MockChatRoomUseCase(),
            chatUseCase: some ChatUseCaseProtocol = MockChatUseCase(),
            scheduledMeetingUseCase: some ScheduledMeetingUseCaseProtocol = MockScheduledMeetingUseCase(),
            accountUseCase: MockAccountUseCase = .loggedIn,
            authUseCase: some AuthUseCaseProtocol = MockAuthUseCase(),
            analyticsEventUseCase: some AnalyticsEventUseCaseProtocol =  MockAnalyticsEventUseCase(),
            megaHandleUseCase: some MEGAHandleUseCaseProtocol = MockMEGAHandleUseCase()
        ) {
            
            self.callUpdateUseCase = callupdateUseCase
            sut = .init(
                router: router,
                chatRoom: chatRoom,
                callUseCase: callUseCase,
                callUpdateUseCase: callupdateUseCase,
                chatRoomUseCase: chatRoomUseCase,
                chatUseCase: chatUseCase,
                scheduledMeetingUseCase: scheduledMeetingUseCase,
                accountUseCase: accountUseCase,
                authUseCase: authUseCase,
                noUserJoinedUseCase: noUserJoinedUseCase,
                analyticsEventUseCase: analyticsEventUseCase,
                megaHandleUseCase: megaHandleUseCase,
                callController: callController,
                passcodeManager: passcodeManager,
                tracker: tracker
            )
        }
    }
    
    @MainActor func testAction_onViewReady() {
        let harness = Harness(chatRoom: .moderatorMeeting)
        test(viewModel: harness.sut, action: .onViewReady, expectedCommands: [])
        XCTAssert(harness.router.showMeetingUI_calledTimes == 1)
    }
    
    @MainActor func testAction_onViewReady_shouldTrackScreenEvent() {
        let harness = Harness()
        test(viewModel: harness.sut, action: .onViewReady, expectedCommands: [])
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: harness.tracker.trackedEventIdentifiers,
            with: [CallScreenEvent()]
        )
    }
    
    @MainActor func testAction_hangCall_attendeeIsParticipantOrModerator() {
        let harness = Harness(
            chatRoom: .moderatorMeeting,
            callUseCase: MockCallUseCase(call: .testCallEntity)
        )
        test(viewModel: harness.sut, action: .hangCall(presenter: UIViewController(), sender: UIButton()), expectedCommands: [])
        XCTAssert(harness.callController.endCall_CalledTimes == 1)
    }
    
    @MainActor func testAction_backButtonTap_shouldDismissAndShowPasscodeIfNeeded() {
        let harness = Harness(chatRoom: .moderatorMeeting)
        test(viewModel: harness.sut, action: .tapOnBackButton, expectedCommands: [])
        XCTAssert(harness.router.dismiss_calledTimes == 1)
        XCTAssert(harness.passcodeManager.showPassCodeIfNeeded_CalledTimes == 1)
    }
    
    @MainActor func testAction_ChangeMenuVisibility() {
        let harness = Harness(chatRoom: .moderatorMeeting)
        test(viewModel: harness.sut, action: .changeMenuVisibility, expectedCommands: [])
        XCTAssert(harness.router.toggleFloatingPanel_CalledTimes == 1)
    }
    
    @MainActor func testAction_shareLink_Success() async throws {
        let harness = Harness(
            chatRoom: .standardPrivilegeMeeting,
            chatRoomUseCase: MockChatRoomUseCase(publicLinkCompletion: .success("https://mega.link"))
        )
        
        await test(viewModel: harness.sut, action: .presentShareLinkActivity(presenter: UIViewController(), sender: UIButton(), completion: nil), expectedCommands: [])
        
        try await Task.sleep(nanoseconds: 500_000_000)
        
        XCTAssert(harness.router.shareLink_calledTimes == 1)
    }
    
    @MainActor func testAction_shareLink_Failure() {
        let harness = Harness(chatRoom: .standardPrivilegeMeeting)
        test(viewModel: harness.sut, action: .presentShareLinkActivity(presenter: UIViewController(), sender: UIButton(), completion: nil), expectedCommands: [])
        XCTAssert(harness.router.shareLink_calledTimes == 0)
    }
    
    @MainActor func testAction_displayParticipantInMainView() {
        let harness = Harness(chatRoom: .standardPrivilegeMeeting)
        test(viewModel: harness.sut, action: .displayParticipantInMainView(.testParticipant), expectedCommands: [])
        XCTAssert(harness.router.displayParticipantInMainView_calledTimes == 1)
    }
    
    @MainActor func testAction_didDisplayParticipantInMainView() {
        let harness = Harness(chatRoom: .standardPrivilegeMeeting)
        test(viewModel: harness.sut, action: .didDisplayParticipantInMainView(.testParticipant), expectedCommands: [])
        XCTAssert(harness.router.didDisplayParticipantInMainView_calledTimes == 1)
    }
    
    @MainActor func testAction_didSwitchToGridView() {
        let harness = Harness(chatRoom: .standardPrivilegeMeeting)
        test(viewModel: harness.sut, action: .didSwitchToGridView, expectedCommands: [])
        XCTAssert(harness.router.didSwitchToGridView_calledTimes == 1)
    }
    
    @MainActor func testAction_showEndCallDialog() {
        let harness = Harness(
            chatRoom: .standardPrivilegeMeeting,
            callUseCase: MockCallUseCase(call: .init(numberOfParticipants: 1, participants: [100]))
        )
        test(viewModel: harness.sut, action: .showEndCallDialogIfNeeded, expectedCommands: [])
        XCTAssert(harness.router.didShowEndDialog_calledTimes == 1)
    }
    
    @MainActor func testAction_removeEndCallDialogWhenParticipantAdded() {
        let harness = Harness(chatRoom: .standardPrivilegeMeeting)
        test(
            viewModel: harness.sut,
            action: .participantAdded,
            expectedCommands: []
        )
        XCTAssert(harness.router.removeEndDialog_calledTimes == 1)
    }
    
    @MainActor func testAction_removeEndCallDialogAndEndCall() {
        let harness = Harness(chatRoom: .standardPrivilegeMeeting)
        test(
            viewModel: harness.sut,
            action: .removeEndCallAlertAndEndCall,
            expectedCommands: []
        )
        XCTAssert(harness.router.removeEndDialog_calledTimes == 1)
    }
    
    @MainActor func testAction_removeEndCallDialogWhenParticipantJoinWaitingRoom() {
        let harness = Harness(chatRoom: .standardPrivilegeMeeting)
        test(
            viewModel: harness.sut,
            action: .participantJoinedWaitingRoom,
            expectedCommands: []
        )
        XCTAssert(harness.router.removeEndDialog_calledTimes == 1)
    }
    
    @MainActor func testAction_showJoinMegaScreen() {
        let harness = Harness(chatRoom: .standardPrivilegeMeeting)
        test(
            viewModel: harness.sut,
            action: .showJoinMegaScreen,
            expectedCommands: []
        )
        XCTAssert(harness.router.showJoinMegaScreen_calledTimes == 1)
    }
    
    @MainActor func testAction_OnViewReady_NoUserJoined() {
        
        let expectation = expectation(description: "testAction_OnViewReady_NoUserJoined")
        
        let harness = Harness(
            chatRoom: .standardPrivilegeMeeting,
            callUseCase: MockCallUseCase(call: CallEntity(numberOfParticipants: 1, participants: [100])),
            chatRoomUseCase: .standardPrivilegeMeeting
        )
        test(
            viewModel: harness.sut,
            action: .onViewReady,
            expectedCommands: []
        )
        
        var subscription: AnyCancellable? = harness.noUserJoinedUseCase
            .monitor
            .receive(on: DispatchQueue.main)
            .sink { _ in
                expectation.fulfill()
            }
        
        _ = subscription // suppress never used warning
        
        harness.noUserJoinedUseCase.start(timerDuration: 1, chatId: 101)
        waitForExpectations(timeout: 10)
        XCTAssert(harness.router.didShowEndDialog_calledTimes == 1)
        subscription = nil
    }
    
    @MainActor func testAction_muteMicrophoneForMeetingsWhenLastParticipantLeft() {
        let harness = Harness(
            callUseCase: MockCallUseCase(call: .withLocalAudio),
            chatRoomUseCase: .meeting,
            accountUseCase: .loggedIn
        )
        
        test(viewModel: harness.sut, action: .participantRemoved, expectedCommands: [])
        XCTAssertTrue(harness.callController.muteCall_CalledTimes == 1)
    }
    
    @MainActor func testAction_muteMicrophoneForGroupWhenLastParticipantLeft() {
        let harness = Harness(
            callUseCase: MockCallUseCase(call: .withLocalAudio),
            chatRoomUseCase: .group,
            accountUseCase: .loggedIn
        )
        
        test(viewModel: harness.sut, action: .participantRemoved, expectedCommands: [])
        XCTAssertTrue(harness.callController.muteCall_CalledTimes == 1)
    }
    
    @MainActor func testAction_doNotMuteMicrophoneForOneToOneWhenLastParticipantLeft() {
        
        let harness = Harness(
            callUseCase: MockCallUseCase(call: .withLocalAudio),
            chatRoomUseCase: .oneToOne,
            accountUseCase: .loggedIn
        )
        
        test(
            viewModel: harness.sut,
            action: .participantRemoved,
            expectedCommands: []
        )
        XCTAssertTrue(harness.callController.muteCall_CalledTimes == 0)
    }
    
    @MainActor func testAction_endCallForAll() {
        let harness = Harness(chatRoom: ChatRoomEntity(chatType: .meeting))
        
        test(
            viewModel: harness.sut,
            action: .endCallForAll,
            expectedCommands: []
        )
        XCTAssert(harness.callController.endCall_CalledTimes == 1)
    }
    
    @MainActor func testHangCall_forNonGuest_shouldResetCallToUnmute() {
        let harness = Harness(
            chatRoom: ChatRoomEntity(ownPrivilege: .moderator, chatType: .meeting),
            callUseCase: MockCallUseCase(call: .init(chatId: 1, callId: 1, duration: 1, initialTimestamp: 1, finalTimestamp: 1, numberOfParticipants: 1)),
            accountUseCase: MockAccountUseCase(isGuest: false)
        )
        
        test(
            viewModel: harness.sut,
            action: .hangCall(
                presenter: UIViewController(),
                sender: UIButton()
            ),
            expectedCommands: []
        )
        XCTAssertEqual(harness.callController.muteCall_CalledTimes, 0)
    }
    
    @MainActor func testAction_mutedByClient_shouldShowMutedMessage() {
        let harness = Harness(chatRoom: ChatRoomEntity(chatType: .meeting))
        
        test(
            viewModel: harness.sut,
            action: .showMutedBy("Host name"),
            expectedCommands: []
        )
        XCTAssert(harness.router.showMutedMessage_calledTimes == 1)
    }
    
    @MainActor func testSfuProtocolErrorReceived_shouldShowUpdateAppAlert() {
        let harness = Harness(
            callUseCase: MockCallUseCase(call: .connecting)
        )
        harness.callUpdateUseCase.sendCallUpdate(.protocolVersionTermination)
        evaluate {
            harness.router.showProtocolErrorAlert_calledTimes == 1
        }
    }
    
    @MainActor func testUsersLimitErrorReceived_loggedUser_shouldShowFreeAccountLimitAlert() {
        let harness = Harness(callUseCase: MockCallUseCase(call: .connecting))
        harness.callUpdateUseCase.sendCallUpdate(.callUsersLimit)
        evaluate {
            harness.router.showUsersLimitErrorAlert_calledTimes == 1
        }
    }
    
    @MainActor func testUsersLimitErrorReceived_isGuestUser_shouldShowFreeAccountLimitAlertAndTrackEvent() async {
        
        let harness = Harness(
            callUseCase: MockCallUseCase(call: .connecting),
            accountUseCase: MockAccountUseCase(isGuest: true)
        )
        
        harness.callUpdateUseCase.sendCallUpdate(.callUsersLimit)
        
        await Task.megaYield()
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: harness.tracker.trackedEventIdentifiers,
            with: [IOSGuestEndCallFreePlanUsersLimitDialogEvent()]
        )
        
        evaluate {
            harness.router.showUsersLimitErrorAlert_calledTimes == 1
        }
    }
    
    @MainActor func testTooManyParticipantsErrorReceived_shouldDismissCall() {
        let harness = Harness(
            callUseCase: MockCallUseCase(call: CallEntity(status: .connecting, changeType: .status, numberOfParticipants: 1, participants: [100]))
        )
        
        harness.callUpdateUseCase.sendCallUpdate(.tooManyParticipants)
        evaluate {
            harness.router.dismiss_calledTimes == 1
        }
    }
    
    @MainActor func testTerminatingUserParticipationUpdate_shouldDismissCallAndShowPasscodeIfNeeded() {
        let harness = Harness(
            callUseCase: MockCallUseCase(call: CallEntity(status: .inProgress, changeType: .status, numberOfParticipants: 1, participants: [100]))
        )
        
        harness.callUpdateUseCase.sendCallUpdate(CallEntity(status: .terminatingUserParticipation, changeType: .status, numberOfParticipants: 1, participants: [100]))
        evaluate {
            harness.router.dismiss_calledTimes == 1 && 
            harness.passcodeManager.showPassCodeIfNeeded_CalledTimes == 1
        }
    }
    
    @MainActor func testCallUpdate_callWillEndReceivedUserIsModerator_shouldshowCallWillEndAlert() {
        let harness = Harness(
            chatRoom: ChatRoomEntity(ownPrivilege: .moderator, chatType: .meeting)
        )
        test(
            viewModel: harness.sut,
            action: .showCallWillEndAlert(timeToEndCall: 10, completion: { _ in }),
            expectedCommands: []
        )
        XCTAssertEqual(harness.router.showCallWillEndAlert_calledTimes, 1)
    }
    
    @MainActor func testCallUpdate_callDestroyedUserIsCaller_shouldShowUpgradeToPro() {

        let harness = Harness(
            accountUseCase: MockAccountUseCase(currentAccountDetails: AccountDetailsEntity.build())
        )
        
        harness.callUpdateUseCase.sendCallUpdate(CallEntity(status: .terminatingUserParticipation, changeType: .status, termCodeType: .callDurationLimit, isOwnClientCaller: true))
        
        evaluate {
            harness.router.showUpgradeToProDialog_calledTimes == 1
        }
    }
    
    @MainActor func testCallUpdate_callDestroyedUserIsNotCaller_shouldNotShowUpgradeToPro() {
        let harness = Harness()
        harness.callUpdateUseCase.sendCallUpdate(.callTerminatedDueToLimits)
        
        evaluate {
            harness.router.showUpgradeToProDialog_calledTimes == 0 &&
            harness.router.dismiss_calledTimes == 1
        }
    }
    
    @MainActor func testAction_copyLinkTappedLinkAvailable_pasteboardShouldContainLink() async {
        let harness = Harness(
            chatRoom: ChatRoomEntity(chatType: .meeting),
            chatRoomUseCase: MockChatRoomUseCase(publicLinkCompletion: .success("https://mega.link"))
        )
        
        await test(
            viewModel: harness.sut,
            action: .copyLinkTapped,
            expectedCommands: []
        )
        
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        XCTAssertEqual(harness.router.showLinkCopied_calledTimes, 1)
    }
    
    @MainActor func testAction_copyLinkTappedLinkNotAvailable_pasteboardShouldNotContainLink() async {
        let harness = Harness()
        
        await test(
            viewModel: harness.sut,
            action: .copyLinkTapped,
            expectedCommands: []
        )

        try? await Task.sleep(nanoseconds: 1_000_000_000)

        XCTAssertEqual(harness.router.showLinkCopied_calledTimes, 0)
    }
    
    @MainActor func testAction_sendLinkToChatTappedLinkAvailable_shouldCallRouterWithLink() async {
        let harness = Harness(
            chatRoom: ChatRoomEntity(chatType: .meeting),
            chatRoomUseCase: MockChatRoomUseCase(publicLinkCompletion: .success("https://mega.link"))
        )
        
        await test(
            viewModel: harness.sut,
            action: .sendLinkToChatTapped,
            expectedCommands: []
        )
        
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        XCTAssertEqual(harness.router.sendLinkToChat_calledTimes, 1)
    }
    
    @MainActor func testAction_sendLinkToChatTappedLinkNotAvailable_shouldNotCallRouterWithLink() async {
        let harness = Harness()
        
        await test(
            viewModel: harness.sut,
            action: .sendLinkToChatTapped,
            expectedCommands: []
        )
        
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        XCTAssertEqual(harness.router.sendLinkToChat_calledTimes, 0)
    }
    
    @MainActor func testAction_inviteParticipantsTapped_shouldNotifyRouter() {
        let harness = Harness()
        
        test(
            viewModel: harness.sut,
            action: .inviteParticipantsTapped,
            expectedCommands: []
        )
        
        XCTAssertEqual(harness.router.notifyFloatingPanelInviteParticipants_calledTimes, 1)
    }
    
    @MainActor func testAction_inviteParticipantsTappedWithFloatingPanelHidden_shouldNotifyRouter() {
        let harness = Harness()
        
        test(
            viewModel: harness.sut,
            action: .changeMenuVisibility,
            expectedCommands: []
        )
        
        test(
            viewModel: harness.sut,
            action: .inviteParticipantsTapped,
            expectedCommands: []
        )
        
        XCTAssertEqual(harness.router.notifyFloatingPanelInviteParticipants_calledTimes, 1)
    }
    
    @MainActor func test_sendLinkToChatTapped_tracked() {
        let harness = Harness()
        harness.sut.dispatch(.sendLinkToChatTapped)
        XCTAssertTrackedAnalyticsEventsEqual(
            harness.tracker.trackedEventIdentifiers,
            [SendLinkToChatPressedEvent()]
        )
    }
    
    @MainActor func test_inviteParticipantsTapped_tracked() {
        let harness = Harness()
        harness.sut.dispatch(.inviteParticipantsTapped)
        XCTAssertTrackedAnalyticsEventsEqual(
            harness.tracker.trackedEventIdentifiers,
            [InviteParticipantsPressedEvent()]
        )
    }
}

extension CallEntity {
    static var testCallEntity: Self {
        .init(
            chatId: 1,
            callId: 1,
            duration: 1,
            initialTimestamp: 1,
            finalTimestamp: 1,
            numberOfParticipants: 1
        )
    }
    static var callTerminatedDueToLimits: CallEntity {
        .init(
            status: .terminatingUserParticipation,
            changeType: .status,
            termCodeType: .callDurationLimit
        )
    }
    
    static var tooManyParticipants: CallEntity {
        .init(
            status: .terminatingUserParticipation,
            changeType: .status,
            termCodeType: .tooManyParticipants,
            numberOfParticipants: 1,
            participants: [100]
        )
    }
    
    static var callUsersLimit: CallEntity {
        .init(
            status: .terminatingUserParticipation,
            changeType: .status,
            termCodeType: .callUsersLimit,
            numberOfParticipants: 1,
            participants: [100]
        )
    }
    
    static var protocolVersionTermination: CallEntity {
        .init(
            status: .terminatingUserParticipation,
            changeType: .status,
            termCodeType: .protocolVersion,
            numberOfParticipants: 1,
            participants: [100]
        )
    }
    
    static var connecting: CallEntity {
        .init(
            status: .connecting,
            changeType: .status,
            numberOfParticipants: 1,
            participants: [100]
        )
    }
    
    static var withLocalAudio: CallEntity {
        .init(
            hasLocalAudio: true,
            numberOfParticipants: 1,
            participants: [100]
        )
    }
}

extension ChatRoomEntity {
    static var standardPrivilegeMeeting: Self {
        .init(
            ownPrivilege: .standard,
            chatType: .meeting
        )
    }
    
    static var moderatorMeeting: Self {
        .init(
            ownPrivilege: .moderator,
            chatType: .meeting
        )
    }
}

extension MockChatRoomUseCase {
    static var oneToOne: Self {
        .init(chatRoomEntity: .init(chatType: .oneToOne))
    }
    
    static var meeting: Self {
        .init(chatRoomEntity: .init(chatType: .meeting))
    }
    
    static var group: Self {
        .init(chatRoomEntity: .init(chatType: .group))
    }
    
    static var standardPrivilegeMeeting: Self {
        .init(chatRoomEntity: .standardPrivilegeMeeting)
    }
    
    static var moderatorMeeting: Self {
        .init(chatRoomEntity: .moderatorMeeting)
    }
}

extension MockAccountUseCase {
    static var loggedIn: MockAccountUseCase {
        .init(
            currentUser: UserEntity(handle: 100),
            isGuest: false,
            isLoggedIn: true
        )
    }
}

extension CallParticipantEntity {
    static var testParticipant: Self {
        .testParticipant()
    }
    
    static func testParticipant(
        chatId: HandleEntity = 100,
        participantId: HandleEntity = 100,
        clientId: HandleEntity = 100
    ) -> Self {
        .init(
            chatId: chatId,
            participantId: participantId,
            clientId: clientId,
            isModerator: false,
            canReceiveVideoHiRes: true
        )
    }
}
