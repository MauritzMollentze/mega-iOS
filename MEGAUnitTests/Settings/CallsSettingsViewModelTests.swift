@testable import MEGA

import MEGADomain
import MEGADomainMock
import MEGAPreference
import Testing

struct CallsSettingsViewModelTests {
    static let arguments: [Bool] = [true, false]
    
    @Test("Enable/Disable Sound Notifications of Legacy Calls Setting View", arguments: arguments)
    func updateSoundNotificationStatus(with status: Bool) {
        let viewModel = CallsSettingsViewModel(preferenceUseCase: MockPreferenceUseCase(dict: [PreferenceKeyEntity.callsSoundNotification.rawValue: false]), analyticsEventUseCase: MockAnalyticsEventUseCase())
        viewModel.callsSoundNotificationPreference = status
        
        #expect(viewModel.callsSoundNotificationPreference == status)
    }
    
    @Test("Enable/Disable Sound Notifications of New Calls Setting View", arguments: arguments)
    func updateSettingToggle(with status: Bool) {
        let viewModel = CallsSettingsViewModel(preferenceUseCase: MockPreferenceUseCase(dict: [PreferenceKeyEntity.callsSoundNotification.rawValue: false]), analyticsEventUseCase: MockAnalyticsEventUseCase())
        viewModel.toggle(status)
        
        #expect(viewModel.isEnabled == status)
        #expect(viewModel.callsSoundNotificationPreference == status)
    }
}
