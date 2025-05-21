import MEGAAppSDKRepo
import MEGAAssets
import MEGADesignToken
import MEGAL10n
import UIKit

final class VerifyEmailViewController: UIViewController {

    @IBOutlet weak var warningGradientView: UIView!

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var topDescriptionLabel: UILabel!
    @IBOutlet weak var bottomDescriptionLabel: UILabel!
    @IBOutlet weak var hintLabel: UILabel!

    @IBOutlet weak var topSeparatorView: UIView!
    @IBOutlet weak var bottomSeparatorView: UIView!

    @IBOutlet weak var hintButton: UIButton!
    @IBOutlet weak var resendButton: UIButton!
    @IBOutlet weak var logoutButton: UIButton!

    @IBOutlet weak var warningImageView: UIImageView!
    
    // MARK: Lifecyle

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(checkIfBlocked), name:
            UIApplication.willEnterForegroundNotification, object: nil)
        configureUI()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory {
            localizeLabels()
            boldenText()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        addGradientBackground()
    }

    // MARK: Private

    private func configureUI() {
        configureImages()
        localizeLabels()
        boldenText()
        updateAppearance()
    }
    
    private func configureImages() {
        warningImageView.image = MEGAAssets.UIImage.image(named: "warning")
    }
    
    private func updateAppearance() {
        view.backgroundColor = TokenColors.Background.page
        resendButton.backgroundColor = TokenColors.Button.primary
        resendButton.setTitleColor(TokenColors.Text.inverse, for: UIControl.State.normal)
        logoutButton.backgroundColor = TokenColors.Button.secondary
        logoutButton.setTitleColor(TokenColors.Text.accent, for: UIControl.State.normal)

        topSeparatorView.backgroundColor = TokenColors.Border.strong
        hintButton.setTitleColor(TokenColors.Support.success, for: .normal)
        hintButton.backgroundColor = TokenColors.Background.surface3
        bottomSeparatorView.backgroundColor = TokenColors.Border.strong
        
        hintLabel.textColor = TokenColors.Text.secondary
    }

    private func addGradientBackground() {
        let gradient = CAGradientLayer()
        gradient.frame = warningGradientView.bounds
        gradient.colors = [MEGAAssets.UIColor.verifyEmailFirstGradient.cgColor,
                           MEGAAssets.UIColor.verifyEmailSecondGradient.cgColor]
        gradient.locations = [0, 1]
        gradient.startPoint = CGPoint(x: 0.5, y: 0)
        gradient.endPoint = CGPoint(x: 0.5, y: 1)

        warningGradientView.layer.addSublayer(gradient)
    }

    private func boldenText() {
        guard let bottomString = bottomDescriptionLabel.text?.replacingOccurrences(of: "[S]", with: "") else { return }

        let bottomStringComponents = bottomString.components(separatedBy: "[/S]")
        guard let textToBolden = bottomStringComponents.first, let textRegular = bottomStringComponents.last else { return }

        let attributtedString = NSMutableAttributedString(string: textToBolden, attributes: [NSAttributedString.Key.font: UIFont.preferredFont(style: .callout, weight: .semibold)])
        let regularlString = NSAttributedString(string: textRegular, attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .callout)])
        attributtedString.append(regularlString)

        bottomDescriptionLabel.attributedText = attributtedString
    }

    func showWhyIAmBlocked() {
        let customModal = CustomModalAlertViewController.init()

        customModal.image = MEGAAssets.UIImage.lockedAccounts
        customModal.viewTitle = Strings.Localizable.lockedAccounts
        customModal.detail = Strings.Localizable.itIsPossibleThatYouAreUsingTheSamePasswordForYourMEGAAccountAsForOtherServicesAndThatAtLeastOneOfTheseOtherServicesHasSufferedADataBreach + "\n\n" + Strings.Localizable.yourPasswordLeakedAndIsNowBeingUsedByBadActorsToLogIntoYourAccountsIncludingButNotLimitedToYourMEGAAccount
        customModal.dismissButtonTitle = Strings.Localizable.close

        present(customModal, animated: true, completion: nil)
    }

    private func localizeLabels() {
        topDescriptionLabel.text = Strings.Localizable.yourAccountHasBeenTemporarilySuspendedForYourSafety
        bottomDescriptionLabel.text = Strings.Localizable.sPleaseVerifyYourEmailSAndFollowItsStepsToUnlockYourAccount
        resendButton.setTitle(Strings.Localizable.resend, for: .normal)
        logoutButton.setTitle(Strings.Localizable.logoutLabel, for: .normal)
        hintButton.setTitle(Strings.Localizable.whyAmISeeingThis, for: .normal)
        hintLabel.text = Strings.Localizable.emailSent
    }

    @objc private func checkIfBlocked() {
        let whyAmIBlockedRequestDelegate = RequestDelegate { result in
            guard case let .success(request) = result, request.number == 0 else {
                return
            }
            
            if MEGASdk.shared.rootNode == nil {
                guard let session = SAMKeychain.password(forService: "MEGA", account: "sessionV3") else { return }
                let loginRequestDelegate = MEGALoginRequestDelegate.init()
                MEGASdk.shared.fastLogin(withSession: session, delegate: loginRequestDelegate)
            }
            
            self.presentedViewController?.dismiss(animated: true, completion: nil)
            self.dismiss(animated: true, completion: nil)
        }
        MEGASdk.shared.whyAmIBlocked(with: whyAmIBlockedRequestDelegate)
    }

    // MARK: Actions

    @IBAction func tapHintButton(_ sender: Any) {
        showWhyIAmBlocked()
    }

    @IBAction func tapResendButton(_ sender: Any) {
        if MEGAReachabilityManager.isReachableHUDIfNot() {
            SVProgressHUD.show()
            let resendVerificationEmailDelegate = RequestDelegate { result in
                SVProgressHUD.dismiss()
                switch result {
                case .success:
                    self.hintLabel.isHidden = false
                case .failure(let error):
                    if error.type == .apiEArgs {
                        self.hintLabel.isHidden = false
                    } else {
                        SVProgressHUD.showError(withStatus: Strings.Localizable.EmailAlreadySent.pleaseWaitAFewMinutesBeforeTryingAgain)
                    }
                }
            }
            MEGASdk.shared.resendVerificationEmail(with: resendVerificationEmailDelegate)
        }
    }

    @IBAction func tapLogoutButton(_ sender: Any) {
        MEGASdk.shared.logout()
    }
}
