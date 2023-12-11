import Foundation
import MEGADomain
import MEGAL10n

protocol ActionSheetFactoryProtocol {

    func nodeLabelColorView(forNode nodeHandle: HandleEntity,
                            completion: ((Result<ActionSheetViewController, NodeLabelActionDomainError>) -> Void)?)
}

struct ActionSheetFactory: ActionSheetFactoryProtocol {

    private let nodeLabelActionUseCase: any NodeLabelActionUseCaseProtocol

    init(
        nodeLabelActionUseCase: some NodeLabelActionUseCaseProtocol
            = NodeLabelActionUseCase(nodeLabelActionRepository: NodeLabelActionRepository())
    ) {
        self.nodeLabelActionUseCase = nodeLabelActionUseCase
    }

    func nodeLabelColorView(forNode nodeHandle: HandleEntity,
                            completion: ((Result<ActionSheetViewController, NodeLabelActionDomainError>) -> Void)?) {
        nodeLabelColorActions(forNode: nodeHandle) { (actionsResult) in
            let viewControllerResult = actionsResult.map {
                ActionSheetViewController(actions: $0, headerTitle: nil, dismissCompletion: nil, sender: nil)
            }
            completion?(viewControllerResult)
        }
    }

    private func nodeLabelColorActions(
        forNode nodeHandle: HandleEntity,
        completion: ((Result<[BaseAction], NodeLabelActionDomainError>) -> Void)?
    ) {
        nodeLabelActionUseCase.nodeLabelColor(forNode: nodeHandle) { (colorResult) in
            switch colorResult {
            case .failure(let error):
                completion?(.failure(error))
            case .success(let nodeCurrentColor):
                let allLabelColors = nodeLabelActionUseCase.labelColors
                let actionSheetActions = allLabelColors.compactMap { (color) -> BaseAction? in
                    nodeLabelActions(
                        forNode: nodeHandle,
                        ofColor: color,
                        currentLabelColor: nodeCurrentColor
                    )
                }
                completion?(.success(actionSheetActions))
            }
        }
    }

    private func nodeLabelActions(
        forNode nodeHandle: HandleEntity,
        ofColor labelColor: NodeLabelColor,
        currentLabelColor: NodeLabelColor
    ) -> BaseAction? {
        switch labelColor == currentLabelColor {
        case true:
            if currentLabelColor == .unknown {
                return nil
            } else {
                let checkMarkImageView = UIImageView.init(image: UIImage.turquoiseCheckmark)
                return ActionSheetAction(
                    title: labelColor.localizedTitle,
                    detail: nil,
                    accessoryView: checkMarkImageView,
                    image: labelColor.iconImage,
                    style: .default,
                    actionHandler: { [nodeLabelActionUseCase] in
                        nodeLabelActionUseCase.resetNodeLabelColor(forNode: nodeHandle, completion: nil)
                    }
                )
            }
        case false:
            return ActionSheetAction(
                title: labelColor.localizedTitle,
                detail: nil,
                accessoryView: nil,
                image: labelColor.iconImage,
                style: (labelColor != .unknown) ? .default : .destructive,
                actionHandler: { [nodeLabelActionUseCase] in
                    nodeLabelActionUseCase.setNodeLabelColor(labelColor, forNode: nodeHandle, completion: nil)
                }
            )
        }
    }
}

private extension NodeLabelColor {

    var iconImage: UIImage {
        switch self {
        case .red:
            return UIImage.red
        case .orange:
            return UIImage.orange
        case .yellow:
            return UIImage.yellow
        case .green:
            return UIImage.green
        case .blue:
            return UIImage.blue
        case .purple:
            return UIImage.purple
        case .grey:
            return UIImage.grey
        case .unknown:
            return UIImage.delete
        }
    }

    var localizedTitle: String {
        switch self {
        case .red:
            return Strings.Localizable.red
        case .orange:
            return Strings.Localizable.orange
        case .yellow:
            return Strings.Localizable.yellow
        case .green:
            return Strings.Localizable.green
        case .blue:
            return Strings.Localizable.blue
        case .purple:
            return Strings.Localizable.purple
        case .grey:
            return Strings.Localizable.grey
        case .unknown:
            return Strings.Localizable.removeLabel
        }
    }
}
