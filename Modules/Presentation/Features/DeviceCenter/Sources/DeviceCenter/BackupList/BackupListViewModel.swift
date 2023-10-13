import Combine
import MEGADomain
import MEGASDKRepo
import SwiftUI

public final class BackupListViewModel: ObservableObject {
    private let selectedDeviceId: String
    private let deviceCenterUseCase: any DeviceCenterUseCaseProtocol
    private let nodeUseCase: any NodeUseCaseProtocol
    private let networkMonitorUseCase: any NetworkMonitorUseCaseProtocol
    private let router: any BackupListRouting
    private let deviceCenterBridge: DeviceCenterBridge
    private let backupListAssets: BackupListAssets
    private let backupStatuses: [BackupStatus]
    private let deviceCenterActions: [DeviceCenterAction]
    private let devicesUpdatePublisher: PassthroughSubject<[DeviceEntity], Never>
    private let updateInterval: UInt64
    private var selectedDeviceName: String
    private(set) var backups: [BackupEntity]
    private var sortedBackupStatuses: [BackupStatusEntity: BackupStatus] {
        Dictionary(uniqueKeysWithValues: backupStatuses.map { ($0.status, $0) })
    }
    private var sortedBackupTypes: [BackupTypeEntity: BackupType] {
        Dictionary(uniqueKeysWithValues: backupListAssets.backupTypes.map { ($0.type, $0) })
    }
    private var sortedAvailableActions: [DeviceCenterActionType: [DeviceCenterAction]] {
        Dictionary(grouping: deviceCenterActions, by: \.type)
    }
    private var backupsPreloaded: Bool = false
    private var searchCancellable: AnyCancellable?
    
    var isFilteredBackupsEmpty: Bool {
        filteredBackups.isEmpty
    }
    
    var displayedBackups: [DeviceCenterItemViewModel] {
        isSearchActive && searchText.isNotEmpty ? filteredBackups : backupModels
    }
    
    @Published private(set) var backupModels: [DeviceCenterItemViewModel] = []
    @Published private(set) var filteredBackups: [DeviceCenterItemViewModel] = []
    @Published private(set) var emptyStateAssets: EmptyStateAssets
    @Published private(set) var searchAssets: SearchAssets
    @Published var isSearchActive: Bool
    @Published var searchText: String = ""
    @Published var hasNetworkConnection: Bool = false
    
    init(
        selectedDeviceId: String,
        selectedDeviceName: String,
        devicesUpdatePublisher: PassthroughSubject<[DeviceEntity], Never>,
        updateInterval: UInt64,
        deviceCenterUseCase: some DeviceCenterUseCaseProtocol,
        nodeUseCase: some NodeUseCaseProtocol,
        networkMonitorUseCase: some NetworkMonitorUseCaseProtocol,
        router: some BackupListRouting,
        deviceCenterBridge: DeviceCenterBridge,
        backups: [BackupEntity],
        backupListAssets: BackupListAssets,
        emptyStateAssets: EmptyStateAssets,
        searchAssets: SearchAssets,
        backupStatuses: [BackupStatus],
        deviceCenterActions: [DeviceCenterAction]
    ) {
        self.selectedDeviceId = selectedDeviceId
        self.selectedDeviceName = selectedDeviceName
        self.devicesUpdatePublisher = devicesUpdatePublisher
        self.updateInterval = updateInterval
        self.deviceCenterUseCase = deviceCenterUseCase
        self.nodeUseCase = nodeUseCase
        self.networkMonitorUseCase = networkMonitorUseCase
        self.router = router
        self.deviceCenterBridge = deviceCenterBridge
        self.backups = backups
        self.backupListAssets = backupListAssets
        self.emptyStateAssets = emptyStateAssets
        self.searchAssets = searchAssets
        self.backupStatuses = backupStatuses
        self.deviceCenterActions = deviceCenterActions
        self.isSearchActive = false
        self.searchText = ""
        
        setupSearchCancellable()
        loadBackupsInitialStatus()
    }
    
    private func setupSearchCancellable() {
        searchCancellable = $searchText
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.filterBackups()
            }
    }
    
    private func loadBackupsInitialStatus() {
        loadBackupsModels()
        backupsPreloaded = true
    }
    
    private func resetBackups() {
        filteredBackups = backupModels
    }
    
    private func filterBackups() {
        let hasSearchQuery = searchText.isNotEmpty
        isSearchActive = hasSearchQuery
        if hasSearchQuery {
            filteredBackups = backupModels.filter {
                $0.name.lowercased().contains(searchText.lowercased())
            }
        } else {
            resetBackups()
        }
    }
    
    @MainActor
    private func monitorNetworkChanges() {
        networkMonitorUseCase.networkPathChanged { [weak self] hasNetworkConnection in
            guard let self else { return }
            self.hasNetworkConnection = hasNetworkConnection
        }
    }
    
    @MainActor
    func updateInternetConnectionStatus() {
        hasNetworkConnection = networkMonitorUseCase.isConnected()
        monitorNetworkChanges()
    }
    
    func updateDeviceStatusesAndNotify() async throws {
        while true {
            if Task.isCancelled { return }
            try await Task.sleep(nanoseconds: updateInterval * 1_000_000_000)
            if Task.isCancelled { return }
            await syncDevicesAndLoadBackups()
        }
    }
    
    func syncDevicesAndLoadBackups() async {
        let devices = await deviceCenterUseCase.fetchUserDevices()
        await filterAndLoadCurrentDeviceBackups(devices)
        await updateCurrentDevice(devices)
        devicesUpdatePublisher.send(devices)
    }
    
    @MainActor
    func filterAndLoadCurrentDeviceBackups(_ devices: [DeviceEntity]) {
        backups = devices.first {$0.id == selectedDeviceId}?.backups ?? []
        loadBackupsModels()
    }
    
    @MainActor
    func updateCurrentDevice(_ devices: [DeviceEntity]) {
        guard let currentDevice = devices.first(where: {$0.id == selectedDeviceId}) else { return }
        selectedDeviceName = currentDevice.name
        router.updateTitle(currentDevice.name)
    }
    
    func loadBackupsModels() {
        backupModels = backups
            .compactMap { backup in
                if let assets = loadAssets(for: backup),
                   let availableActions = actionsForBackup(backup) {
                    return DeviceCenterItemViewModel(
                        deviceCenterUseCase: deviceCenterUseCase,
                        nodeUseCase: nodeUseCase,
                        deviceCenterBridge: deviceCenterBridge,
                        itemType: .backup(backup),
                        assets: assets,
                        availableActions: availableActions
                    )
                }
                return nil
            }
    }
    
    func loadAssets(for backup: BackupEntity) -> ItemAssets? {
        guard let backupStatus = backup.backupStatus,
              let status = sortedBackupStatuses[backupStatus],
              let backupType = sortedBackupTypes[backup.type] else {
            return nil
        }
        
        return ItemAssets(
            iconName: backupType.iconName,
            status: status
        )
    }
    
    func actionsForBackup(_ backup: BackupEntity) -> [DeviceCenterAction]? {
        var actionTypes = [DeviceCenterActionType]()
        
        actionTypes.append(.info)
        
        if backup.type == .cameraUpload || backup.type == .mediaUpload {
            actionTypes.append(.showInCloudDrive)
        } else {
            actionTypes.append(.showInBackups)
        }
        
        return actionTypes.compactMap { type in
            sortedAvailableActions[type]?.first
        }
    }
    
    func actionsForDevice() -> [DeviceCenterAction] {
        let currentDeviceUUID = UIDevice.current.identifierForVendor?.uuidString ?? ""
        let currentDeviceId = deviceCenterUseCase.loadCurrentDeviceId()
        let isMobileDevice = backups.contains {
            $0.type == .cameraUpload || $0.type == .mediaUpload
        }
        
        var actionTypes: [DeviceCenterActionType] = [.rename]

        if selectedDeviceId == currentDeviceUUID || (selectedDeviceId == currentDeviceId && isMobileDevice) {
            actionTypes.append(.cameraUploads)
        }
        
        actionTypes.append(.sort)
        
        return actionTypes.compactMap { type in
            sortedAvailableActions[type]?.first
        }
    }
    
    @MainActor
    func executeDeviceAction(type: DeviceCenterActionType) async {
        switch type {
        case .cameraUploads:
            deviceCenterBridge.cameraUploadActionTapped { [weak self] in
                Task {
                    await self?.syncDevicesAndLoadBackups()
                }
            }
        case .rename:
            let deviceNames = await deviceCenterUseCase.fetchDeviceNames()
            let renameEntity = RenameActionEntity(
                deviceId: selectedDeviceId,
                deviceOldName: selectedDeviceName,
                otherDeviceNames: deviceNames) { [weak self] in
                    Task {
                        await self?.syncDevicesAndLoadBackups()
                    }
            }
            deviceCenterBridge.renameActionTapped(renameEntity)
        case .info:
            guard let nodeHandle = backups.first?.rootHandle,
                  let nodeEntity = nodeUseCase.parentForHandle(nodeHandle) else { return }
            
            deviceCenterBridge.infoActionTapped(nodeEntity)
        default: break
        }
    }
}
