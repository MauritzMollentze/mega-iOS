import MEGAAppPresentation
import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAL10n
import UIKit

enum SortingAndViewSection: Int {
    case sortingPreference = 0
    case viewModePreference = 1
}

class SortingAndViewModeTableViewController: UITableViewController {
    
    @IBOutlet weak var sortingPreferencePerFolderLabel: UILabel!
    @IBOutlet weak var sortingPreferenceSameForAllLabel: UILabel!
    @IBOutlet weak var sortingPreferenceSameForAllDetailLabel: UILabel!
    
    @IBOutlet weak var viewModePreferencePerFolderLabel: UILabel!
    @IBOutlet weak var viewModePreferenceListViewLabel: UILabel!
    @IBOutlet weak var viewModePreferenceThumbnailViewLabel: UILabel!
    
    var sortingPreference = UserDefaults.standard.integer(forKey: MEGASortingPreference)
    var viewModePreference = UserDefaults.standard.integer(forKey: MEGAViewModePreference)
    
    let localizedSortByStringsArray = [Strings.Localizable.nameAscending,
                                       Strings.Localizable.nameDescending,
                                       Strings.Localizable.largest,
                                       Strings.Localizable.smallest,
                                       Strings.Localizable.newest,
                                       Strings.Localizable.oldest]
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = Strings.Localizable.sortingAndViewMode
        
        sortingPreferencePerFolderLabel.text = Strings.Localizable.perFolder
        sortingPreferenceSameForAllLabel.text = Strings.Localizable.sameForAll
        sortingPreferenceSameForAllDetailLabel.text = Strings.Localizable.General.choose
        
        viewModePreferencePerFolderLabel.text = Strings.Localizable.perFolder
        viewModePreferenceListViewLabel.text = Strings.Localizable.listView
        viewModePreferenceThumbnailViewLabel.text = Strings.Localizable.thumbnailView
        
        setupColors()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(processSortingPreferenceNotification(_:)), name: Notification.Name(MEGASortingPreference), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(processViewModePreferenceNotification(_:)), name: .MEGAViewModePreferenceDidChange, object: nil)
        
        setupUI()
    }
    
    // MARK: - Private
    
    private func setupColors() {
        sortingPreferenceSameForAllDetailLabel.textColor = UIColor.secondaryLabel
        
        tableView.separatorColor = TokenColors.Border.strong
        tableView.backgroundColor = TokenColors.Background.page

        sortingPreferencePerFolderLabel.textColor = TokenColors.Text.primary
        sortingPreferenceSameForAllLabel.textColor = TokenColors.Text.primary
        sortingPreferenceSameForAllDetailLabel.textColor = TokenColors.Text.secondary
        viewModePreferencePerFolderLabel.textColor = TokenColors.Text.primary
        viewModePreferenceListViewLabel.textColor = TokenColors.Text.primary
        viewModePreferenceThumbnailViewLabel.textColor = TokenColors.Text.primary
    }
    
    private func setupUI() {
        sortingPreference = UserDefaults.standard.integer(forKey: MEGASortingPreference)
        switch sortingPreference {
        case SortingPreference.perFolder.rawValue:
            let selectedSortingPreferenceCell = tableView.cellForRow(at: IndexPath.init(row: sortingPreference, section: SortingAndViewSection.sortingPreference.rawValue)) as! SelectableTableViewCell
            selectedSortingPreferenceCell.redCheckmarkImageView.isHidden = false
            
        case SortingPreference.sameForAll.rawValue:
            setupSortingPreferenceSameForAllDetailLabel(orderType: UserDefaults.standard.integer(forKey: MEGASortingPreferenceType))
            
        default:
            return
        }
        
        viewModePreference = UserDefaults.standard.integer(forKey: MEGAViewModePreference)
        let selectedViewModePreferenceCell = tableView.cellForRow(at: IndexPath.init(row: viewModePreference, section: SortingAndViewSection.viewModePreference.rawValue)) as! SelectableTableViewCell
        selectedViewModePreferenceCell.redCheckmarkImageView.isHidden = false
    }
    
    @objc func processSortingPreferenceNotification(_ notification: Notification) {
        let selectedSortingPreference = notification.userInfo?[MEGASortingPreference] as! Int
        if selectedSortingPreference == SortingPreference.sameForAll.rawValue && sortingPreference != selectedSortingPreference {
            let previousSelectedViewModePreferenceCell = tableView.cellForRow(at: IndexPath.init(row: sortingPreference, section: SortingAndViewSection.sortingPreference.rawValue)) as! SelectableTableViewCell
            previousSelectedViewModePreferenceCell.redCheckmarkImageView.isHidden = true
        }
        
        sortingPreference = selectedSortingPreference
        setupSortingPreferenceSameForAllDetailLabel(orderType: UserDefaults.standard.integer(forKey: MEGASortingPreferenceType))
    }
    
    @objc func processViewModePreferenceNotification(_ notification: Notification) {
        let updatedViewModePreference = UserDefaults.standard.integer(forKey: MEGAViewModePreference)
        guard updatedViewModePreference != viewModePreference else { return }

        let previousSelectedViewModePreferenceCell = tableView.cellForRow(at: IndexPath.init(row: viewModePreference, section: SortingAndViewSection.viewModePreference.rawValue)) as! SelectableTableViewCell
        previousSelectedViewModePreferenceCell.redCheckmarkImageView.isHidden = true
        
        viewModePreference = updatedViewModePreference

        let selectedViewModePreferenceCell = tableView.cellForRow(at: IndexPath.init(row: viewModePreference, section: SortingAndViewSection.viewModePreference.rawValue)) as! SelectableTableViewCell
        selectedViewModePreferenceCell.redCheckmarkImageView.isHidden = false
    }
    
    private func setupSortingPreferenceSameForAllDetailLabel(orderType: Int) {
        var orderTypeIndex: Int
        switch orderType {
        case MEGASortOrderType.defaultAsc.rawValue:
            orderTypeIndex = 0
            
        case MEGASortOrderType.defaultDesc.rawValue:
            orderTypeIndex = 1
            
        case MEGASortOrderType.sizeDesc.rawValue:
            orderTypeIndex = 2
            
        case MEGASortOrderType.sizeAsc.rawValue:
            orderTypeIndex = 3
            
        case MEGASortOrderType.modificationDesc.rawValue:
            orderTypeIndex = 4
            
        case MEGASortOrderType.modificationAsc.rawValue:
            orderTypeIndex = 5
            
        default:
            orderTypeIndex = 0
        }
        
        sortingPreferenceSameForAllDetailLabel.text = localizedSortByStringsArray[orderTypeIndex]
    }
    
    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = TokenColors.Background.page
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        configureTableViewHeaderStyleWithSentenceCase(view, forSection: section)
    }
    
    private func configureTableViewHeaderStyleWithSentenceCase(_ view: UIView, forSection section: Int) {
        guard let tableViewHeaderFooterView = view as? UITableViewHeaderFooterView
        else { return }

        tableViewHeaderFooterView.textLabel?.text = titleForHeader(in: section)
        tableViewHeaderFooterView.textLabel?.textColor = TokenColors.Text.secondary
    }

    override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        guard let tableViewHeaderFooterView = view as? UITableViewHeaderFooterView
        else { return }

        tableViewHeaderFooterView.textLabel?.textColor = TokenColors.Text.secondary
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        titleForHeader(in: section)
    }
    
    private func titleForHeader(in section: Int) -> String? {
        switch SortingAndViewSection(rawValue: section) {
        case .sortingPreference:
            return Strings.Localizable.sortingPreference
        case .viewModePreference:
            return Strings.Localizable.viewModePreference
        case nil:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case SortingAndViewSection.sortingPreference.rawValue:
            return Strings.Localizable.configureColumnSortingOrderOnAPerFolderBasisOrUseTheSameOrderForAllFolders
            
        case SortingAndViewSection.viewModePreference.rawValue:
            return Strings.Localizable.selectViewModeListOrThumbnailOnAPerFolderBasisOrUseTheSameViewModeForAllFolders
            
        default:
            return nil
        }
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.section {
        case SortingAndViewSection.sortingPreference.rawValue:
            if indexPath.row == SortingPreference.perFolder.rawValue {
                if sortingPreference == indexPath.row {
                    return
                }
                
                let selectedSortingPreferenceCell = tableView.cellForRow(at: IndexPath.init(row: indexPath.row, section: SortingAndViewSection.sortingPreference.rawValue)) as! SelectableTableViewCell
                selectedSortingPreferenceCell.redCheckmarkImageView.isHidden = false
                
                sortingPreference = indexPath.row
                UserDefaults.standard.set(sortingPreference, forKey: MEGASortingPreference)
                
                sortingPreferenceSameForAllDetailLabel.text = Strings.Localizable.General.choose
            } else {
                var actions = [ActionSheetAction]()
                let sortType = Helper.sortType(for: nil)
                let checkmarkImageView = UIImageView(image: MEGAAssets.UIImage.turquoiseCheckmark)
    
                actions.append(ActionSheetAction(title: Strings.Localizable.nameAscending, detail: nil, accessoryView: sortType == .defaultAsc ? checkmarkImageView : nil, image: MEGAAssets.UIImage.ascending, style: .default) {
                    Helper.save(.defaultAsc, for: nil)
                })
                actions.append(ActionSheetAction(title: Strings.Localizable.nameDescending, detail: nil, accessoryView: sortType == .defaultDesc ? checkmarkImageView : nil, image: MEGAAssets.UIImage.descending, style: .default) {
                    Helper.save(.defaultDesc, for: nil)
                })
                actions.append(ActionSheetAction(title: Strings.Localizable.largest, detail: nil, accessoryView: sortType == .sizeDesc ? checkmarkImageView : nil, image: MEGAAssets.UIImage.largest, style: .default) {
                    Helper.save(.sizeDesc, for: nil)
                })
                actions.append(ActionSheetAction(title: Strings.Localizable.smallest, detail: nil, accessoryView: sortType == .sizeAsc ? checkmarkImageView : nil, image: MEGAAssets.UIImage.smallest, style: .default) {
                    Helper.save(.sizeAsc, for: nil)
                })
                actions.append(ActionSheetAction(title: Strings.Localizable.newest, detail: nil, accessoryView: sortType == .modificationDesc ? checkmarkImageView : nil, image: MEGAAssets.UIImage.newest, style: .default) {
                    Helper.save(.modificationDesc, for: nil)
                })
                actions.append(ActionSheetAction(title: Strings.Localizable.oldest, detail: nil, accessoryView: sortType == .modificationAsc ? checkmarkImageView : nil, image: MEGAAssets.UIImage.oldest, style: .default) {
                    Helper.save(.modificationAsc, for: nil)
                })
                
                let sortByActionSheet = ActionSheetViewController(actions: actions, headerTitle: nil, dismissCompletion: nil, sender: tableView.cellForRow(at: indexPath))
                present(sortByActionSheet, animated: true, completion: nil)
            }
            
        case SortingAndViewSection.viewModePreference.rawValue:
            if viewModePreference == indexPath.row {
                return
            }
            
            UserDefaults.standard.set(indexPath.row, forKey: MEGAViewModePreference)
            
            if let viewMode = ViewModePreferenceEntity(rawValue: indexPath.row) {
                NotificationCenter.default.post(viewMode: viewMode)
            }
            
        default:
            return
        }
    }
}
