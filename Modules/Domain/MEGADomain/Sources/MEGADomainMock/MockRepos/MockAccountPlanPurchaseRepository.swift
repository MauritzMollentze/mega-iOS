import Combine
import MEGADomain

public final class MockAccountPlanPurchaseRepository: AccountPlanPurchaseRepositoryProtocol, @unchecked Sendable {
    private let plans: [PlanEntity]
    public let successfulRestorePublisher: AnyPublisher<Void, Never>
    public let incompleteRestorePublisher: AnyPublisher<Void, Never>
    public let failedRestorePublisher: AnyPublisher<AccountPlanErrorEntity, Never>
    public let purchasePlanResultPublisher: AnyPublisher<Result<Void, AccountPlanErrorEntity>, Never>
    public let submitReceiptResultPublisher: AnyPublisher<Result<Void, AccountPlanErrorEntity>, Never>
    public var registerRestoreDelegateCalled = 0
    public var deRegisterRestoreDelegateCalled = 0
    public var restorePurchaseCalled = 0
    public var purchasePlanCalled = 0
    public var registerPurchaseDelegateCalled = 0
    public var deRegisterPurchaseDelegateCalled = 0
    public let monitorSubmitReceiptPublisher: AnyPublisher<Bool, Never>
    public let _isSubmittingReceiptAfterPurchase: Bool
    public var startMonitoringSubmitReceiptAfterPurchaseCalled = 0
    public var endMonitoringPurchaseReceiptCalled = 0
    
    public static var newRepo: MockAccountPlanPurchaseRepository {
        MockAccountPlanPurchaseRepository()
    }
    
    public init(plans: [PlanEntity] = [],
                successfulRestorePublisher: AnyPublisher<Void, Never> = Empty().eraseToAnyPublisher(),
                incompleteRestorePublisher: AnyPublisher<Void, Never> = Empty().eraseToAnyPublisher(),
                failedRestorePublisher: AnyPublisher<AccountPlanErrorEntity, Never> = Empty().eraseToAnyPublisher(),
                purchasePlanResultPublisher: AnyPublisher<Result<Void, AccountPlanErrorEntity>, Never> = Empty().eraseToAnyPublisher(),
                submitReceiptResultPublisher: AnyPublisher<Result<Void, AccountPlanErrorEntity>, Never> = Empty().eraseToAnyPublisher(),
                monitorSubmitReceiptPublisher: AnyPublisher<Bool, Never> = Empty().eraseToAnyPublisher(),
                isSubmittingReceiptAfterPurchase: Bool = false
    ) {
        self.plans = plans
        self.successfulRestorePublisher = successfulRestorePublisher
        self.incompleteRestorePublisher = incompleteRestorePublisher
        self.failedRestorePublisher = failedRestorePublisher
        self.purchasePlanResultPublisher = purchasePlanResultPublisher
        self.submitReceiptResultPublisher = submitReceiptResultPublisher
        self.monitorSubmitReceiptPublisher = monitorSubmitReceiptPublisher
        _isSubmittingReceiptAfterPurchase = isSubmittingReceiptAfterPurchase
    }
    
    public func accountPlanProducts(useAPIPrice: Bool) -> [PlanEntity] {
        plans
    }
    
    public func registerRestoreDelegate() async {
        registerRestoreDelegateCalled += 1
    }
    
    public func deRegisterRestoreDelegate() async {
        deRegisterRestoreDelegateCalled += 1
    }
    
    public func restorePurchase() {
        restorePurchaseCalled += 1
    }
    
    public func purchasePlan(_ plan: PlanEntity) async {
        purchasePlanCalled += 1
    }
    
    public func registerPurchaseDelegate() async {
        registerPurchaseDelegateCalled += 1
    }
    
    public func deRegisterPurchaseDelegate() async {
        deRegisterPurchaseDelegateCalled += 1
    }
    
    public var monitorSubmitReceiptAfterPurchase: AnyPublisher<Bool, Never> {
        monitorSubmitReceiptPublisher
    }
    
    public var isSubmittingReceiptAfterPurchase: Bool {
        _isSubmittingReceiptAfterPurchase
    }
    
    public func startMonitoringSubmitReceiptAfterPurchase() {
        startMonitoringSubmitReceiptAfterPurchaseCalled += 1
    }
    
    public func endMonitoringPurchaseReceipt() {
        endMonitoringPurchaseReceiptCalled += 1
    }
}
