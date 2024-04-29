import Combine
import Foundation

public protocol AccountRepositoryProtocol {
    // User authentication status and identifiers
    var currentUserHandle: HandleEntity? { get }
    var isGuest: Bool { get }
    var isNewAccount: Bool { get }
    var myEmail: String? { get }

    // Account characteristics
    var accountCreationDate: Date? { get }
    var currentAccountDetails: AccountDetailsEntity? { get }
    var bandwidthOverquotaDelay: Int64 { get }
    var isMasterBusinessAccount: Bool { get }
    var isSMSAllowed: Bool { get }
    var isAchievementsEnabled: Bool { get }

    // User and session management
    func currentUser() async -> UserEntity?
    func isLoggedIn() -> Bool
    func isAccountType(_ type: AccountTypeEntity) -> Bool
    func refreshCurrentAccountDetails() async throws -> AccountDetailsEntity

    // Account operations
    func contacts() -> [UserEntity]
    func totalNodesCount() -> UInt64
    func getMyChatFilesFolder(completion: @escaping (Result<NodeEntity, AccountErrorEntity>) -> Void)
    func upgradeSecurity() async throws -> Bool
    func getMiscFlags() async throws
    func sessionTransferURL(path: String) async throws -> URL

    // Account social and notifications
    func incomingContactsRequestsCount() -> Int
    func relevantUnseenUserAlertsCount() -> UInt

    // Account events and delegates
    var requestResultPublisher: AnyPublisher<Result<AccountRequestEntity, Error>, Never> { get }
    var contactRequestPublisher: AnyPublisher<[ContactRequestEntity], Never> { get }
    var userAlertUpdatePublisher: AnyPublisher<[UserAlertEntity], Never> { get }
    func registerMEGARequestDelegate() async
    func deRegisterMEGARequestDelegate() async
    func registerMEGAGlobalDelegate() async
    func deRegisterMEGAGlobalDelegate() async
    func multiFactorAuthCheck(email: String) async throws -> Bool
}
