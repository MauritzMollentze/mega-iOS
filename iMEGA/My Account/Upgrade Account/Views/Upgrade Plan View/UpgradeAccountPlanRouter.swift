import Accounts
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADesignToken
import MEGADomain
import Settings
import SwiftUI

protocol UpgradeAccountPlanRouting: Routing {
    func showTermsAndPolicies()
    var isFromAds: Bool { get }
}

final class UpgradeAccountPlanRouter: NSObject, UpgradeAccountPlanRouting {
    private weak var presenter: UIViewController?
    private weak var baseViewController: UIViewController?
    private var accountDetails: AccountDetailsEntity
    private let accountUseCase: any AccountUseCaseProtocol
    private let viewType: UpgradeAccountPlanViewType
    let isFromAds: Bool
    
    init(
        presenter: UIViewController?,
        accountDetails: AccountDetailsEntity,
        viewType: UpgradeAccountPlanViewType = .upgrade,
        isFromAds: Bool = false
    ) {
        self.presenter = presenter
        self.accountDetails = accountDetails
        self.viewType = viewType
        self.isFromAds = isFromAds
        accountUseCase = AccountUseCase(repository: AccountRepository.newRepo)
    }
    
    func build() -> UIViewController {
        let viewModel = UpgradeAccountPlanViewModel(
            accountDetails: accountDetails,
            accountUseCase: accountUseCase,
            purchaseUseCase: AccountPlanPurchaseUseCase(repository: AccountPlanPurchaseRepository.newRepo),
            subscriptionsUseCase: SubscriptionsUseCase(repo: SubscriptionsRepository.newRepo),
            viewType: viewType,
            router: self,
            appVersion: AppMetaDataFactory(bundle: .main).make().currentAppVersion
        )
        
        let accountsConfigs = AccountsConfig(onboardingViewAssets: AccountsConfig.OnboardingViewAssets(
            primaryTextColor: TokenColors.Text.primary.swiftUI,
            primaryGrayTextColor: TokenColors.Text.primary.swiftUI,
            secondaryTextColor: TokenColors.Text.secondary.swiftUI,
            subMessageBackgroundColor: TokenColors.Background.blur.swiftUI,
            headerForegroundSelectedColor: TokenColors.Text.accent.swiftUI,
            headerForegroundUnSelectedColor: TokenColors.Border.strong.swiftUI,
            headerBackgroundColor: TokenColors.Background.surface1.swiftUI,
            headerStrokeColor: TokenColors.Border.strong.swiftUI,
            backgroundColor: TokenColors.Background.page.swiftUI,
            currentPlanTagColor: TokenColors.Notifications.notificationWarning.swiftUI,
            recommendedPlanTagColor: TokenColors.Notifications.notificationInfo.swiftUI))
        
        let upgradeAccountPlanView = UpgradeAccountPlanView(viewModel: viewModel, accountConfigs: accountsConfigs)
        let hostingController = UIHostingController(rootView: upgradeAccountPlanView)
        hostingController.isModalInPresentation = true
        
        return hostingController
    }
    
    func start() {
        let viewController = build()
        baseViewController = viewController
        presenter?.present(viewController, animated: true)
    }
    
    func showTermsAndPolicies() {
        TermsAndPoliciesRouter(
            accountUseCase: accountUseCase,
            presenter: baseViewController
        ).start()
    }
}
