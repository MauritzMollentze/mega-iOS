#import <UIKit/UIKit.h>

@class MegaAvatarView, ItemCollectionViewCellViewModel;

@interface ItemCollectionViewCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UIImageView *thumbnailPlayImageView;
@property (weak, nonatomic) IBOutlet UIImageView *contactVerifiedImageView;

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;

@property (weak, nonatomic) IBOutlet UILabel *videoDurationLabel;

@property (weak, nonatomic) IBOutlet UIView *videoOverlayView;

@property (weak, nonatomic) IBOutlet UIButton *removeUserButton;

@property (weak, nonatomic) IBOutlet MegaAvatarView *avatarView;

@property (strong, nonatomic) ItemCollectionViewCellViewModel *viewModel;
@property (strong, nonatomic) NSSet<id> *cancellables;

@end
