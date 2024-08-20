import SwiftUI

final class CancellationSurveyViewModel: ObservableObject {
    @Published var shouldDismiss: Bool = false
    @Published var selectedReason: CancellationSurveyReason?
    @Published var cancellationSurveyReasonList: [CancellationSurveyReason] = []
    @Published var otherReasonText: String = ""
    @Published var isOtherFieldFocused: Bool = false
    @Published var allowToBeContacted: Bool = false
    @Published var showNoReasonSelectedError: Bool = false
    
    let otherReasonID = CancellationSurveyReason.otherReason.id
    let minimumTextRequired = 10
    let maximumTextRequired = 120
    private let cancelAccountPlanRouter: any CancelAccountPlanRouting
    
    init(cancelAccountPlanRouter: some CancelAccountPlanRouting) {
        self.cancelAccountPlanRouter = cancelAccountPlanRouter
    }
    
    @MainActor
    func setupRandomizedReasonList() {
        let otherReasonItem = CancellationSurveyReason.eight
        let cancellationReasons = CancellationSurveyReason.allCases.filter({ $0 != otherReasonItem })
        
        var randomizedList = cancellationReasons.shuffled()
        randomizedList.append(otherReasonItem)
        
        cancellationSurveyReasonList = randomizedList
    }
    
    @MainActor
    func selectReason(_ reason: CancellationSurveyReason) {
        selectedReason = reason
        isOtherFieldFocused = !reason.isOtherReason
        showNoReasonSelectedError = false
    }
    
    func isReasonSelected(_ reason: CancellationSurveyReason) -> Bool {
        selectedReason?.id == reason.id
    }
    
    func didTapCancelButton() {
        dismissView()
    }
    
    func didTapDontCancelButton() {
        dismissView()
        cancelAccountPlanRouter.dismissCancellationFlow()
    }
    
    func didTapCancelSubscriptionButton() {
        guard let selectedReason else {
            showNoReasonSelectedError = true
            return
        }

        if selectedReason.isOtherReason,
            otherReasonText.isEmpty {
            isOtherFieldFocused = true
            return
        }

        cancelAccountPlanRouter.showAppleManageSubscriptions()
    }
    
    private func dismissView() {
        Task { @MainActor in
            shouldDismiss = true
        }
    }
}
