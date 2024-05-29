import ChatRepo
import MEGADomain
import MEGAPresentation
import MEGASDKRepo
import SwiftUI

final class WaitingRoomParticipantsListRouter: WaitingRoomParticipantsListRouting {
    private(set) var presenter: UIViewController
    private let call: CallEntity
    
    init(
        presenter: UIViewController,
        call: CallEntity
    ) {
        self.presenter = presenter
        self.call = call
    }
    
    func build() -> UIViewController {
        let viewModel = WaitingRoomParticipantsListViewModel(
            router: self,
            call: call,
            callUseCase: CallUseCase(repository: CallRepository.newRepo), 
            chatRoomUseCase: ChatRoomUseCase(chatRoomRepo: ChatRoomRepository.newRepo)
        )
        
        let waitingRoomListView = WaitingRoomParticipantsListView(viewModel: viewModel)
        let hostingController = UIHostingController(rootView: waitingRoomListView)
        hostingController.overrideUserInterfaceStyle = .dark
        return hostingController
    }
    
    func start() {
        presenter.present(build(), animated: true)
    }
    
    func dismiss() {
        presenter.dismiss(animated: true)
    }
}
