import Foundation
import MEGAL10n

enum CookieSettingsSection: Int {
    case acceptCookies
    case essentialCookies
    case performanceAndAnalyticsCookies
    case advertisingCookies
}

class CookieSettingsTableViewController: UITableViewController {
    
    @IBOutlet var saveBarButtonItem: UIBarButtonItem!
    
    @IBOutlet weak var acceptCookiesLabel: UILabel!
    @IBOutlet weak var acceptCookiesSwitch: UISwitch!
    
    @IBOutlet weak var essentialCookiesLabel: UILabel!
    @IBOutlet weak var essentialCookiesDetailLabel: UILabel!
    
    @IBOutlet weak var performanceAndAnalyticsCookiesLabel: UILabel!
    @IBOutlet weak var performanceAndAnalyticsSwitch: UISwitch!
    
    @IBOutlet weak var advertisingCookiesLabel: UILabel!
    @IBOutlet weak var advertisingCookiesSwitch: UISwitch!
    
    @IBOutlet var cookiePolicyBarButtonItem: UIBarButtonItem!
    @IBOutlet var privacyPolicyBarButtonItem: UIBarButtonItem!
    
    var router: CookieSettingsRouter!
    var viewModel: CookieSettingsViewModel!
    
    private var footersArray: [String] = ["", "", "", "", "", ""]
    
    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.invokeCommand = { [weak self] command in
            DispatchQueue.main.async { self?.executeCommand(command) }
        }
        
        configView()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            AppearanceManager.forceNavigationBarUpdate(self.navigationController?.navigationBar ?? UINavigationBar(), traitCollection: traitCollection)
            AppearanceManager.forceToolbarUpdate(self.navigationController?.toolbar ?? UIToolbar(), traitCollection: traitCollection)
            
            updateAppearance()
        }
    }
    
    // MARK: - Execute command
    func executeCommand(_ command: CookieSettingsViewModel.Command) {
        switch command {
        case .configCookieSettings(let cookiesBitmap):
            guard viewModel.isFeatureFlagForInAppAdsEnabled else {
                performanceAndAnalyticsSwitch.setOn(cookiesBitmap.contains(.analytics), animated: false)
                acceptCookiesSwitch.isOn = performanceAndAnalyticsSwitch.isOn
                return
            }
            
            performanceAndAnalyticsSwitch.setOn(cookiesBitmap.contains(.analytics), animated: false)
            advertisingCookiesSwitch.setOn(cookiesBitmap.contains(.ads), animated: false)
            acceptCookiesSwitch.isOn = performanceAndAnalyticsSwitch.isOn && advertisingCookiesSwitch.isOn
            
        case .updateFooters(let array):
            footersArray = array
            tableView.reloadData()
            
        case .cookieSettingsSaved:
            router.dismiss()
            
        case .showResult(let resultCommand):
            executeCommand(resultCommand)
        }
    }
    
    func executeCommand(_ command: CookieSettingsViewModel.Command.ResultCommand) {
        switch command {
        case .success:
            router.dismiss()
            
        case .error(let message):
            SVProgressHUD.showError(withStatus: message)
        }
    }
    
    // MARK: - IBActions
    
    @IBAction func saveTouchUpInside(_ sender: UIBarButtonItem) {
        viewModel.dispatch(.save)
    }
    
    @IBAction func acceptCookiesSwitchValueChanged(_ sender: UISwitch) {
        viewModel.dispatch(.acceptCookiesSwitchValueChanged(sender.isOn))
        
        performanceAndAnalyticsSwitch.setOn(sender.isOn, animated: true)
        
        if viewModel.isFeatureFlagForInAppAdsEnabled {
            advertisingCookiesSwitch.setOn(sender.isOn, animated: true)
        }
    }
    
    @IBAction func performanceAndAnalyticsSwitchValueChanged(_ sender: UISwitch) {
        viewModel.dispatch(.performanceAndAnalyticsSwitchValueChanged(sender.isOn))
    }
    
    @IBAction func advertisingSwitchValueChanged(_ sender: UISwitch) {
        viewModel.dispatch(.advertisingSwitchValueChanged(sender.isOn))
    }
    
    @IBAction func cookiePolicyTouchUpInside(_ sender: UIBarButtonItem) {
        router.didTap(on: .showCookiePolicy)
    }
    
    @IBAction func privacyPolicyTouchUpInside(_ sender: UIBarButtonItem) {
        router.didTap(on: .showPrivacyPolicy)
    }
    
    // MARK: - Private
    
    private func configView() {
        navigationController?.presentationController?.delegate = self
        
        title = Strings.Localizable.General.cookieSettings
        
        saveBarButtonItem.title = Strings.Localizable.save
        self.navigationItem.rightBarButtonItem = saveBarButtonItem
        
        acceptCookiesLabel.text = Strings.Localizable.Dialog.Cookies.accept
        essentialCookiesLabel.text = Strings.Localizable.Settings.Cookies.essential
        essentialCookiesDetailLabel.text = Strings.Localizable.Settings.Cookies.Essential.alwaysOn
        performanceAndAnalyticsCookiesLabel.text = Strings.Localizable.Settings.Cookies.performanceAndAnalytics
        
        if viewModel.isFeatureFlagForInAppAdsEnabled {
            advertisingCookiesLabel.text = Strings.Localizable.Settings.Cookies.advertisingCookies
        }
        
        configToolbar()
        
        viewModel.dispatch(.configView)
        
        updateAppearance()
    }
    
    private func configToolbar() {
        cookiePolicyBarButtonItem.title = Strings.Localizable.General.cookiePolicy
        privacyPolicyBarButtonItem.title = Strings.Localizable.privacyPolicyLabel
        let flexibleBarButtonItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        setToolbarItems([cookiePolicyBarButtonItem, flexibleBarButtonItem, privacyPolicyBarButtonItem], animated: false)
        navigationController?.isToolbarHidden = false
        navigationController?.toolbar.isTranslucent = true
    }
    
    private func updateAppearance() {
        tableView.backgroundColor = .mnz_secondaryBackground(for: traitCollection)
        tableView.separatorColor = .mnz_separator(for: traitCollection)
        
        saveBarButtonItem.tintColor = .mnz_primaryGray(for: traitCollection)
        
        essentialCookiesDetailLabel.textColor = .mnz_secondaryLabel()
        
        tableView.reloadData()
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = .mnz_tertiaryBackground(traitCollection)
    }
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        viewModel.numberOfSection
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case CookieSettingsSection.acceptCookies.rawValue:
            return viewModel.isFeatureFlagForInAppAdsEnabled ? "" : footersArray[CookieSettingsSection.acceptCookies.rawValue]
            
        case CookieSettingsSection.essentialCookies.rawValue:
            return footersArray[CookieSettingsSection.essentialCookies.rawValue]
            
        case CookieSettingsSection.performanceAndAnalyticsCookies.rawValue:
            return footersArray[CookieSettingsSection.performanceAndAnalyticsCookies.rawValue]
            
        case CookieSettingsSection.advertisingCookies.rawValue:
            return viewModel.isFeatureFlagForInAppAdsEnabled ? footersArray[CookieSettingsSection.advertisingCookies.rawValue] : ""
            
        default:
            return ""
        }
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate

extension CookieSettingsTableViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        return false
    }
}
