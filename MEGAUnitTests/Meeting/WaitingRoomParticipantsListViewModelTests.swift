@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAPresentationMock
import XCTest

final class WaitingRoomParticipantsListViewModelTests: XCTestCase {
    func testAction_admitAllTappedAndParticipantsInWaitingRoom_allowUsersShouldBeCalled() {
        let router = MockWaitingRoomParticipantsListRouter()
        let call = CallEntity(waitingRoom: WaitingRoomEntity(sessionClientIds: [100, 101]))
        let callUseCase = MockCallUseCase(call: call)
        let viewModel = WaitingRoomParticipantsListViewModel(
            router: router,
            call: call,
            callUseCase: callUseCase,
            chatRoomUseCase: MockChatRoomUseCase()
        )
        
        viewModel.admitAllTapped()
        XCTAssertTrue(callUseCase.allowUsersJoinCall_CalledTimes == 1)
        XCTAssertTrue(router.dismiss_calledTimes == 1)
    }
    
    func testAction_admitAllTappedAndNoParticipantsInWaitingRoom_allowUsersShouldNotBeCalled() {
        let router = MockWaitingRoomParticipantsListRouter()
        let callUseCase = MockCallUseCase()
        let viewModel = WaitingRoomParticipantsListViewModel(
            router: router,
            call: CallEntity(),
            callUseCase: callUseCase,
            chatRoomUseCase: MockChatRoomUseCase()
        )
        
        viewModel.admitAllTapped()
        XCTAssertTrue(callUseCase.allowUsersJoinCall_CalledTimes == 0)
        XCTAssertTrue(router.dismiss_calledTimes == 0)
    }
    
    func testAction_closeTapped_dismissShouldBeCalled() {
        let router = MockWaitingRoomParticipantsListRouter()
        let viewModel = WaitingRoomParticipantsListViewModel(
            router: router,
            call: CallEntity(),
            callUseCase: MockCallUseCase(),
            chatRoomUseCase: MockChatRoomUseCase()
        )
        
        viewModel.closeTapped()
        XCTAssertTrue(router.dismiss_calledTimes == 1)
    }
}
