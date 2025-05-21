import Foundation
import MEGAAssets
import MEGADesignToken
import MEGAL10n

class ContactsTableViewHeader: UIView {
    @objc var navigationController: UINavigationController!
    
    @IBOutlet weak var disclosureIndicatorRequestImageView: UIImageView!
    @IBOutlet weak var disclosureIndicatorGroupsImageView: UIImageView!
    @IBOutlet weak var requestsImageView: UIImageView!
    @IBOutlet weak var requestsLabel: UILabel!
    @IBOutlet weak var requestsDetailLabel: UILabel!
    @IBOutlet weak var requestsSeparatorView: UIView!
    
    @IBOutlet weak var groupsImageView: UIImageView!
    @IBOutlet weak var groupsLabel: UILabel!
    
    @IBOutlet weak var requestsTapGestureRecognizer: UITapGestureRecognizer!
    @IBOutlet weak var groupsTapGestureRecognizer: UITapGestureRecognizer!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        requestsLabel.text = Strings.Localizable.requests
        groupsLabel.text = Strings.Localizable.groups
        
        configDetailsLabel()
        setupColors()
        
        disclosureIndicatorRequestImageView.image?.withRenderingMode(.alwaysTemplate)
        disclosureIndicatorRequestImageView.tintColor = TokenColors.Icon.secondary
        disclosureIndicatorGroupsImageView.image?.withRenderingMode(.alwaysTemplate)
        disclosureIndicatorGroupsImageView.tintColor = TokenColors.Icon.secondary
    }
    
    // MARK: - Private
    
    private func setupColors() {
        backgroundColor = TokenColors.Background.page
        
        requestsLabel.textColor = TokenColors.Text.primary
        groupsLabel.textColor = TokenColors.Text.primary
        requestsDetailLabel.textColor = TokenColors.Text.secondary
        
        requestsSeparatorView.backgroundColor = TokenColors.Border.strong
        
        requestsImageView.image = MEGAAssets.UIImage.contactRequests.imageFlippedForRightToLeftLayoutDirection()
        groupsImageView.image = MEGAAssets.UIImage.contactGroups.imageFlippedForRightToLeftLayoutDirection()
        disclosureIndicatorRequestImageView.image = MEGAAssets.UIImage.image(named: "standardDisclosureIndicator")
        disclosureIndicatorGroupsImageView.image = MEGAAssets.UIImage.image(named: "standardDisclosureIndicator")
    }
    
    private func configDetailsLabel() {
        let incomingContactsLists = MEGASdk.shared.incomingContactRequests()
        let contactsCount = incomingContactsLists.size
        requestsDetailLabel.text = contactsCount == 0 ? "" : String(contactsCount)
    }
    
    // MARK: - IBAction
    
    @IBAction func requestsTapped(_ sender: UITapGestureRecognizer) {
        let contactRequestsVC = UIStoryboard(name: "Contacts", bundle: nil).instantiateViewController(withIdentifier: "ContactsRequestsViewControllerID")
        
        navigationController.pushViewController(contactRequestsVC, animated: true)
    }
    
    @IBAction func groupsTapped(_ sender: UITapGestureRecognizer) {
        let contactsGroupsVC = UIStoryboard(name: "ContactsGroups", bundle: nil).instantiateViewController(withIdentifier: "ContactsGroupsViewControllerID")
        
        navigationController.pushViewController(contactsGroupsVC, animated: true)
    }
}
