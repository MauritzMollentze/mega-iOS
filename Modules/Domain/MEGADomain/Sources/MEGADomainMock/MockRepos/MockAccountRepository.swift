import Combine
import Foundation
import MEGADomain
import MEGASwift

public final class MockAccountRepository: AccountRepositoryProtocol, @unchecked Sendable {
    public static var newRepo: MockAccountRepository {
        MockAccountRepository()
    }
    
    // MARK: - User Authentication Details
    let currentUser: UserEntity?
    public let isGuest: Bool
    public let isPaidAccount: Bool
    
    private let _isLoggedIn: Bool
    private let _myEmail: String?
    private let _isNewAccount: Bool
    private let _isMasterBusinessAccount: Bool
    private let _isExpiredAccount: Bool
    private let _isInGracePeriod: Bool
    private let _isBilledProPlan: Bool
    private let _hasMultipleBilledProPlan: Bool
    private let accountType: AccountTypeEntity
    
    // MARK: - Account Characteristics
    private let _currentAccountDetails: AccountDetailsEntity?
    private let _accountCreationDate: Date?
    private let _bandwidthOverquotaDelay: Int64
    private let nodesCount: UInt64
    private let _contacts: [UserEntity]
    private let _isSmsAllowed: Bool
    private let _isAchievementsEnabled: Bool
    private let _plans: [PlanEntity]
    private let _currentProPlan: AccountPlanEntity?
    private let _currentSubscription: AccountSubscriptionEntity?
    private let _currentStorageStatus: StorageStatusEntity
    private let _isUnlimitedStorageAccount: Bool
    private let _shouldRefreshStorageStatus: Bool
    private let _isPaywalled: Bool
    
    // MARK: - Result Handlers
    private let getMyChatFilesFolderResult: Result<NodeEntity, AccountErrorEntity>
    private let accountDetailsResult: Result<AccountDetailsEntity, AccountDetailsErrorEntity>
    private let miscFlagsResult: Result<Void, AccountErrorEntity>
    private let sessionTransferURLResult: Result<URL, AccountErrorEntity>
    private let multiFactorAuthCheckResult: Result<Bool, AccountErrorEntity>
    private let isUpgradeSecuritySuccess: Bool
    
    // MARK: - Management of Contacts and Alerts
    private let contactsRequestsCount: Int
    private let unseenUserAlertsCount: UInt
    
    // MARK: - Account updates
    public let onRequestFinishUpdates: AnyAsyncSequence<RequestResponseEntity>
    public let onUserAlertsUpdates: AnyAsyncSequence<[UserAlertEntity]>
    public let onContactRequestsUpdates: AnyAsyncSequence<[ContactRequestEntity]>
    public let onEventsUpdates: AnyAsyncSequence<EventEntity>
    public let monitorRefreshAccountPublisher: AnyPublisher<Bool, Never>
    public let _isMonitoringRefreshAccount: Bool
    private(set) public var setAccountStorageStatusCalledCount: Int = 0
    
    // MARK: - Node Sizes
    public let rootStorage: Int64
    public let rubbishBinStorage: Int64
    public let incomingSharesStorage: Int64
    public let backupStorage: Int64
    
    // MARK: - Rich Link Preview
    public let richLinkPreviewEnabled: Bool

    // MARK: - Notification Settings
    public let notificationSettings: NotificationSettingsEntity
    
    // MARK: - Initializer
    public init(
        currentUser: UserEntity? = nil,
        isGuest: Bool = false,
        isProAccount: Bool = false,
        isNewAccount: Bool = false,
        accountCreationDate: Date? = nil,
        myEmail: String? = nil,
        isLoggedIn: Bool = true,
        isMasterBusinessAccount: Bool = false,
        isExpiredAccount: Bool = false,
        isInGracePeriod: Bool = false,
        isBilledProPlan: Bool = false,
        hasMultipleBilledProPlan: Bool = false,
        isAchievementsEnabled: Bool = false,
        isPaywalled: Bool = false,
        shouldRefreshStorageStatus: Bool = false,
        plans: [PlanEntity] = [],
        isSmsAllowed: Bool = false,
        contacts: [UserEntity] = [],
        nodesCount: UInt64 = 0,
        contactsRequestsCount: Int = 0,
        unseenUserAlertsCount: UInt = 0,
        getMyChatFilesFolderResult: Result<NodeEntity, AccountErrorEntity> = .failure(.nodeNotFound),
        currentAccountDetails: AccountDetailsEntity? = nil,
        accountDetailsResult: Result<AccountDetailsEntity, AccountDetailsErrorEntity> = .failure(.generic),
        miscFlagsResult: Result<Void, AccountErrorEntity> = .failure(.generic),
        sessionTransferURLResult: Result<URL, AccountErrorEntity> = .failure(.generic),
        multiFactorAuthCheckResult: Result<Bool, AccountErrorEntity> = .failure(.generic),
        isUpgradeSecuritySuccess: Bool = false,
        bandwidthOverquotaDelay: Int64 = 0,
        accountType: AccountTypeEntity = .free,
        rootStorage: Int64 = 0,
        rubbishBinStorage: Int64 = 0,
        incomingSharesStorage: Int64 = 0,
        backupStorage: Int64 = 0,
        richLinkPreviewEnabled: Bool = false,
        notificationSettings: NotificationSettingsEntity = NotificationSettingsEntity(
            globalChatsDndEnabled: false,
            globalChatsDndTimestamp: 0
        ),
        currentProPlan: AccountPlanEntity? = nil,
        currentStorageStatus: StorageStatusEntity = .noStorageProblems,
        isUnlimitedStorageAccount: Bool = false,
        currentSubscription: AccountSubscriptionEntity? = nil,
        onRequestFinishUpdates: AnyAsyncSequence<RequestResponseEntity> = EmptyAsyncSequence().eraseToAnyAsyncSequence(),
        onUserAlertsUpdates: AnyAsyncSequence<[UserAlertEntity]> = EmptyAsyncSequence().eraseToAnyAsyncSequence(),
        onContactRequestsUpdates: AnyAsyncSequence<[ContactRequestEntity]> = EmptyAsyncSequence().eraseToAnyAsyncSequence(),
        onEventsUpdates: AnyAsyncSequence<EventEntity> = EmptyAsyncSequence().eraseToAnyAsyncSequence(),
        monitorRefreshAccountPublisher: AnyPublisher<Bool, Never> = Empty().eraseToAnyPublisher(),
        isMonitoringRefreshAccount: Bool = false
    ) {
        self.currentUser = currentUser
        self.isGuest = isGuest
        self.isPaidAccount = isProAccount
        
        _isLoggedIn = isLoggedIn
        _myEmail = myEmail
        _isNewAccount = isNewAccount
        _isMasterBusinessAccount = isMasterBusinessAccount
        _isExpiredAccount = isExpiredAccount
        _isInGracePeriod = isInGracePeriod
        _isBilledProPlan = isBilledProPlan
        _hasMultipleBilledProPlan = hasMultipleBilledProPlan
        _isAchievementsEnabled = isAchievementsEnabled
        _isPaywalled = isPaywalled
        _shouldRefreshStorageStatus = shouldRefreshStorageStatus
        _plans = plans
        _currentProPlan = currentProPlan
        _currentStorageStatus = currentStorageStatus
        _isUnlimitedStorageAccount = isUnlimitedStorageAccount
        _currentSubscription = currentSubscription
        _accountCreationDate = accountCreationDate
        _isSmsAllowed = isSmsAllowed
        _contacts = contacts
        _currentAccountDetails = currentAccountDetails
        _bandwidthOverquotaDelay = bandwidthOverquotaDelay
        _isMonitoringRefreshAccount = isMonitoringRefreshAccount
        
        self.nodesCount = nodesCount
        self.contactsRequestsCount = contactsRequestsCount
        self.unseenUserAlertsCount = unseenUserAlertsCount
        self.getMyChatFilesFolderResult = getMyChatFilesFolderResult
        self.accountDetailsResult = accountDetailsResult
        self.miscFlagsResult = miscFlagsResult
        self.sessionTransferURLResult = sessionTransferURLResult
        self.isUpgradeSecuritySuccess = isUpgradeSecuritySuccess
        self.multiFactorAuthCheckResult = multiFactorAuthCheckResult
        self.accountType = accountType
        self.rootStorage = rootStorage
        self.rubbishBinStorage = rubbishBinStorage
        self.incomingSharesStorage = incomingSharesStorage
        self.backupStorage = backupStorage
        self.richLinkPreviewEnabled = richLinkPreviewEnabled
        self.notificationSettings = notificationSettings
        self.onRequestFinishUpdates = onRequestFinishUpdates
        self.onUserAlertsUpdates = onUserAlertsUpdates
        self.onContactRequestsUpdates = onContactRequestsUpdates
        self.onEventsUpdates = onEventsUpdates
        self.monitorRefreshAccountPublisher = monitorRefreshAccountPublisher
    }
    
    // MARK: - AccountRepositoryProtocol Implementation
    
    public var currentUserHandle: HandleEntity? {
        currentUser?.handle
    }
    
    public func currentUser() async -> UserEntity? {
        currentUser
    }
    
    public var myEmail: String? {
        _myEmail
    }
    
    public func isLoggedIn() -> Bool {
        _isLoggedIn
    }
    
    public var isMasterBusinessAccount: Bool {
        _isMasterBusinessAccount
    }
    
    public var isAchievementsEnabled: Bool {
        _isAchievementsEnabled
    }
    
    public var isPaywalled: Bool {
        _isPaywalled
    }
    
    public func currentAccountPlan() async -> PlanEntity? {
        _plans.first { $0.type == _currentAccountDetails?.proLevel && $0.subscriptionCycle == _currentAccountDetails?.subscriptionCycle }
    }
    
    public var isNewAccount: Bool {
        _isNewAccount
    }
    
    public func isExpiredAccount() -> Bool {
        _isExpiredAccount
    }
    
    public func isInGracePeriod() -> Bool {
        _isInGracePeriod
    }
    
    public func isBilledProPlan() -> Bool {
        _isBilledProPlan
    }
    
    public func hasMultipleBilledProPlans() -> Bool {
        _hasMultipleBilledProPlan
    }
    
    public var shouldRefreshStorageStatus: Bool {
        _shouldRefreshStorageStatus
    }
    
    public func refreshCurrentStorageState() async throws -> StorageStatusEntity? {
        currentStorageStatus
    }
    
    public var currentProPlan: AccountPlanEntity? {
        _currentProPlan
    }
    
    public func currentSubscription() -> AccountSubscriptionEntity? {
        _currentSubscription
    }
    
    public var currentStorageStatus: StorageStatusEntity {
        _currentStorageStatus
    }
    
    public var isUnlimitedStorageAccount: Bool {
        _isUnlimitedStorageAccount
    }
    
    public var accountCreationDate: Date? {
        _accountCreationDate
    }

    public func contacts() -> [UserEntity] {
        _contacts
    }

    public var bandwidthOverquotaDelay: Int64 {
        _bandwidthOverquotaDelay
    }

    public func totalNodesCount() -> UInt64 {
        nodesCount
    }

    public func getMyChatFilesFolder(completion: @escaping (Result<NodeEntity, AccountErrorEntity>) -> Void) {
        completion(getMyChatFilesFolderResult)
    }

    public var currentAccountDetails: AccountDetailsEntity? {
        _currentAccountDetails
    }

    public func refreshCurrentAccountDetails() async throws -> AccountDetailsEntity {
        switch accountDetailsResult {
        case .success(let details): return details
        case .failure(let error): throw error
        }
    }

    public func upgradeSecurity() async throws -> Bool {
        isUpgradeSecuritySuccess
    }

    public func getMiscFlags() async throws {
        if case .failure(let error) = miscFlagsResult {
            throw error
        }
    }

    public func sessionTransferURL(path: String) async throws -> URL {
        switch sessionTransferURLResult {
        case .success(let url): return url
        case .failure(let error): throw error
        }
    }

    public var isSMSAllowed: Bool {
        _isSmsAllowed
    }

    public func isAccountType(_ type: AccountTypeEntity) -> Bool {
        type == accountType
    }

    public func multiFactorAuthCheck(email: String) async throws -> Bool {
        switch multiFactorAuthCheckResult {
        case .success(let isMultifactorAuth): return isMultifactorAuth
        case .failure(let error): throw error
        }
    }

    public func incomingContactsRequestsCount() -> Int {
        contactsRequestsCount
    }

    public func relevantUnseenUserAlertsCount() -> UInt {
        unseenUserAlertsCount
    }

    public func rootStorageUsed() -> Int64 {
        rootStorage
    }
    
    public func rubbishBinStorageUsed() -> Int64 {
        rubbishBinStorage
    }
    
    public func incomingSharesStorageUsed() -> Int64 {
        incomingSharesStorage
    }
    
    public func backupStorageUsed() async throws -> Int64 {
        backupStorage
    }
    
    public func isRichLinkPreviewEnabled() async -> Bool {
        richLinkPreviewEnabled
    }
    
    public func enableRichLinkPreview(_ enabled: Bool) {
        
    }
    
    public func getPushNotificationSettings() async throws -> NotificationSettingsEntity {
        notificationSettings
    }
    
    public func setPushNotificationSettings(_ settings: NotificationSettingsEntity) async throws {
        
    }
    
    public var isMonitoringRefreshAccount: Bool {
        _isMonitoringRefreshAccount
    }
    
    public var monitorRefreshAccount: AnyPublisher<Bool, Never> {
        monitorRefreshAccountPublisher
    }
    
    public func refreshAccountAndMonitorUpdate() async throws -> AccountDetailsEntity {
        try accountDetailsResult.get()
    }
    
    public func setAccountStorageStatus(_ status: StorageStatusEntity) {
        setAccountStorageStatusCalledCount += 1
    }
}
