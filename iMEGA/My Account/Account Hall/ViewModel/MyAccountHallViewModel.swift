import Combine
import DeviceCenter
import Foundation
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGASwift

enum MyAccountSection: Int, CaseIterable {
    case mega = 0
}

enum MyAccountMegaSection: Int, CaseIterable {
    case plan = 0, storage, myAccount, contacts, notifications, achievements, transfers, deviceCenter, offline, rubbishBin, settings
}

enum MyAccountHallLoadTarget {
    case planList, accountDetails, contentCounts, promos
}

enum MyAccountHallAction: ActionType {
    case viewDidLoad
    case viewWillAppear
    case viewWillDisappear
    case reloadUI
    case load(_ target: MyAccountHallLoadTarget)
    case didTapUpgradeButton
    case didTapDeviceCenterButton
    case navigateToProfile
    case navigateToUsage
    case navigateToSettings
    case didTapMyAccountButton
    case didTapAccountHeader
    case didTapNotificationCentre
}

@MainActor
final class MyAccountHallViewModel: ViewModelType, ObservableObject {
    
    enum Command: CommandType, Equatable {
        case reloadCounts
        case reloadUIContent
        case reloadStorage
        case configPlanDisplay
        case setUserAvatar
        case setName
    }

    @Atomic var relevantUnseenUserAlertsCount: UInt = 0
    @Atomic var accountDetails: AccountDetailsEntity?
    @Atomic var arePromosAvailable: Bool = false

    var invokeCommand: ((Command) -> Void)?
    var incomingContactRequestsCount = 0
    var unreadNotificationsCount = 0
    
    private(set) var planList: [PlanEntity] = []
    private let myAccountHallUseCase: any MyAccountHallUseCaseProtocol
    private let accountUseCase: any AccountUseCaseProtocol
    private let purchaseUseCase: any AccountPlanPurchaseUseCaseProtocol
    private let notificationsUseCase: any NotificationsUseCaseProtocol
    private let tracker: any AnalyticsTracking
    private let notificationCenter: NotificationCenter
    private var hasTrackedNotificationCentreDisplayedEvents = false
    let shareUseCase: any ShareUseCaseProtocol
    let deviceCenterBridge: DeviceCenterBridge
    let router: any MyAccountHallRouting
    
    private var subscriptions = Set<AnyCancellable>()
    var loadContentTask: Task<Void, Never>?
    var onAccountRequestFinishUpdatesTask: Task<Void, any Error>?
    var onUserAlertsUpdatesTask: Task<Void, any Error>?
    var onContactRequestsUpdatesTask: Task<Void, any Error>?
    
    // MARK: Account Plan view
    @Published private(set) var currentPlanName: String = ""
    @Published var isAccountUpdating: Bool = false
    
    // MARK: - Init
    
    init(
        myAccountHallUseCase: some MyAccountHallUseCaseProtocol,
        accountUseCase: some AccountUseCaseProtocol,
        purchaseUseCase: some AccountPlanPurchaseUseCaseProtocol,
        shareUseCase: some ShareUseCaseProtocol,
        notificationsUseCase: some NotificationsUseCaseProtocol,
        deviceCenterBridge: DeviceCenterBridge,
        tracker: some AnalyticsTracking,
        router: some MyAccountHallRouting,
        notificationCenter: NotificationCenter = .default
    ) {
        self.myAccountHallUseCase = myAccountHallUseCase
        self.accountUseCase = accountUseCase
        self.purchaseUseCase = purchaseUseCase
        self.shareUseCase = shareUseCase
        self.notificationsUseCase = notificationsUseCase
        self.deviceCenterBridge = deviceCenterBridge
        self.tracker = tracker
        self.router = router
        self.notificationCenter = notificationCenter
        
        setAccountDetails(myAccountHallUseCase.currentAccountDetails)
        makeDeviceCenterBridge()
        registerDelegates()
    }
    
    deinit {
        Task { [purchaseUseCase] in
            await purchaseUseCase.deRegisterPurchaseDelegate()
        }
        loadContentTask?.cancel()
        loadContentTask = nil
    }
    
    // MARK: - Dispatch actions
    
    func dispatch(_ action: MyAccountHallAction) {
        switch action {
        case .viewDidLoad:
            trackAccountScreenEvent()
            registerDelegates()
            setupSubscriptions()
        case .viewWillAppear:
            startAccountUpdatesMonitoring()
        case .viewWillDisappear:
            stopAccountUpdatesMonitoring()
        case .reloadUI:
            invokeCommand?(.reloadUIContent)
        case .load(let target):
            loadContentTask = Task { [weak self] in
                guard let self else { return }
                await loadContent(target)
            }
        case .didTapUpgradeButton:
            trackUpgradeAccountButtonTappedEvent()
            showUpgradeAccountPlanView()
        case .didTapDeviceCenterButton:
            router.navigateToDeviceCenter(
                deviceCenterBridge: deviceCenterBridge,
                deviceCenterActions: makeDeviceCenterActionList()
            )
        case .navigateToProfile: router.navigateToProfile()
        case .navigateToUsage: router.navigateToUsage()
        case .navigateToSettings: router.navigateToSettings()
        case .didTapMyAccountButton:
            trackMyAccountEvent()
        case .didTapAccountHeader:
            trackAccountHeaderEvent()
        case .didTapNotificationCentre:
            trackNotificationCentreButtonPressedEvent()
            router.navigateToNotificationCentre()
        }
    }
    
    // MARK: - Setup
    private func registerDelegates() {
        Task { [purchaseUseCase] in
            await purchaseUseCase.registerPurchaseDelegate()
        }
    }
    
    private func trackAccountScreenEvent() {
        tracker.trackAnalyticsEvent(with: AccountScreenEvent())
    }
    
    private func trackMyAccountEvent() {
        tracker.trackAnalyticsEvent(with: MyAccountProfileNavigationItemEvent())
    }
    
    private func trackAccountHeaderEvent() {
        tracker.trackAnalyticsEvent(with: AccountScreenHeaderTappedEvent())
    }
    
    private func trackUpgradeAccountButtonTappedEvent() {
        tracker.trackAnalyticsEvent(with: UpgradeMyAccountEvent())
    }
    
    private func trackNotificationCentreButtonPressedEvent() {
        tracker.trackAnalyticsEvent(with: NotificationsEntryButtonPressedEvent())
    }
    
    private func trackNotificationCentreDisplayedWithNoUnreadNotificationsEvent() {
        tracker.trackAnalyticsEvent(with: AccountNotificationCentreDisplayedWithNoUnreadNotificationsEvent())
    }
    
    private func trackNotificationCentreDisplayedWithUnreadNotificationsEvent() {
        tracker.trackAnalyticsEvent(with: AccountNotificationCentreDisplayedWithUnreadNotificationsEvent())
    }
    
    private func showUpgradeAccountPlanView() {
        guard let accountDetails else { return }
        router.navigateToUpgradeAccount(accountDetails: accountDetails)
    }
    
    // MARK: - Public
    var currentUserHandle: HandleEntity? {
        myAccountHallUseCase.currentUserHandle
    }
    
    var userFullName: String? {
        guard let userHandle = currentUserHandle else { return nil }
        return MEGAUser.mnz_fullName(userHandle)
    }
    
    var isMasterBusinessAccount: Bool {
        myAccountHallUseCase.isMasterBusinessAccount
    }
    
    var showPlanRow: Bool {
        !isBusinessAccount && !isProFlexiAccount
    }
    
    var transferUsed: Int64 {
        accountDetails?.transferUsed ?? 0
    }
    
    var transferMax: Int64 {
        accountDetails?.transferMax ?? 0
    }
    
    var storageUsed: Int64 {
        accountDetails?.storageUsed ?? 0
    }
    
    var storageMax: Int64 {
        accountDetails?.storageMax ?? 0
    }
    
    var isBusinessAccount: Bool {
        accountDetails?.proLevel == .business
    }
    
    var isProFlexiAccount: Bool {
        accountDetails?.proLevel == .proFlexi
    }
    
    var rubbishBinFormattedStorageUsed: String {
        let rubbishBinStorageUsed = accountUseCase.rubbishBinStorageUsed()
        return String
            .memoryStyleString(fromByteCount: rubbishBinStorageUsed)
            .formattedByteCountString()
    }
    
    func calculateCellHeight(at indexPath: IndexPath) -> CGFloat {
        var shouldShowCell = true
        switch MyAccountMegaSection(rawValue: indexPath.row) {
        case .plan:
            shouldShowCell = showPlanRow
        case .achievements:
            shouldShowCell = myAccountHallUseCase.isAchievementsEnabled
        default: break
        }
        
        return shouldShowCell ? UITableView.automaticDimension : 0.0
    }
    
    // MARK: - Private
    private func setAccountDetails(_ details: AccountDetailsEntity?) {
        $accountDetails.mutate { currentValue in
            currentValue = details
        }
        
        currentPlanName = details?.proLevel.toAccountTypeDisplayName() ?? ""
    }
    
    private func loadContent(_ target: MyAccountHallLoadTarget) async {
        switch target {
        case .planList:
            await fetchPlanList()
        case .accountDetails:
            isAccountUpdating = accountUseCase.isMonitoringRefreshAccount || purchaseUseCase.isSubmittingReceiptAfterPurchase
            await updateAccountDetails()
        case .contentCounts:
            await fetchCounts()
        case .promos:
            await fetchAvailablePromos()
        }
    }
    
    private func fetchPlanList() async {
        planList = await purchaseUseCase.accountPlanProducts()
        configPlanDisplay()
    }
    
    private func updateAccountDetails(monitorUpdate: Bool = false) async {
        do {
            let accountDetails = try await (
                monitorUpdate
                ? accountUseCase.refreshAccountAndMonitorUpdate()
                : accountUseCase.refreshCurrentAccountDetails()
            )
            updateAccountDisplay(accountDetails)
        } catch {
            MEGALogError("[Account Hall] Error loading account details. Error: \(error)")
        }
    }
    
    private func updateAccountDisplay(_ accountDetails: AccountDetailsEntity) {
        setAccountDetails(accountDetails)
        configPlanDisplay()
        reloadStorage()
    }

    private func fetchCounts() async {
        incomingContactRequestsCount = await myAccountHallUseCase.incomingContactsRequestsCount()
        let relevantUnseenUserAlertsCount = await myAccountHallUseCase.relevantUnseenUserAlertsCount()
        $relevantUnseenUserAlertsCount.mutate { currentValue in
            currentValue = relevantUnseenUserAlertsCount
        }
        
        unreadNotificationsCount = await notificationsUseCase.unreadNotificationIDs().count
        
        if !hasTrackedNotificationCentreDisplayedEvents {
            unreadNotificationsCount > 0 ? trackNotificationCentreDisplayedWithUnreadNotificationsEvent() : trackNotificationCentreDisplayedWithNoUnreadNotificationsEvent()
            hasTrackedNotificationCentreDisplayedEvents = true
        }

        reloadNotificationCounts()
    }
    
    private func fetchAvailablePromos() async {
        $arePromosAvailable.mutate { [weak self] currentValue in
            guard let self else { return }
            let hasEnabledNotifications = notificationsUseCase.fetchEnabledNotifications().isNotEmpty
            currentValue = hasEnabledNotifications
        }
    }
    
    // MARK: UI
    private func reloadNotificationCounts() {
        invokeCommand?(.reloadCounts)
    }
    
    private func configPlanDisplay() {
        invokeCommand?(.configPlanDisplay)
    }
    
    private func reloadStorage() {
        invokeCommand?(.reloadStorage)
    }

    // MARK: Subscriptions and Account updates
    private func startAccountUpdatesMonitoring() {
        onAccountRequestFinishUpdatesTask = Task { [weak self, myAccountHallUseCase] in
            for await resultRequest in myAccountHallUseCase.onAccountRequestFinish {
                guard let self else { return }
                try Task.checkCancellation()
                
                handleRequestResult(resultRequest)
            }
        }
        
        onUserAlertsUpdatesTask = Task { [weak self, myAccountHallUseCase] in
            for await _ in myAccountHallUseCase.onUserAlertsUpdates {
                guard let self else { return }
                try Task.checkCancellation()
                let userAlertsCount = await myAccountHallUseCase.relevantUnseenUserAlertsCount()
                $relevantUnseenUserAlertsCount.mutate { currentValue in
                    currentValue = userAlertsCount
                }
                invokeCommand?(.reloadCounts)
            }
        }

        onContactRequestsUpdatesTask = Task { [weak self, myAccountHallUseCase] in
            for await _ in myAccountHallUseCase.onContactRequestsUpdates {
                guard let self else { return }
                try Task.checkCancellation()
                incomingContactRequestsCount = await myAccountHallUseCase.incomingContactsRequestsCount()
                invokeCommand?(.reloadCounts)
            }
        }
    }
    
    private func stopAccountUpdatesMonitoring() {
        onAccountRequestFinishUpdatesTask?.cancel()
        onUserAlertsUpdatesTask?.cancel()
        onContactRequestsUpdatesTask?.cancel()
        onAccountRequestFinishUpdatesTask = nil
        onUserAlertsUpdatesTask = nil
        onContactRequestsUpdatesTask = nil
    }
    
    private func setupSubscriptions() {
        /// Listens for the result of receipt submission.
        /// - If the submission is successful, it refreshes the account details and
        ///   ends any ongoing purchase receipt monitoring.
        /// - If unsuccessful, it does nothing.
        purchaseUseCase.submitReceiptResultPublisher
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .sink { [weak self] result in
                guard let self, case .success = result else { return }
                Task { [weak self] in
                    guard let self else { return }
                    purchaseUseCase.endMonitoringPurchaseReceipt()
                    await updateAccountDetails(monitorUpdate: true)
                }
            }
            .store(in: &subscriptions)

        /// Monitors whether receipt submission is in progress after a purchase.
        /// - When `startMonitoringSubmitReceiptAfterPurchase` is called,
        ///   `monitorSubmitReceiptAfterPurchase` will publish updates.
        /// - If `monitorSubmitReceiptAfterPurchase` emits `true`, the UI will show
        ///   the loading indicator.
        /// - If `false`, it is ignored.
        purchaseUseCase.monitorSubmitReceiptAfterPurchase
            .removeDuplicates()
            .filter { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.isAccountUpdating = true
                self?.reloadStorage()
            }
            .store(in: &subscriptions)
        
        /// Monitors the account refresh process, primarily used after a plan purchase.
        /// - When `monitorRefreshAccount` emits `true`, the UI displays a loading indicator.
        /// - When it emits `false`, the UI hides the loading indicator.
        accountUseCase.monitorRefreshAccount
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isUpdating in
                self?.isAccountUpdating = isUpdating
                self?.reloadStorage()
                Task { await self?.updateAccountDetails() }
            }
            .store(in: &subscriptions)
    }
    
    private func handleRequestResult(_ result: Result<AccountRequestEntity, any Error>) {
        if case .success(let request) = result {
            switch request.type {
            case .accountDetails:
                invokeCommand?(.reloadUIContent)
            case .getAttrUser:
                if request.file != nil {
                    invokeCommand?(.setUserAvatar)
                }

                if (request.userAttribute == .firstName || request.userAttribute == .lastName) &&
                    request.email == nil {
                    invokeCommand?(.setName)
                }
            default:
                MEGALogDebug("[Account Hall] Received \(request.type) request type but will not handle here")
                return
            }
        }
    }
}
