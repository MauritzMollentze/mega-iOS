@testable import MEGA
import MEGADomain
import MEGADomainMock
import XCTest

final class WaitingRoomViewModelTests: XCTestCase {
    func testMeetingTitle_onLoadWaitingRoom_shouldMatch() {
        let meetingTitle = "Test Meeting"
        let scheduledMeeting = ScheduledMeetingEntity(title: meetingTitle)
        let sut = WaitingRoomViewModel(scheduledMeeting: scheduledMeeting)
        
        XCTAssertEqual(sut.meetingTitle, meetingTitle)
    }
    
    func testMeetingDate_givenMeetingStartAndEndDate_shouldMatch() throws {
        let startDate = try XCTUnwrap(sampleDate(from: "21/09/2023 10:30"))
        let endDate = try XCTUnwrap(sampleDate(from: "21/09/2023 10:45"))
        let scheduledMeeting = ScheduledMeetingEntity(startDate: startDate, endDate: endDate)
        let sut = WaitingRoomViewModel(scheduledMeeting: scheduledMeeting)
        
        XCTAssertEqual(sut.createMeetingDate(), "Thu, 21 Sep ·10:30-10:45")
    }
    
    func testViewState_onLoadWaitingRoomAndIsGuest_shouldBeGuestJoinState() {
        let accountUseCase = MockAccountUseCase(isGuest: true)
        let sut = WaitingRoomViewModel(accountUseCase: accountUseCase)
        XCTAssertEqual(sut.viewState, .guestJoin)
    }
    
    func testViewState_onLoadWaitingRoomAndIsNotGuest_shouldBeWaitForHostToLetInJoinState() {
        let sut = WaitingRoomViewModel()
        XCTAssertEqual(sut.viewState, .waitForHostToLetIn)
    }
    
    func testSpeakerButton_onTapSpeakerButton_shouldDisableSpeakerButton() {
        let audioSessionUseCase = MockAudioSessionUseCase()
        let sut = WaitingRoomViewModel(audioSessionUseCase: audioSessionUseCase)
        
        sut.enableLoudSpeaker(enabled: false)
        
        XCTAssertEqual(audioSessionUseCase.disableLoudSpeaker_calledTimes, 1)
    }
    
    func testLeaveButton_didTapLeaveButton_shouldPresentLeaveAlert() {
        let router = MockWaitingRoomViewRouter()
        let sut = WaitingRoomViewModel(router: router)
        
        sut.leaveButtonTapped()
        
        XCTAssertEqual(router.showLeaveAlert_calledTimes, 1)
    }
    
    func testMeetingInfoButton_didTapMeetingInfoButton_shouldPresentMeetingInfo() {
        let router = MockWaitingRoomViewRouter()
        let sut = WaitingRoomViewModel(router: router)
        
        sut.infoButtonTapped()
        
        XCTAssertEqual(router.showMeetingInfo_calledTimes, 1)
    }
    
    func testCalculateVideoSize_portraitMode_shouldMatch() {
        let screenHeight = 424.0
        let sut = WaitingRoomViewModel()
        
        let videoSize = sut.calculateVideoSize(by: screenHeight)
        
        XCTAssertEqual(videoSize, calculateVideoSize(by: screenHeight, isLandscape: false))
    }
    
    func testCalculateVideoSize_landscapeMode_shouldMatch() {
        let screenHeight = 236.0
        let sut = WaitingRoomViewModel()
        sut.orientation = .landscapeLeft
        
        let videoSize = sut.calculateVideoSize(by: screenHeight)
        
        XCTAssertEqual(videoSize, calculateVideoSize(by: screenHeight, isLandscape: true))
    }
    
    func testCalculateBottomPanelHeight_portraitModeAndGuestJoin_shouldMatch() {
        let accountUseCase = MockAccountUseCase(isGuest: true)
        let sut = WaitingRoomViewModel(accountUseCase: accountUseCase)
                
        XCTAssertEqual(sut.calculateBottomPanelHeight(), 142.0)
    }
    
    func testCalculateBottomPanelHeight_portraitModeAndWaitForHostToLetIn_shouldMatch() {
        let sut = WaitingRoomViewModel()

        XCTAssertEqual(sut.calculateBottomPanelHeight(), 100.0)
    }
    
    func testCalculateBottomPanelHeight_landscapeModeAndGuestJoin_shouldMatch() {
        let accountUseCase = MockAccountUseCase(isGuest: true)
        let sut = WaitingRoomViewModel(accountUseCase: accountUseCase)
        sut.orientation = .landscapeLeft
                
        XCTAssertEqual(sut.calculateBottomPanelHeight(), 142.0)
    }
    
    func testCalculateBottomPanelHeight_landscapeModeAndWaitForHostToLetIn_shouldMatch() {
        let sut = WaitingRoomViewModel()
        sut.orientation = .landscapeLeft

        XCTAssertEqual(sut.calculateBottomPanelHeight(), 8.0)
    }
    
    // MARK: - Private methods.
    
    private func sampleDate(from string: String = "12/06/2023 09:10") -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy HH:mm"
        return dateFormatter.date(from: string)
    }
    
    private func calculateVideoSize(by screenHeight: CGFloat, isLandscape: Bool) -> CGSize {
        let videoAspectRatio = isLandscape ? 424.0 / 236.0 : 236.0 / 424.0
        let videoHeight = screenHeight - (isLandscape ? 66.0 : 332.0)
        let videoWidth = videoHeight * videoAspectRatio
        return CGSize(width: videoWidth, height: videoHeight)
    }
}

final class MockWaitingRoomViewRouter: WaitingRoomViewRouting {
    var dismiss_calledTimes = 0
    var showLeaveAlert_calledTimes = 0
    var showMeetingInfo_calledTimes = 0
    var showVideoPermissionError_calledTimes = 0
    var showAudioPermissionError_calledTimes = 0
    
    func dismiss() {
        dismiss_calledTimes += 1
    }
    
    func showLeaveAlert(leaveAction: @escaping () -> Void) {
        showLeaveAlert_calledTimes += 1
    }
    
    func showMeetingInfo() {
        showMeetingInfo_calledTimes += 1
    }
    
    func showVideoPermissionError() {
        showVideoPermissionError_calledTimes += 1
    }
    
    func showAudioPermissionError() {
        showAudioPermissionError_calledTimes += 1
    }
}