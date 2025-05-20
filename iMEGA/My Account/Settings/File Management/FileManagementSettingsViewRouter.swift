import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGAPreference
import MEGARepo
import Settings
import SwiftUI

protocol FileManagementRouter: Routing {
    func navigateToFileVersioning()
    func navigateToRubbishBinSettings()
}

final class FileManagementSettingsViewRouter: FileManagementRouter {
    private weak var baseViewController: UIViewController?
    private weak var navigationController: UINavigationController?
    
    init(navigationController: UINavigationController?) {
        self.navigationController = navigationController
    }
    
    func build() -> UIViewController {
        if DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .newSetting) {
            let viewModel = FileManagementViewModel(
                cacheUseCase: CacheUseCase(cacheRepository: CacheRepository.newRepo),
                offlineUseCase: OfflineUseCase(
                    fileSystemRepository: FileSystemRepository.sharedRepo,
                    offlineFilesRepository: OfflineFilesRepository.newRepo,
                    nodeTransferRepository: NodeTransferRepository.newRepo
                ),
                mobileDataUseCase: MobileDataUseCase(preferenceUseCase: PreferenceUseCase.default),
                fileVersionsUseCase: FileVersionsUseCase(repo: FileVersionsRepository.newRepo),
                accountUseCase: AccountUseCase(repository: AccountRepository.newRepo),
                removeOfflineFilesCompletion: removeOfflineFilesCompletion,
                navigateToRubbishBinSettings: navigateToRubbishBinSettings,
                navigateToFileVersioning: navigateToFileVersioning
            )
            let hostingVC = UIHostingController(rootView: FileManagementView(viewModel: viewModel))
            hostingVC.navigationItem.backButtonTitle = ""
            baseViewController = hostingVC
            return hostingVC
        } else {
            let vc = UIStoryboard(name: "Settings", bundle: nil).instantiateViewController(withIdentifier: "FileManagementTableViewControllerID")
            baseViewController = vc
            return vc
        }
    }
    
    func start() {
        navigationController?.pushViewController(build(), animated: true)
    }
    
    func navigateToFileVersioning() {
        guard let navigationController else { return }
        FileVersioningViewRouter(navigationController: navigationController).start()
    }
    
    func navigateToRubbishBinSettings() {
        guard let navigationController else { return }
        RubbishBinSettingViewRouter(navigationController: navigationController).start()
    }
    
    func removeOfflineFilesCompletion() {
        let offlineUseCase = OfflineUseCase(
            fileSystemRepository: FileSystemRepository.sharedRepo,
            offlineFilesRepository: OfflineFilesRepository.newRepo,
            nodeTransferRepository: NodeTransferRepository.newRepo
        )
        
        offlineUseCase.removeAllStoredFiles()
        QuickAccessWidgetManager.reloadWidgetContentOfKind(kind: MEGAOfflineQuickAccessWidget)
    }
}
