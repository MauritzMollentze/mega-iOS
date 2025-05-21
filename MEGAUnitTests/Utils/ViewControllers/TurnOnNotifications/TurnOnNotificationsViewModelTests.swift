@testable import MEGA

import MEGAAssets
import MEGADomain
import MEGADomainMock
import MEGAL10n
import MEGAPreference
import XCTest

final class TurnOnNotificationsViewModelTests: XCTestCase {
    
    let mockRouter = MockTurnOnNotificationsViewRouter()
    let mockPreference = MockPreferenceUseCase()
    
    @MainActor func testAction_onViewLoaded_configView() {
        let sut = TurnOnNotificationsViewModel(router: mockRouter,
                                               accountUseCase: MockAccountUseCase(isLoggedIn: true))
        sut.dispatch(.onViewLoaded)
        
        let title = Strings.Localizable.Dialog.TurnOnNotifications.Label.title
        let description = Strings.Localizable.Dialog.TurnOnNotifications.Label.description
        let stepOne = Strings.Localizable.Dialog.TurnOnNotifications.Label.stepOne
        let stepTwo = Strings.Localizable.Dialog.TurnOnNotifications.Label.stepTwo
        let stepThree = Strings.Localizable.Dialog.TurnOnNotifications.Label.stepThree
        let stepFour = Strings.Localizable.Dialog.TurnOnNotifications.Label.stepFour
        
        let expectedNotificationsModel = TurnOnNotificationsModel(headerImage: MEGAAssets.UIImage.groupChat,
                                                                  title: title,
                                                                  description: description,
                                                                  stepOneImage: MEGAAssets.UIImage.openSettings,
                                                                  stepOne: stepOne,
                                                                  stepTwoImage: MEGAAssets.UIImage.tapNotifications,
                                                                  stepTwo: stepTwo,
                                                                  stepThreeImage: MEGAAssets.UIImage.tapMega,
                                                                  stepThree: stepThree,
                                                                  stepFourImage: MEGAAssets.UIImage.allowNotifications,
                                                                  stepFour: stepFour,
                                                                  openSettingsTitle: Strings.Localizable.Dialog.TurnOnNotifications.Button.primary,
                                                                  dismissTitle: Strings.Localizable.dismiss)
        test(viewModel: sut, action: .onViewLoaded, expectedCommands: [.configView(expectedNotificationsModel)])
    }
    
    @MainActor func testAction_openSettings() {
        let sut = TurnOnNotificationsViewModel(router: mockRouter,
                                               accountUseCase: MockAccountUseCase(isLoggedIn: true))
        test(viewModel: sut, action: .openSettings, expectedCommands: [])
        XCTAssertEqual(mockRouter.openSettings_calledTimes, 1)
    }
    
    @MainActor func testAction_dismiss() {
        let sut = TurnOnNotificationsViewModel(router: mockRouter,
                                               accountUseCase: MockAccountUseCase(isLoggedIn: true))
        test(viewModel: sut, action: .dismiss, expectedCommands: [])
        XCTAssertEqual(mockRouter.dismiss_calledTimes, 1)
    }
    
    @MainActor
    func testShoudlShowTurnOnNotifications_moreThanSevenDaysHasPassed() {
        mockPreference.dict[PreferenceKeyEntity.lastDateTurnOnNotificationsShowed.rawValue] = Date.init(timeIntervalSince1970: 0)
        let sut = TurnOnNotificationsViewModel(router: mockRouter, preferenceUseCase: mockPreference,
                                               accountUseCase: MockAccountUseCase(isLoggedIn: false))
        XCTAssertFalse(sut.shouldShowTurnOnNotifications())
    }
    
    @MainActor
    func testShoudlShowTurnOnNotifications_moreThanSevenDaysHasPassed_userLoggedIn() {
        mockPreference.dict[PreferenceKeyEntity.lastDateTurnOnNotificationsShowed.rawValue] = Date.init(timeIntervalSince1970: 0)
        let sut = TurnOnNotificationsViewModel(router: mockRouter, preferenceUseCase: mockPreference,
                                               accountUseCase: MockAccountUseCase(isLoggedIn: true))
        XCTAssertTrue(sut.shouldShowTurnOnNotifications())
    }
    
    @MainActor
    func testShoudlShowTurnOnNotifications_lessThanSevenDaysHasPassed() {
        mockPreference.dict[PreferenceKeyEntity.lastDateTurnOnNotificationsShowed.rawValue] = Date()
        let sut = TurnOnNotificationsViewModel(router: mockRouter, preferenceUseCase: mockPreference,
                                               accountUseCase: MockAccountUseCase(isLoggedIn: true))
        XCTAssertFalse(sut.shouldShowTurnOnNotifications())
    }
    
    @MainActor
    func testShoudlShowTurnOnNotifications_equalOrMoreThanThreeTimesShown() {
        mockPreference.dict[PreferenceKeyEntity.timesTurnOnNotificationsShowed.rawValue] = 3
        let sut = TurnOnNotificationsViewModel(router: mockRouter, preferenceUseCase: mockPreference,
                                               accountUseCase: MockAccountUseCase(isLoggedIn: true))
        XCTAssertFalse(sut.shouldShowTurnOnNotifications())
    }
    
    @MainActor
    func testShoudlShowTurnOnNotifications_lessThanThreeTimesShown() {
        mockPreference.dict[PreferenceKeyEntity.timesTurnOnNotificationsShowed.rawValue] = 2
        let sut = TurnOnNotificationsViewModel(router: mockRouter, preferenceUseCase: mockPreference,
                                               accountUseCase: MockAccountUseCase(isLoggedIn: false))
        XCTAssertFalse(sut.shouldShowTurnOnNotifications())
    }
    
    @MainActor
    func testShoudlShowTurnOnNotifications_lessThanThreeTimesShown_userLoggedI() {
        mockPreference.dict[PreferenceKeyEntity.timesTurnOnNotificationsShowed.rawValue] = 2
        let sut = TurnOnNotificationsViewModel(router: mockRouter, preferenceUseCase: mockPreference,
                                               accountUseCase: MockAccountUseCase(isLoggedIn: true))
        XCTAssertTrue(sut.shouldShowTurnOnNotifications())
    }
}

final class MockTurnOnNotificationsViewRouter: TurnOnNotificationsViewRouting {
    var openSettings_calledTimes = 0
    var dismiss_calledTimes = 0
    
    func dismiss() {
        dismiss_calledTimes += 1
    }
    
    func openSettings() {
        openSettings_calledTimes += 1
    }
}
