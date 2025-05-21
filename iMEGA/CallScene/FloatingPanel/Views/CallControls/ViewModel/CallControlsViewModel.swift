import Chat
import Combine
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAssets
import MEGADomain
import MEGAL10n
import MEGAPermissions

@MainActor
final class CallControlsViewModel: CallControlsViewModelProtocol {
    
    private let router: any MeetingFloatingPanelRouting
    private let menuPresenter: ([ActionSheetAction]) -> Void
    private var chatRoom: ChatRoomEntity
    
    private let callUseCase: any CallUseCaseProtocol
    private let callUpdateUseCase: any CallUpdateUseCaseProtocol
    private let localVideoUseCase: any CallLocalVideoUseCaseProtocol
    private let audioSessionUseCase: any AudioSessionUseCaseProtocol
    private weak var containerViewModel: MeetingContainerViewModel?
    
    private let permissionHandler: any DevicePermissionsHandling
    private let callController: any CallControllerProtocol
    private let accountUseCase: any AccountUseCaseProtocol
    private let notificationCenter: NotificationCenter
    private let audioRouteChangeNotificationName: Notification.Name
    private let layoutUpdateChannel: ParticipantLayoutUpdateChannel
    private let cameraSwitcher: any CameraSwitching
    private let raiseHandBadgeStoring: any RaiseHandBadgeStoring
    private let tracker: any AnalyticsTracking

    @Published var micEnabled: Bool = false
    @Published var cameraEnabled: Bool = false
    @Published var speakerEnabled: Bool = false
    @Published var routeViewVisible: Bool = false

    var showRaiseHandBadge: Bool = false
    
    init(
        router: some MeetingFloatingPanelRouting,
        menuPresenter: @escaping ([ActionSheetAction]) -> Void,
        chatRoom: ChatRoomEntity,
        callUseCase: some CallUseCaseProtocol,
        callUpdateUseCase: some CallUpdateUseCaseProtocol,
        localVideoUseCase: some CallLocalVideoUseCaseProtocol,
        containerViewModel: MeetingContainerViewModel? = nil,
        audioSessionUseCase: some AudioSessionUseCaseProtocol,
        permissionHandler: some DevicePermissionsHandling,
        callController: some CallControllerProtocol,
        notificationCenter: NotificationCenter,
        audioRouteChangeNotificationName: Notification.Name,
        accountUseCase: some AccountUseCaseProtocol,
        layoutUpdateChannel: ParticipantLayoutUpdateChannel,
        cameraSwitcher: some CameraSwitching,
        raiseHandBadgeStoring: some RaiseHandBadgeStoring,
        tracker: some AnalyticsTracking
    ) {
        self.router = router
        self.menuPresenter = menuPresenter
        self.chatRoom = chatRoom
        self.callUseCase = callUseCase
        self.callUpdateUseCase = callUpdateUseCase
        self.localVideoUseCase = localVideoUseCase
        self.containerViewModel = containerViewModel
        self.permissionHandler = permissionHandler
        self.audioSessionUseCase = audioSessionUseCase
        self.callController = callController
        self.notificationCenter = notificationCenter
        self.audioRouteChangeNotificationName = audioRouteChangeNotificationName
        self.accountUseCase = accountUseCase
        self.layoutUpdateChannel = layoutUpdateChannel
        self.cameraSwitcher = cameraSwitcher
        self.raiseHandBadgeStoring = raiseHandBadgeStoring
        self.tracker = tracker
        
        guard let call = callUseCase.call(for: chatRoom.chatId) else {
            MEGALogError("Error initialising call actions, call does not exists")
            return
        }
        
        micEnabled = call.hasLocalAudio
        cameraEnabled = call.hasLocalVideo
        
        registerForAudioRouteChanges()
        checkRouteViewAvailability()
        monitorOnCallUpdate()
        updateSpeakerIcon()
    }
    
    // MARK: - Public
    
    @MainActor func endCallTapped() async {
        manageEndCall()
    }
    
    func toggleCameraTapped() async {
        await toggleCamera()
    }
    
    func toggleMicTapped() async {
        await toggleMic()
    }
    
    func toggleSpeakerTapped() {
        toggleSpeaker()
    }
    
    func switchCameraTapped() async {
        await switchCamera()
    }
    
    func checkRaiseHandBadge() async {
        showRaiseHandBadge = await raiseHandBadgeStoring.shouldPresentRaiseHandBadge()
    }
    
    func moreButtonTapped() async {
        tracker.trackAnalyticsEvent(with: CallUIMoreButtonPressedEvent())
        menuPresenter(moreMenuActions)
        if showRaiseHandBadge {
            await raiseHandBadgeStoring.incrementRaiseHandBadgePresented()
            await checkRaiseHandBadge()
        }
    }
    
    // MARK: - Private
    private func toggleSpeaker() {
        if speakerEnabled {
            audioSessionUseCase.disableLoudSpeaker()
        } else {
            audioSessionUseCase.enableLoudSpeaker()
        }
    }
    
    private func updateSpeakerIcon() {
        let currentSelectedPort = audioSessionUseCase.currentSelectedAudioPort
        let isBluetoothAvailable = audioSessionUseCase.isBluetoothAudioRouteAvailable
        MEGALogDebug("[Calls Controls] updating speaker info with selected port \(currentSelectedPort) bluetooth available \(isBluetoothAvailable)")
        speakerEnabled = switch currentSelectedPort {
        case .unknown, .builtInReceiver, .other:
            false
        case .builtInSpeaker, .headphones:
            true
        }
    }
    
    private var isNotOneToOneCall: Bool {
        chatRoom.chatType != .oneToOne
    }
    
    // we do not show raise hand functionality in one-to-one calls
    var showMoreButton: Bool {
        moreButtonVisibleInCallControls(
            isOneToOne: !isNotOneToOneCall
        )
    }
    
    private func switchLayout(
        gallery: Bool,
        enabled: Bool
    ) -> ActionSheetAction {
        .init(
            title: gallery ? Strings.Localizable.Chat.Call.ContextMenu.switchToMainView : Strings.Localizable.Chat.Call.ContextMenu.switchToGrid,
            detail: nil,
            image: gallery ? MEGAAssets.UIImage.speakerView : MEGAAssets.UIImage.galleryView,
            enabled: layoutSwitchingEnabled,
            syncIconAndTextColor: true,
            style: .default,
            actionHandler: toggleLayoutAction
        )
    }
    
    private var layoutSwitchingEnabled: Bool {
        layoutUpdateChannel.layoutSwitchingEnabled?() ?? false
    }
    
    private var currentLayout: ParticipantsLayoutMode {
        layoutUpdateChannel.getCurrentLayout?() ?? .grid
    }
    
    private func toggleLayoutAction() {
        var layout = currentLayout
        layout.toggle()
        layoutUpdateChannel.updateLayout?(layout)
    }
    
    private func raiseOrLowerHand(raised: Bool) -> ActionSheetAction {
        .init(
            title: raised ? Strings.Localizable.Chat.Call.ContextMenu.lowerHand : Strings.Localizable.Chat.Call.ContextMenu.raiseHand,
            detail: nil,
            image: MEGAAssets.UIImage.callRaiseHand,
            syncIconAndTextColor: true,
            showNewFeatureBadge: showRaiseHandBadge,
            style: .default,
            actionHandler: { [weak self] in
                self?.signalHandAction(!raised)
            }
        )
    }
    
    private func signalHandAction(_ raise: Bool) {
        guard
            let call = callUseCase.call(for: chatRoom.chatId)
        else { return }
        
        Task { @MainActor in 
            MEGALogDebug("[CallControls] \(raise ? "raising" : "lowering") hand begin")
            do {
                if raise {
                    try await self.callUseCase.raiseHand(forCall: call)
                    tracker.trackAnalyticsEvent(with: CallRaiseHandEvent())
                } else {
                    try await self.callUseCase.lowerHand(forCall: call)
                    tracker.trackAnalyticsEvent(with: CallLowerHandEvent())
                }
                if showRaiseHandBadge {
                    await raiseHandBadgeStoring.saveRaiseHandBadgeAsPresented()
                    await checkRaiseHandBadge()
                }
                MEGALogDebug("[CallControls] \(raise ? "raised" : "lowered") hand successfully")
            } catch {
                MEGALogDebug("[CallControls] \(raise ? "raising" : "lowering") hand failed \(error)")
            }
        }
    }
    
    private var localUserHandIsRaiseCurrently: Bool {
        guard
            let call = callUseCase.call(for: chatRoom.chatId),
            let userId = accountUseCase.currentUserHandle
        else { return false }
        let raised = Set(call.raiseHandsList).contains(userId)
        MEGALogDebug("[CallControls] local user has raised hand: \(raised)")
        return raised
    }
    
    private var moreMenuActions: [ActionSheetAction] {
        [
            switchLayout(gallery: currentLayout == .grid, enabled: layoutSwitchingEnabled),
            raiseOrLowerHand(raised: localUserHandIsRaiseCurrently)
        ]
    }
    
    private func manageEndCall() {
        guard let call = callUseCase.call(for: chatRoom.chatId) else {
            MEGALogError("[CallControls] Error hanging call, call does not exists")
            return
        }
        if (chatRoom.chatType == .group || chatRoom.chatType == .meeting) && chatRoom.ownPrivilege == .moderator && call.numberOfParticipants > 1, let containerViewModel {
            router.showHangOrEndCallDialog(containerViewModel: containerViewModel)
        } else {
            callController.endCall(in: chatRoom, endForAll: false)
        }
    }
    
    private func toggleMic() async {
        if await permissionHandler.requestPermission(for: .audio) {
            callController.muteCall(in: chatRoom, muted: micEnabled)
            micEnabled.toggle()
        } else {
            router.showAudioPermissionError()
        }
    }
    
    private func toggleCamera() async {
        if await permissionHandler.requestPermission(for: .video) {
            do {
                if cameraEnabled {
                    try await localVideoUseCase.disableLocalVideo(for: chatRoom.chatId)
                } else {
                    try await localVideoUseCase.enableLocalVideo(for: chatRoom.chatId)
                }
                cameraEnabled.toggle()
            } catch {
                MEGALogDebug("[CallControls] Error enabling or disabling local video")
            }
        } else {
            router.showVideoPermissionError()
        }
    }
    
    private func switchCamera() async {
        if cameraEnabled {
            await cameraSwitcher.switchCamera()
        }
    }
    
    private func registerForAudioRouteChanges() {
        notificationCenter.addObserver(
            self,
            selector: #selector(audioRouteChanged(_:)),
            name: audioRouteChangeNotificationName,
            object: nil
        )
    }
    
    @objc private func audioRouteChanged(_ notification: Notification) {
        checkRouteViewAvailability()
        updateSpeakerIcon()
    }
    
    private func checkRouteViewAvailability() {
        routeViewVisible = audioSessionUseCase.isBluetoothAudioRouteAvailable
    }
    
    private func monitorOnCallUpdate() {
        let callUpdates = callUpdateUseCase.monitorOnCallUpdate()
        Task { [weak self] in
            for await call in callUpdates {
                self?.onCallUpdate(call)
            }
        }
    }
    
    private func onCallUpdate(_ call: CallEntity) {
        switch call.changeType {
        case .localAVFlags:
            micEnabled = call.hasLocalAudio
        default:
            break
        }
    }
}
