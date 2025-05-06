import MEGADomain
import MEGAL10n
import MEGAPreference

@objc enum TabType: Int, CaseIterable {
    case cloudDrive
    case cameraUploads
    case home
    case chat
    case sharedItems
}

@objc final class TabManager: NSObject {
    @PreferenceWrapper(key: PreferenceKeyEntity.launchTab, defaultValue: TabType.home.rawValue, useCase: PreferenceUseCase.default)
    private static var launchTabPreference: Int
    @PreferenceWrapper(key: PreferenceKeyEntity.launchTabSelected, defaultValue: false, useCase: PreferenceUseCase.default)
    private static var launchTabSelected: Bool
    @PreferenceWrapper(key: PreferenceKeyEntity.launchTabSuggested, defaultValue: false, useCase: PreferenceUseCase.default)
    private static var launchTabDialogAlreadySuggested: Bool

    @objc static let avaliableTabs = TabType.allCases.count
    
    @objc static func setPreferenceTab(tab: Tab) {
        launchTabPreference = tab.tabType.rawValue
        launchTabSelected = true
    }
    
    @objc static func getPreferenceTab() -> Tab {
        guard let tabType = TabType(rawValue: launchTabPreference) else {
            return Tab(tabType: TabType.home)
        }
        return Tab(tabType: tabType)
    }
    
    @objc static func isLaunchTabSelected() -> Bool {
        launchTabSelected
    }
    
    @objc static func isLaunchTabDialogAlreadySuggested() -> Bool {
        launchTabDialogAlreadySuggested
    }
    
    @objc static func setLaunchTabDialogAlreadyAsSuggested() {
        launchTabDialogAlreadySuggested = true
    }
}

@objc final class Tab: NSObject {
    @objc let tabType: TabType
    
    @objc init(tabType: TabType) {
        self.tabType = tabType
    }
    
    @objc var icon: UIImage? {
        switch tabType {
        case .cloudDrive: UIImage.cloudDriveIcon
        case .cameraUploads: UIImage.cameraUploadsIcon
        case .home: UIImage.home
        case .chat: UIImage.chatIcon
        case .sharedItems: UIImage.sharedItemsIcon
        }
    }
    
    @objc var title: String {
        switch tabType {
        case .cloudDrive: Strings.Localizable.cloudDrive
        case .cameraUploads: Strings.Localizable.General.cameraUploads
        case .home: Strings.Localizable.home
        case .chat: Strings.Localizable.chat
        case .sharedItems: Strings.Localizable.sharedItems
        }
    }
}
