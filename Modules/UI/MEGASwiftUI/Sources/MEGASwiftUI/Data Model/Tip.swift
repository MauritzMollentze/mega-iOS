import Foundation

public struct Tip {
    let title: String
    let message: String
    let buttonTitle: String
    let buttonAction: (() -> Void)?
    
    public init(title: String,
                message: String,
                buttonTitle: String,
                buttonAction: (() -> Void)?) {
        self.title = title
        self.message = message
        self.buttonTitle = buttonTitle
        self.buttonAction = buttonAction
    }
}
