import Combine
@testable import MEGA
import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import MEGADomain
import XCTest

final class AccountPlanPurchaseRepositoryTests: XCTestCase {
    private var subscriptions = Set<AnyCancellable>()
    
    // MARK: Plans
    func testAccountPlanProducts_monthly() async {
        let products = [MockSKProduct(identifier: "pro1.oneMonth", price: "1", priceLocale: Locale.current),
                        MockSKProduct(identifier: "pro2.oneMonth", price: "1", priceLocale: Locale.current),
                        MockSKProduct(identifier: "pro3.oneMonth", price: "1", priceLocale: Locale.current),
                        MockSKProduct(identifier: "lite.oneMonth", price: "1", priceLocale: Locale.current)]
        let expectedResult = [PlanEntity(type: .proI, subscriptionCycle: .monthly),
                              PlanEntity(type: .proII, subscriptionCycle: .monthly),
                              PlanEntity(type: .proIII, subscriptionCycle: .monthly),
                              PlanEntity(type: .lite, subscriptionCycle: .monthly)]
        
        let mockPurchase = MockMEGAPurchase(productPlans: products)
        let sut = AccountPlanPurchaseRepository(purchase: mockPurchase, sdk: MockSdk())
        let plans = await sut.accountPlanProducts(useAPIPrice: false)
        XCTAssertEqual(plans, expectedResult)
    }
    
    func testAccountPlanProducts_yearly() async {
        let products = [MockSKProduct(identifier: "pro1.oneYear", price: "1", priceLocale: Locale.current),
                        MockSKProduct(identifier: "pro2.oneYear", price: "1", priceLocale: Locale.current),
                        MockSKProduct(identifier: "pro3.oneYear", price: "1", priceLocale: Locale.current),
                        MockSKProduct(identifier: "lite.oneYear", price: "1", priceLocale: Locale.current)]
        let expectedResult = [PlanEntity(type: .proI, subscriptionCycle: .yearly),
                              PlanEntity(type: .proII, subscriptionCycle: .yearly),
                              PlanEntity(type: .proIII, subscriptionCycle: .yearly),
                              PlanEntity(type: .lite, subscriptionCycle: .yearly)]
        
        let mockPurchase = MockMEGAPurchase(productPlans: products)
        let sut = AccountPlanPurchaseRepository(purchase: mockPurchase, sdk: MockSdk())
        let plans = await sut.accountPlanProducts(useAPIPrice: false)
        XCTAssertEqual(plans, expectedResult)
    }

//    func testAccountPlanProducts_usingAPIPrice_shouldReturnAPIPrice_andCurrencyCode() async {
//        let products = [
//            MockSKProduct(identifier: "pro1.oneYear", price: "1", priceLocale: Locale.current),
//            MockSKProduct(identifier: "pro2.oneYear", price: "1", priceLocale: Locale.current),
//            MockSKProduct(identifier: "pro3.oneYear", price: "1", priceLocale: Locale.current),
//            MockSKProduct(identifier: "lite.oneYear", price: "1", priceLocale: Locale.current)
//        ]
//        let expectedResult = [
//            PlanEntity(type: .proI, subscriptionCycle: .yearly, price: 1111.11),
//            PlanEntity(type: .proII, subscriptionCycle: .yearly, price: 2222.22),
//            PlanEntity(type: .proIII, subscriptionCycle: .yearly, price: 3333.33),
//            PlanEntity(type: .lite, subscriptionCycle: .yearly, price: 4444.44)
//        ]
//
//        let mockPurchase = MockMEGAPurchase(productPlans: products)
//        mockPurchase._pricing = MockMEGAPricing(
//            productList: [
//                MockPricingProduct(proLevel: .proI, localPrice: 111111),
//                MockPricingProduct(proLevel: .proII, localPrice: 222222),
//                MockPricingProduct(proLevel: .proIII, localPrice: 333333),
//                MockPricingProduct(proLevel: .lite, localPrice: 444444)
//            ]
//        )
//        mockPurchase._currency = MockMEGACurrency(localCurrencyName: "USD")
//        let sut = AccountPlanPurchaseRepository(purchase: mockPurchase, sdk: MockSdk())
//        let plans = await sut.accountPlanProducts(useAPIPrice: true)
//        XCTAssertEqual(plans, expectedResult)
//        XCTAssertTrue(plans.allSatisfy { $0.currency == "USD" })
//    }

    // MARK: Restore purchase
    func testRestorePurchase_addDelegate_delegateShouldExist() async {
        let mockPurchase = MockMEGAPurchase()
        let sut = AccountPlanPurchaseRepository(purchase: mockPurchase, sdk: MockSdk())
        await sut.registerRestoreDelegate()
        XCTAssertTrue(mockPurchase.hasRestoreDelegate)
    }
    
    func testRestorePurchase_removeDelegate_delegateShouldNotExist() async {
        let mockPurchase = MockMEGAPurchase()
        let sut = AccountPlanPurchaseRepository(purchase: mockPurchase, sdk: MockSdk())
        await sut.registerRestoreDelegate()
        
        await sut.deRegisterRestoreDelegate()
        XCTAssertFalse(mockPurchase.hasRestoreDelegate)
    }
    
    func testRestorePurchaseCalled_shouldReturnTrue() async {
        let mockPurchase = MockMEGAPurchase()
        let sut = AccountPlanPurchaseRepository(purchase: mockPurchase, sdk: MockSdk())
        sut.restorePurchase()
        XCTAssertTrue(mockPurchase.restorePurchaseCalled == 1)
    }
    
    func testRestorePublisher_successfulRestorePublisher_shouldSendToPublisher() {
        let mockPurchase = MockMEGAPurchase()
        let sut = AccountPlanPurchaseRepository(purchase: mockPurchase, sdk: MockSdk())
        
        let exp = expectation(description: "Should receive signal from successfulRestorePublisher")
        sut.successfulRestorePublisher
            .sink {
                exp.fulfill()
            }.store(in: &subscriptions)
        sut.successfulRestore(mockPurchase)
        wait(for: [exp], timeout: 1)
    }
    
    func testRestorePublisher_incompleteRestorePublisher_shouldSendToPublisher() {
        let mockPurchase = MockMEGAPurchase()
        let sut = AccountPlanPurchaseRepository(purchase: mockPurchase, sdk: MockSdk())
        
        let exp = expectation(description: "Should receive signal from incompleteRestorePublisher")
        sut.incompleteRestorePublisher
            .sink {
                exp.fulfill()
            }.store(in: &subscriptions)
        sut.incompleteRestore()
        wait(for: [exp], timeout: 1)
    }
    
    func testRestorePublisher_failedRestorePublisher_shouldSendToPublisher() {
        let mockPurchase = MockMEGAPurchase()
        let sut = AccountPlanPurchaseRepository(purchase: mockPurchase, sdk: MockSdk())
        
        let exp = expectation(description: "Should receive signal from failedRestorePublisher")
        let expectedError = AccountPlanErrorEntity(errorCode: 1, errorMessage: "Test Error")
        sut.failedRestorePublisher
            .sink { errorEntity in
                XCTAssertEqual(errorEntity.errorCode, expectedError.errorCode)
                XCTAssertEqual(errorEntity.errorMessage, expectedError.errorMessage)
                exp.fulfill()
            }.store(in: &subscriptions)
        sut.failedRestore(expectedError.errorCode, message: expectedError.errorMessage)
        wait(for: [exp], timeout: 1)
    }
    
    // MARK: Purchase plan
    func testPurchasePlan_addDelegate_delegateShouldExist() async {
        let mockPurchase = MockMEGAPurchase()
        let sut = AccountPlanPurchaseRepository(purchase: mockPurchase, sdk: MockSdk())
        await sut.registerPurchaseDelegate()
        XCTAssertTrue(mockPurchase.hasPurchaseDelegate)
    }
    
    func testPurchasePlan_removeDelegate_delegateShouldNotExist() async {
        let mockPurchase = MockMEGAPurchase()
        let sut = AccountPlanPurchaseRepository(purchase: mockPurchase, sdk: MockSdk())
        await sut.registerPurchaseDelegate()
        
        await sut.deRegisterPurchaseDelegate()
        XCTAssertFalse(mockPurchase.hasPurchaseDelegate)
    }
    
    func testPurchasePublisher_successPurchase_shouldSendToPublisher() {
        let mockPurchase = MockMEGAPurchase()
        let sut = AccountPlanPurchaseRepository(purchase: mockPurchase, sdk: MockSdk())
        
        let exp = expectation(description: "Should receive success purchase result")
        sut.purchasePlanResultPublisher
            .sink { result in
                if case .failure = result {
                    XCTFail("Request error is not expected.")
                }
                exp.fulfill()
            }.store(in: &subscriptions)
        
        sut.successfulPurchase(mockPurchase)
        wait(for: [exp], timeout: 1)
    }
    
    func testPurchasePublisher_failedPurchase_shouldSendToPublisher() {
        let mockPurchase = MockMEGAPurchase()
        let sut = AccountPlanPurchaseRepository(purchase: mockPurchase, sdk: MockSdk())
        let expectedError = AccountPlanErrorEntity(errorCode: 1, errorMessage: "TestError")
        
        let exp = expectation(description: "Should receive failed purchase result")
        sut.purchasePlanResultPublisher
            .sink { result in
                switch result {
                case .success:
                    XCTFail("Expecting an error but got a success.")
                case .failure(let error):
                    XCTAssertEqual(error.errorCode, expectedError.errorCode)
                    XCTAssertEqual(error.errorMessage, expectedError.errorMessage)
                }
                exp.fulfill()
            }.store(in: &subscriptions)
        
        sut.failedPurchase(expectedError.errorCode, message: expectedError.errorMessage)
        wait(for: [exp], timeout: 1)
    }
    
    // MARK: Submit receipt
    func testSubmitReceiptPublisher_failedResult_shouldSendToPublisher() {
        let sut = AccountPlanPurchaseRepository(purchase: MockMEGAPurchase(), sdk: MockSdk())
        let expectedError = AccountPlanErrorEntity(errorCode: -11, errorMessage: nil)
        
        let exp = expectation(description: "Should receive failed submit receipt result")
        sut.submitReceiptResultPublisher
            .sink { result in
                switch result {
                case .success:
                    XCTFail("Expecting an error but got a success.")
                case .failure(let error):
                    XCTAssertEqual(error.errorCode, expectedError.errorCode)
                }
                exp.fulfill()
            }.store(in: &subscriptions)
        
        sut.failedSubmitReceipt(expectedError.errorCode)
        wait(for: [exp], timeout: 1)
    }
    
    func testStartMonitoringSubmitReceiptAfterPurchase_whenCalled_shouldSetIsSubmittingReceiptValueToMonitoringStatus() {
        let isSubmittingReceipt = Bool.random()
        let currentUserSource = CurrentUserSource(sdk: MockSdk())
        let sut = makeSUT(
            purchase: MockMEGAPurchase(isSubmittingReceipt: isSubmittingReceipt),
            currentUserSource: currentUserSource
        )
        
        sut.startMonitoringSubmitReceiptAfterPurchase()
        
        XCTAssertEqual(currentUserSource.monitorSubmitReceiptAfterPurchaseSourcePublisher.value, isSubmittingReceipt)
    }
    
    func testEndMonitoringPurchaseReceipt_whenCalled_shouldSetMonitoringStatusToFalse() {
        let currentUserSource = CurrentUserSource(sdk: MockSdk())
        let sut = makeSUT(
            purchase: MockMEGAPurchase(isSubmittingReceipt: true),
            currentUserSource: currentUserSource
        )
        
        sut.endMonitoringPurchaseReceipt()
        
        XCTAssertEqual(currentUserSource.monitorSubmitReceiptAfterPurchaseSourcePublisher.value, false)
    }

    func testIsSubmittingReceiptAfterPurchase_whenCalled_shouldReturnCurrentSourceValue() {
        assertIsSubmittingReceiptAfterPurchase(true)
        
        assertIsSubmittingReceiptAfterPurchase(false)
    }
    
    private func assertIsSubmittingReceiptAfterPurchase(_ value: Bool) {
        let currentUserSource = CurrentUserSource(sdk: MockSdk())
        let sut = makeSUT(currentUserSource: currentUserSource)
        currentUserSource.monitorSubmitReceiptAfterPurchaseSourcePublisher.send(value)
        
        XCTAssertEqual(sut.isSubmittingReceiptAfterPurchase, value)
    }

    func testMonitorSubmitReceiptAfterPurchase_shouldPublishChanges() {
        let currentUserSource = CurrentUserSource(sdk: MockSdk())
        let sut = makeSUT(currentUserSource: currentUserSource)
        var receivedValues: [Bool] = []
        
        let expectation = expectation(description: "Should receive monitoring state changes")
        expectation.expectedFulfillmentCount = 2
        let cancellable = sut.monitorSubmitReceiptAfterPurchase
            .dropFirst()
            .sink {
                receivedValues.append($0)
                expectation.fulfill()
            }

        currentUserSource.monitorSubmitReceiptAfterPurchaseSourcePublisher.send(true)
        currentUserSource.monitorSubmitReceiptAfterPurchaseSourcePublisher.send(false)
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertEqual(receivedValues, [true, false], "Publisher should emit correct sequence")
        
        cancellable.cancel()
    }
    
    func testSuccessSubmitReceipt_whenCalled_shouldEmitSubmitReceiptResultAndUpdateMonitorSubmitReceipt() {
        let sut = makeSUT(purchase: MockMEGAPurchase(isSubmittingReceipt: false))
        
        let exp = expectation(description: "Should receive success submit receipt result")
        sut.submitReceiptResultPublisher
            .sink { result in
                if case .failure = result {
                    XCTFail("Expected success, but received failure: \(result)")
                }
                exp.fulfill()
            }
            .store(in: &subscriptions)
        
        sut.successSubmitReceipt()
        
        wait(for: [exp], timeout: 1)
        XCTAssertEqual(sut.isSubmittingReceiptAfterPurchase, false)
    }
    
    // MARK: - Helper
    private func makeSUT(
        purchase: MockMEGAPurchase = MockMEGAPurchase(),
        sdk: MockSdk = MockSdk(),
        currentUserSource: CurrentUserSource = CurrentUserSource(sdk: MockSdk())
    ) -> AccountPlanPurchaseRepository {
        AccountPlanPurchaseRepository(
            purchase: purchase,
            sdk: sdk,
            currentUserSource: currentUserSource
        )
    }
}
