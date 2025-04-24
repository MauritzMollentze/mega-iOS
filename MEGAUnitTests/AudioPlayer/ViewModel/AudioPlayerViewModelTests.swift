@testable import MEGA
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGAAppSDKRepoMock
import MEGADomain
import MEGADomainMock
import MEGAL10n
import MEGATest
import XCTest

final class AudioPlayerViewModelTests: XCTestCase {
    
    @MainActor
    func testPlaybackActions() async {
        let (onlineSUT, _, playerHandler, _) = makeOnlineSUT()
        
        await test(
            viewModel: onlineSUT,
            action: .onViewDidLoad,
            expectedCommands: [
                .showLoading(true),
                .updateShuffle(status: playerHandler.isShuffleEnabled()),
                .updateSpeed(mode: .normal),
                .configureFileLinkPlayer(title: "Track 5", subtitle: Strings.Localizable.fileLink)
            ],
            timeout: 0.5
        )
        
        await test(viewModel: onlineSUT, action: .updateCurrentTime(percentage: 0.2), expectedCommands: [])
        XCTAssertEqual(playerHandler.updateProgressCompleted_calledTimes, 1)
        
        await test(viewModel: onlineSUT, action: .progressDragEventBegan, expectedCommands: [])
        XCTAssertEqual(playerHandler.progressDragEventBeganCalledTimes, 1)
        
        await test(viewModel: onlineSUT, action: .progressDragEventEnded, expectedCommands: [])
        XCTAssertEqual(playerHandler.progressDragEventEndedCalledTimes, 1)
        
        await test(viewModel: onlineSUT, action: .onShuffle(active: true), expectedCommands: [])
        XCTAssertEqual(playerHandler.onShuffle_calledTimes, 1)
        
        await test(viewModel: onlineSUT, action: .onPlayPause, expectedCommands: [])
        XCTAssertEqual(playerHandler.togglePlay_calledTimes, 1)
        
        await test(viewModel: onlineSUT, action: .onGoBackward, expectedCommands: [])
        XCTAssertEqual(playerHandler.goBackward_calledTimes, 1)
        
        await test(viewModel: onlineSUT, action: .onPrevious, expectedCommands: [])
        XCTAssertEqual(playerHandler.playPrevious_calledTimes, 1)
        
        await test(viewModel: onlineSUT, action: .onNext, expectedCommands: [])
        XCTAssertEqual(playerHandler.playNext_calledTimes, 1)
        
        await test(viewModel: onlineSUT, action: .onGoForward, expectedCommands: [])
        XCTAssertEqual(playerHandler.goForward_calledTimes, 1)
        
        await test(viewModel: onlineSUT, action: .onRepeatPressed, expectedCommands: [.updateRepeat(status: .loop)])
        XCTAssertEqual(playerHandler.onRepeatAll_calledTimes, 1)
        
        await test(viewModel: onlineSUT, action: .onRepeatPressed, expectedCommands: [.updateRepeat(status: .repeatOne)])
        XCTAssertEqual(playerHandler.onRepeatOne_calledTimes, 1)
        
        await test(viewModel: onlineSUT, action: .onRepeatPressed, expectedCommands: [.updateRepeat(status: .none)])
        XCTAssertEqual(playerHandler.onRepeatDisabled_calledTimes, 1)
        
        await test(viewModel: onlineSUT, action: .viewDidDisappear, expectedCommands: [])
        XCTAssertEqual(playerHandler.removePlayerListener_calledTimes, 1)
        
        await test(viewModel: onlineSUT, action: .onChangeSpeedModePressed, expectedCommands: [.updateSpeed(mode: .oneAndAHalf)])
        XCTAssertEqual(playerHandler.changePlayerRate_calledTimes, 1)
        
        await test(viewModel: onlineSUT, action: .onChangeSpeedModePressed, expectedCommands: [.updateSpeed(mode: .double)])
        XCTAssertEqual(playerHandler.changePlayerRate_calledTimes, 2)
        
        await test(viewModel: onlineSUT, action: .onChangeSpeedModePressed, expectedCommands: [.updateSpeed(mode: .half)])
        XCTAssertEqual(playerHandler.changePlayerRate_calledTimes, 3)
        
        await test(viewModel: onlineSUT, action: .onChangeSpeedModePressed, expectedCommands: [.updateSpeed(mode: .normal)])
        XCTAssertEqual(playerHandler.changePlayerRate_calledTimes, 4)
    }
    
    @MainActor
    func testRouterActions() async {
        let (onlineSUT, _, _, onlineRouter) = makeOnlineSUT()
        let (offlineSUT, offlineRouter) = makeOfflineSUT()
        
        await test(viewModel: onlineSUT, action: .dismiss, expectedCommands: [])
        XCTAssertEqual(onlineRouter.dismiss_calledTimes, 1)
        
        await test(viewModel: onlineSUT, action: .showPlaylist, expectedCommands: [])
        XCTAssertEqual(onlineRouter.goToPlaylist_calledTimes, 1)
        
        await test(viewModel: onlineSUT, action: .viewWillDisappear(reason: .userInitiatedDismissal), expectedCommands: [])
        XCTAssertEqual(onlineRouter.showMiniPlayer_calledTimes, 1)
        
        await test(viewModel: offlineSUT, action: .viewWillDisappear(reason: .userInitiatedDismissal), expectedCommands: [])
        XCTAssertEqual(offlineRouter.showMiniPlayer_calledTimes, 1)
        
        await test(viewModel: onlineSUT, action: .initMiniPlayer, expectedCommands: [])
        XCTAssertEqual(onlineRouter.showMiniPlayer_calledTimes, 2)
        
        await test(viewModel: onlineSUT, action: .`import`, expectedCommands: [])
        XCTAssertEqual(onlineRouter.importNode_calledTimes, 1)
        
        await test(viewModel: onlineSUT, action: .share(sender: nil), expectedCommands: [])
        XCTAssertEqual(onlineRouter.share_calledTimes, 1)
        
        await test(viewModel: onlineSUT, action: .sendToChat, expectedCommands: [])
        XCTAssertEqual(onlineRouter.sendToContact_calledTimes, 1)
        
        await test(viewModel: onlineSUT, action: .showActionsforCurrentNode(sender: UIButton()), expectedCommands: [])
        XCTAssertEqual(onlineRouter.showAction_calledTimes, 1)
    }
    
    @MainActor
    func testOnReceiveAudioPlayerActions_shouldInvokeCorrectCommands() {
        let (onlineSUT, playbackUseCase, _, _) = makeOnlineSUT()
        playbackUseCase._status = .startFromBeginning
        
        assert(
            onlineSUT,
            when: { viewModel in
                viewModel.audioDidStartPlayingItem(testItem)
            },
            shouldInvokeCommands: []
        )
    }
    
    @MainActor
    func testAudioStartPlayingWithDisplayDialogStatus_shouldDisplayDialog_andPausePlayer_whenAppIsActive() async {
        let (onlineSUT, playbackUseCase, playerHandler, _) = makeOnlineSUT()
        onlineSUT.checkAppIsActive = { true }
        playbackUseCase._status = .displayDialog(playbackTime: 1234.0)
        
        let expectedCommands: [AudioPlayerViewModel.Command] = [
            .displayPlaybackContinuationDialog(
                fileName: testItem.name,
                playbackTime: 1234.0
            )
        ]
        
        await test(
            viewModel: onlineSUT,
            trigger: { onlineSUT.audioDidStartPlayingItem(testItem) },
            expectedCommands: expectedCommands
        )
        
        XCTAssertEqual(playerHandler.pause_calledTimes, 1)
    }
    
    @MainActor
    func testAudioStartPlayingWithDisplayDialogStatus_shouldNotDisplayDialog_whenAppIsNotActive() async {
        let (onlineSUT, playbackUseCase, _, _) = makeOnlineSUT()
        onlineSUT.checkAppIsActive = { false }
        playbackUseCase._status = .displayDialog(playbackTime: 1234.0)

        await test(
            viewModel: onlineSUT,
            trigger: { onlineSUT.audioDidStartPlayingItem(testItem) },
            expectedCommands: []
        )
    }

    @MainActor
    func testAudioStartPlayingWithDisplayDialogStatus_shouldResumePlayback_whenAppIsNotActive() {
        let (onlineSUT, playbackUseCase, playerHandler, _) = makeOnlineSUT()
        onlineSUT.checkAppIsActive = { false }
        playbackUseCase._status = .displayDialog(playbackTime: 1234.0)
        
        let expectation = XCTestExpectation(description: #function)
        
        playerHandler.onPlayerResumePlaybackCompletion = {
            expectation.fulfill()
        }
        
        onlineSUT.audioDidStartPlayingItem(testItem)

        wait(for: [expectation], timeout: 1)
        
        XCTAssertEqual(playerHandler.pause_calledTimes, 0)
        XCTAssertEqual(playerHandler.playerResumePlayback_Calls, [1234.0])
        XCTAssertEqual(
            playbackUseCase.setPreference_Calls,
            [.resumePreviousSession]
        )
    }
    
    @MainActor
    func testAudioPlaybackContinuation_resumeSession() async {
        let expectation = expectation(description: #function)
        let (onlineSUT, playbackUseCase, playerHandler, _) = makeOnlineSUT()
        playbackUseCase._status = .resumeSession(playbackTime: 1234.0)
        
        playerHandler.onPlayerResumePlaybackCompletion = {
            expectation.fulfill()
        }
        
        onlineSUT.audioDidStartPlayingItem(testItem)
        
        await fulfillment(of: [expectation], timeout: 1)
        
        XCTAssertEqual(
            playerHandler.playerResumePlayback_Calls,
            [1234.0]
        )
    }
    
    @MainActor
    func testSelectPlaybackContinuationDialog_shouldSetPreference() {
        let (onlineSUT, playbackUseCase, _, _) = makeOnlineSUT()
        onlineSUT.dispatch(.onSelectResumePlaybackContinuationDialog(playbackTime: 1234.0))
        
        XCTAssertEqual(
            playbackUseCase.setPreference_Calls,
            [.resumePreviousSession]
        )
        
        onlineSUT.dispatch(.onSelectRestartPlaybackContinuationDialog)
        
        XCTAssertEqual(
            playbackUseCase.setPreference_Calls,
            [.resumePreviousSession, .restartFromBeginning]
        )
    }
    
    // MARK: - viewWillDisappear
    
    @MainActor
    func testViewWillDisappear_whenLoggedInAndDisappearReasonUserInitiatedDismissal_initMiniPlayer() {
        let loggedInAccountUseCase = MockAccountUseCase(isLoggedIn: true)
        let defaultConfigEntity = audioPlayerConfigEntity(node: anyAudioNode)
        let (sut, _, router) = makeSUT(
            configEntity: defaultConfigEntity,
            accountUseCase: loggedInAccountUseCase
        )
        
        sut.dispatch(.viewWillDisappear(reason: .userInitiatedDismissal))
        
        XCTAssertEqual(router.showNodesMiniPlayer_calledTimes, 1)
    }
    
    @MainActor
    func testViewWillDisappear_whenNotLoggedInAndDisappearReasonUserInitiatedDismissal_stopsPlayer() {
        let loggedInAccountUseCase = MockAccountUseCase(isLoggedIn: false)
        let streamingInfoUseCase = MockStreamingInfoUseCase()
        let defaultConfigEntity = audioPlayerConfigEntity(node: anyAudioNode)
        let (sut, _, router) = makeSUT(
            configEntity: defaultConfigEntity,
            streamingInfoUseCase: streamingInfoUseCase,
            accountUseCase: loggedInAccountUseCase
        )
        sut.dispatch(.onViewDidLoad)
        
        sut.dispatch(.viewWillDisappear(reason: .userInitiatedDismissal))
        
        guard let playerHandler = defaultConfigEntity.playerHandler as? MockAudioPlayerHandler else {
            XCTFail("Expect to have mock audio player handler type: \(type(of: MockAudioPlayerHandler.self)), but got different type.")
            return
        }
        XCTAssertEqual(router.showNodesMiniPlayer_calledTimes, 0)
        XCTAssertEqual(playerHandler.pause_calledTimes, 1)
        XCTAssertEqual(playerHandler.closePlayer_calledTimes, 1)
    }
    
    @MainActor
    func testViewWillDisappear_whenNotLoggedInAndDisappearReasonSystemPushedAnotherView_shouldNotStopsPlayer() {
        let loggedInAccountUseCase = MockAccountUseCase(isLoggedIn: false)
        let streamingInfoUseCase = MockStreamingInfoUseCase()
        let defaultConfigEntity = audioPlayerConfigEntity(node: anyAudioNode)
        let (sut, _, router) = makeSUT(
            configEntity: defaultConfigEntity,
            streamingInfoUseCase: streamingInfoUseCase,
            accountUseCase: loggedInAccountUseCase
        )
        sut.dispatch(.onViewDidLoad)
        
        sut.dispatch(.viewWillDisappear(reason: .systemPushedAnotherView))
        
        guard let playerHandler = defaultConfigEntity.playerHandler as? MockAudioPlayerHandler else {
            XCTFail("Expect to have mock audio player handler type: \(type(of: MockAudioPlayerHandler.self)), but got different type.")
            return
        }
        XCTAssertEqual(router.showNodesMiniPlayer_calledTimes, 0)
        XCTAssertEqual(playerHandler.pause_calledTimes, 0)
        XCTAssertEqual(playerHandler.closePlayer_calledTimes, 0)
    }
    
    // MARK: - initMiniPlayer
    
    @MainActor
    func tesInitMiniPlayer_whenNotLoggedIn_stopsPlayer() {
        let loggedInAccountUseCase = MockAccountUseCase(isLoggedIn: false)
        let streamingInfoUseCase = MockStreamingInfoUseCase()
        let defaultConfigEntity = audioPlayerConfigEntity(node: anyAudioNode)
        let (sut, _, router) = makeSUT(
            configEntity: defaultConfigEntity,
            streamingInfoUseCase: streamingInfoUseCase,
            accountUseCase: loggedInAccountUseCase
        )
        sut.dispatch(.onViewDidLoad)
        
        sut.dispatch(.initMiniPlayer)
        
        guard let playerHandler = defaultConfigEntity.playerHandler as? MockAudioPlayerHandler else {
            XCTFail("Expect to have mock audio player handler type: \(type(of: MockAudioPlayerHandler.self)), but got different type.")
            return
        }
        XCTAssertEqual(router.showNodesMiniPlayer_calledTimes, 0)
        XCTAssertEqual(playerHandler.pause_calledTimes, 1)
        XCTAssertEqual(playerHandler.closePlayer_calledTimes, 1)
        XCTAssertEqual(streamingInfoUseCase.stopServer_calledTimes, 1)
    }
    
    // MARK: - Analytics
    
    @MainActor
    func testAnalytics_onViewDidLoad_shouldTrackAudioPlayerIsActivatedEvent() {
        let tracker = MockTracker()
        let (sut, _, _) = makeSUT(
            configEntity: audioPlayerConfigEntity(node: anyAudioNode),
            tracker: tracker
        )
        
        sut.dispatch(.onViewDidLoad)
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [AudioPlayerIsActivatedEvent()])
    }
    
    @MainActor
    func testAnalytics_onShuffleActive_shouldTrackAudioPlayerShuffleEnabledEvent() {
        let tracker = MockTracker()
        let (sut, _, _) = makeSUT(
            configEntity: audioPlayerConfigEntity(node: anyAudioNode),
            tracker: tracker
        )
        
        sut.dispatch(.onShuffle(active: true))
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [AudioPlayerShuffleEnabledEvent()])
    }
    
    @MainActor
    func testAnalytics_onRepeatPressed_shouldTrackLoopAndRepeatOneEvents() {
        let tracker = MockTracker()
        let (sut, _, _) = makeSUT(
            configEntity: audioPlayerConfigEntity(node: anyAudioNode),
            tracker: tracker
        )
        
        sut.dispatch(.onRepeatPressed)
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [AudioPlayerLoopQueueEnabledEvent()])
        
        tracker.reset()
        
        sut.dispatch(.onRepeatPressed)
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [AudioPlayerLoopPlayingItemEnabledEvent()])
        
        tracker.reset()
        
        sut.dispatch(.onRepeatPressed)
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [])
    }
    
    @MainActor
    func testAnalytics_showPlaylist_shouldTrackQueueButtonPressedEvent() {
        let tracker = MockTracker()
        let (sut, _, _) = makeSUT(
            configEntity: audioPlayerConfigEntity(node: anyAudioNode),
            tracker: tracker
        )
        
        sut.dispatch(.showPlaylist)
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [AudioPlayerQueueButtonPressedEvent()])
    }
    
    @MainActor
    func testAnalytics_onChangeSpeedModePressed_shouldTrackSpeedChangeEvents() {
        let tracker = MockTracker()
        
        let (sut, _, _) = makeSUT(
            configEntity: audioPlayerConfigEntity(node: anyAudioNode),
            tracker: tracker
        )
        
        sut.dispatch(.onChangeSpeedModePressed)
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [AudioPlayerSpeedChangeOneAndHalfXEvent()]
        )
        
        tracker.reset()
        
        sut.dispatch(.onChangeSpeedModePressed)
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [AudioPlayerSpeedChange2XEvent()]
        )
        
        tracker.reset()
        
        sut.dispatch(.onChangeSpeedModePressed)
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [AudioPlayerSpeedChangeHalfXEvent()]
        )
        
        tracker.reset()
        
        sut.dispatch(.onChangeSpeedModePressed)
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [AudioPlayerSpeedChange1XEvent()]
        )
    }
    
    @MainActor
    func testAnalytics_onGoBackward_shouldTrackBackwardEvent() {
        let tracker = MockTracker()
        let (sut, _, _) = makeSUT(
            configEntity: audioPlayerConfigEntity(node: anyAudioNode),
            tracker: tracker
        )
        sut.dispatch(.onGoBackward)
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [AudioPlayerBack15SecondsEvent()]
        )
    }

    @MainActor
    func testAnalytics_onGoForward_shouldTrackForwardEvent() {
        let tracker = MockTracker()
        let (sut, _, _) = makeSUT(
            configEntity: audioPlayerConfigEntity(node: anyAudioNode),
            tracker: tracker
        )
        sut.dispatch(.onGoForward)
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [AudioPlayerForward15SecondsEvent()]
        )
    }
    
    @MainActor
    func testViewWillDisappear_whenUserInitiatedDismissalAndNetworkIsConnected_shouldInitMiniPlayer() {
        let mockNetworkMonitor = MockNetworkMonitorUseCase(connected: true)
        let (sut, _, router) = makeSUT(
            configEntity: audioPlayerConfigEntity(
                node: anyAudioNode,
                relatedFiles: ["File1"]
            ),
            accountUseCase: MockAccountUseCase(isLoggedIn: true),
            networkMonitorUseCase: mockNetworkMonitor
        )
        
        sut.dispatch(.viewWillDisappear(reason: .userInitiatedDismissal))
        
        XCTAssertEqual(router.showMiniPlayer_calledTimes, 1)
    }
    
    @MainActor
    func testViewWillDisappear_whenUserInitiatedDismissalAndNetworkIsDisconnected_shouldInitMiniPlayerWithoutStoppingAudio() {
        let mockNetworkMonitor = MockNetworkMonitorUseCase(connected: false)
        let (sut, _, router) = makeSUT(
            configEntity: audioPlayerConfigEntity(
                node: anyAudioNode,
                relatedFiles: ["File1"]
            ),
            networkMonitorUseCase: mockNetworkMonitor
        )
        
        sut.dispatch(.viewWillDisappear(reason: .userInitiatedDismissal))
        
        XCTAssertEqual(router.showMiniPlayer_calledTimes, 1)
    }
    
    // MARK: - Helpers
    
    @MainActor
    private func makeOnlineSUT() -> (sut: AudioPlayerViewModel, playbackUseCase: MockPlaybackContinuationUseCase, playerHandler: MockAudioPlayerHandler, router: MockAudioPlayerViewRouter) {
        let playerHandler = MockAudioPlayerHandler()
        let (sut, playbackUseCase, router) = makeSUT(
            configEntity: AudioPlayerConfigEntity(
                node: MEGANode(),
                isFolderLink: false,
                fileLink: "",
                playerHandler: playerHandler
            ),
            nodeInfoUseCase: NodeInfoUseCase(nodeInfoRepository: MockNodeInfoRepository()),
            streamingInfoUseCase: StreamingInfoUseCase(streamingInfoRepository: MockStreamingInfoRepository())
        )
        return (sut, playbackUseCase, playerHandler, router)
    }
    
    @MainActor
    private func makeOfflineSUT() -> (sut: AudioPlayerViewModel, router: MockAudioPlayerViewRouter) {
        let playerHandler = MockAudioPlayerHandler()
        let (sut, _, router) = makeSUT(
            configEntity: AudioPlayerConfigEntity(
                fileLink: "file_path",
                playerHandler: playerHandler
            ),
            offlineInfoUseCase: OfflineFileInfoUseCase(offlineInfoRepository: MockOfflineInfoRepository())
        )
        return (sut, router)
    }
    
    @MainActor
    private func makeSUT(
        configEntity: AudioPlayerConfigEntity,
        tracker: some AnalyticsTracking = MockTracker(),
        nodeInfoUseCase: (any NodeInfoUseCaseProtocol)? = nil,
        streamingInfoUseCase: (any StreamingInfoUseCaseProtocol)? = nil,
        offlineInfoUseCase: (any OfflineFileInfoUseCaseProtocol)? = nil,
        accountUseCase: any AccountUseCaseProtocol = MockAccountUseCase(),
        networkMonitorUseCase: any NetworkMonitorUseCaseProtocol = MockNetworkMonitorUseCase(),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: AudioPlayerViewModel, playbackContinuationUseCase: MockPlaybackContinuationUseCase, router: MockAudioPlayerViewRouter) {
        let mockPlaybackContinuationUseCase = MockPlaybackContinuationUseCase()
        let mockAudioPlayerUseCase = MockAudioPlayerUseCase()
        let router = MockAudioPlayerViewRouter()
        let sut = AudioPlayerViewModel(
            configEntity: configEntity,
            router: router,
            nodeInfoUseCase: nodeInfoUseCase,
            streamingInfoUseCase: streamingInfoUseCase,
            offlineInfoUseCase: offlineInfoUseCase,
            playbackContinuationUseCase: mockPlaybackContinuationUseCase,
            audioPlayerUseCase: mockAudioPlayerUseCase,
            accountUseCase: accountUseCase,
            networkMonitorUseCase: networkMonitorUseCase,
            tracker: tracker
        )
        trackForMemoryLeaks(on: sut, timeoutNanoseconds: 1_000_000_000, file: file, line: line)
        return (sut, mockPlaybackContinuationUseCase, router)
    }
    
    @MainActor
    private func simulateUserViewDidLoadWithNewInstane(audioNode: MockNode) -> (sut: AudioPlayerViewModel, playbackUseCase: MockPlaybackContinuationUseCase, playerHandler: MockAudioPlayerHandler, router: MockAudioPlayerViewRouter) {
        let configEntity = audioPlayerConfigEntity(node: audioNode)
        let (sut, playbackUseCase, router) = makeSUT(
            configEntity: configEntity,
            nodeInfoUseCase: NodeInfoUseCase(nodeInfoRepository: MockNodeInfoRepository()),
            streamingInfoUseCase: StreamingInfoUseCase(streamingInfoRepository: MockStreamingInfoRepository())
        )
        sut.dispatch(.onViewDidLoad)
        return (sut, playbackUseCase, configEntity.playerHandler as! MockAudioPlayerHandler, router)
    }
    
    @MainActor
    private func assert(
        _ viewModel: AudioPlayerViewModel,
        when action: (AudioPlayerViewModel) -> Void,
        shouldInvokeCommands expectedCommands: [AudioPlayerViewModel.Command],
        line: UInt = #line
    ) {
        var invokedCommands =  [AudioPlayerViewModel.Command]()
        viewModel.invokeCommand = { invokedCommands.append($0) }
        
        action(viewModel)
        
        XCTAssertEqual(invokedCommands, expectedCommands, line: line)
    }
    
    private var testItem: AudioPlayerItem {
        AudioPlayerItem(
            name: "test-name",
            url: URL(string: "any-url")!,
            node: MockNode(handle: 1, fingerprint: "test-fingerprint")
        )
    }
    
    private func audioPlayerConfigEntity(node: MockNode, isFolderLink: Bool = false, relatedFiles: [String]? = nil, fileLink: String? = nil) -> AudioPlayerConfigEntity {
        let playerHandler = MockAudioPlayerHandler()
        return AudioPlayerConfigEntity(
            node: node,
            isFolderLink: isFolderLink,
            fileLink: fileLink,
            relatedFiles: relatedFiles,
            playerHandler: playerHandler,
        )
    }
    
    private func assertThatCleanPlayerStateForReuse(on playerHandler: MockAudioPlayerHandler, sut: AudioPlayerViewModel, file: StaticString = #filePath, line: UInt = #line) throws {
        let player = try XCTUnwrap(playerHandler.currentPlayer(), file: file, line: line)
        assertThatRemovePreviousQueuedTrackInPlayer(on: player, file: file, line: line)
        assertThatRefreshPlayerListener(on: player, sut: sut, file: file, line: line)
    }
    
    private func assertThatRemovePreviousQueuedTrackInPlayer(on player: AudioPlayer, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertNil(player.queuePlayer, file: file, line: line)
        XCTAssertTrue(player.tracks.isEmpty, file: file, line: line)
    }
    
    private func assertThatRefreshPlayerListener(on player: AudioPlayer, sut: AudioPlayerViewModel, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(player.observersListenerManager.listeners.isEmpty, file: file, line: line)
        XCTAssertTrue(player.observersListenerManager.listeners.notContains(where: { $0 as! AnyHashable == sut as! AnyHashable }), file: file, line: line)
    }
    
    private var anyAudioNode: MockNode {
        MockNode(handle: 1, name: "first-audio.mp3", nodeType: .file)
    }
}
