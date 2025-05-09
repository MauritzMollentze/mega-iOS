import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADesignToken
import MEGADomain
import SwiftUI

public struct AppLoadingViewRouter: Routing {
    public func start() { }
    
    let appLoadComplete: ( @MainActor @Sendable () -> Void)?
    
    public init (appLoadComplete: ( @MainActor @Sendable () -> Void)? = nil) {
        self.appLoadComplete = appLoadComplete
    }
    
    public func build() -> UIViewController {
        let viewModel = AppLoadingViewModel(
            appLoadingUseCase: AppLoadingUseCase(
                requestStatesRepository: RequestStatesRepository.newRepo,
                appLoadingRepository: AppLoadingRepository.newRepo
            ),
            requestStatProgressUseCase: RequestStatProgressUseCase(repo: EventRepository.newRepo),
            appLoadComplete: appLoadComplete
        )
        let view = AppLoadingView(viewModel: viewModel)
        let viewController = UIHostingController(rootView: view)
        viewController.view.backgroundColor = TokenColors.Background.page
        return viewController
    }
}
