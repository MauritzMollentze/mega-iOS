import ChatRepo
import MEGAAppSDKRepo
import MEGAAssets
import MEGADesignToken
import MEGADomain
import UIKit

class ContactsGroupTableViewCell: UITableViewCell {

    @IBOutlet weak var backAvatarImage: UIImageView!
    @IBOutlet weak var frontAvatarImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var keyRotationImage: UIImageView!
    
    private var viewModel: ContactsGroupCellViewModel?
    
    func configure(
        with chatListItem: ChatListItemEntity
    ) {
        viewModel = ContactsGroupCellViewModel(
            chatListItem: chatListItem,
            chatRoomUseCase: ChatRoomUseCase(chatRoomRepo: ChatRoomRepository.newRepo),
            accountUseCase: AccountUseCase(repository: AccountRepository.newRepo)
        )
        
        titleLabel.text = viewModel?.title
        keyRotationImage.isHidden = viewModel?.isKeyRotationImageHidden ?? false
        
        configureAvatarImages()
    }
    
    private func configureAvatarImages() {
        guard let viewModel = viewModel else { return }
        
        backAvatarImage.mnz_setImage(forUserHandle: viewModel.backAvatarHandle)
        frontAvatarImage.mnz_setImage(forUserHandle: viewModel.frontAvatarHandle)
        frontAvatarImage.borderColor = TokenColors.Background.page
    }
    
    private func updateStyle() {
        backgroundColor = TokenColors.Background.page
        titleLabel.textColor = TokenColors.Text.primary
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        updateStyle()
        keyRotationImage.image = MEGAAssets.UIImage.image(named: "privateChat")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        updateStyle()
    }
}
