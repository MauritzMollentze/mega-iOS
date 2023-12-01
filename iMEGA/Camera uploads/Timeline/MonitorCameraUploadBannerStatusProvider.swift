import MEGADomain
import MEGAPermissions
import MEGASwift

struct MonitorCameraUploadBannerStatusProvider {
    
    private var monitorCameraUploadUseCase: any MonitorCameraUploadUseCaseProtocol
    private let networkMonitorUseCase: any NetworkMonitorUseCaseProtocol
    private let devicePermissionHandler: any DevicePermissionsHandling
    
    @PreferenceWrapper(key: .cameraUploadsCellularDataUsageAllowed, defaultValue: false)
    private var cameraUploadsUseCellularDataUsageAllowed: Bool
    
    init(monitorCameraUploadUseCase: some MonitorCameraUploadUseCaseProtocol,
         networkMonitorUseCase: some NetworkMonitorUseCaseProtocol,
         preferenceUseCase: some PreferenceUseCaseProtocol,
         devicePermissionHandler: some DevicePermissionsHandling) {
        self.monitorCameraUploadUseCase = monitorCameraUploadUseCase
        self.networkMonitorUseCase = networkMonitorUseCase
        self.devicePermissionHandler = devicePermissionHandler
        $cameraUploadsUseCellularDataUsageAllowed.useCase = preferenceUseCase
    }
    
    mutating func change(monitorCameraUploadUseCase: some MonitorCameraUploadUseCaseProtocol) {
        self.monitorCameraUploadUseCase = monitorCameraUploadUseCase
    }
        
    func monitorCameraUploadStatusSequence() -> AnyAsyncSequence<CameraUploadBannerStatusViewStates> {
        monitorCameraUploadUseCase
            .monitorUploadStatus
            .compactMap { uploadStatsResult -> CameraUploadBannerStatusViewStates?  in
                switch uploadStatsResult {
                case .success(let uploadStats):
                    return map(uploadStats: uploadStats)
                case .failure:
                    return nil
                }
            }
            .eraseToAnyAsyncSequence()
    }
    
    private func map(uploadStats: CameraUploadStatsEntity) -> CameraUploadBannerStatusViewStates? {
        guard uploadStats.pendingFilesCount == 0 else {
            
            if networkMonitorUseCase.isConnectedViaWiFi() {
                return .uploadInProgress(numberOfFilesPending: uploadStats.pendingFilesCount)
            } else if networkMonitorUseCase.isConnected(), cameraUploadsUseCellularDataUsageAllowed {
                // This may become the future scenario to handle `No internet connection`
                return .uploadInProgress(numberOfFilesPending: uploadStats.pendingFilesCount)
            } else {
                return .uploadPaused(reason: .noWifiConnection(numberOfFilesPending: uploadStats.pendingFilesCount))
            }
        }
        
        guard devicePermissionHandler.photoLibraryAuthorizationStatus != .limited else {
            return .uploadPartialCompleted(reason: .photoLibraryLimitedAccess)
        }
        
        guard uploadStats.pendingVideosCount > 0 else {
            return .uploadCompleted
        }

        return .uploadPartialCompleted(
            reason: .videoUploadIsNotEnabled(pendingVideoUploadCount: uploadStats.pendingVideosCount))
    }
}