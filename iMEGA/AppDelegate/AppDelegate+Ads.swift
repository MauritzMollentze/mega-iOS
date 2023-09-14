import MEGADomain
import MEGASDKRepo
import SwiftUI

extension AppDelegate {
    @objc func isAdsMainTabBarRootView() -> Bool {
        window.isKind(of: UIHostingController<AdsSlotView<MainTabBarWrapper>>.self)
    }
    
    @objc func adsMainTabBarViewController(_ tabBar: MainTabBarController) -> UIViewController {
        let adsSlot = AdsSlotEntity.files
        let viewModel = AdsSlotViewModel(adsUseCase: AdsUseCase(repository: AdsRepository.newRepo),
                                         accountUseCase: AccountUseCase(repository: AccountRepository.newRepo),
                                         adsSlot: adsSlot)
        let adsSlotView = AdsSlotView(viewModel: viewModel) {
            MainTabBarWrapper(mainTabBar: tabBar)
        }
        return UIHostingController(rootView: adsSlotView)
    }
}
