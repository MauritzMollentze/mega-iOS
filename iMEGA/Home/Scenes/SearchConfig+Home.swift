import MEGAAppPresentation
import MEGAAssets
import MEGADesignToken
import MEGAL10n
import MEGAUIKit
import Search
import SwiftUI

extension SearchConfig {
    static func searchConfig(
        contextPreviewFactory: ContextPreviewFactory,
        defaultEmptyViewAsset: @escaping () -> EmptyViewAssets
    ) -> SearchConfig {
        return .init(
            chipAssets: .init(
                selectionIndicatorImage: MEGAAssets.UIImage.turquoiseCheckmark,
                closeIcon: MEGAAssets.UIImage.miniplayerClose,
                selectedForeground: TokenColors.Text.inverse.swiftUI,
                selectedBackground: TokenColors.Components.selectionControl.swiftUI,
                normalForeground: TokenColors.Text.primary.swiftUI,
                normalBackground: TokenColors.Button.secondary.swiftUI
            ),
            emptyViewAssetFactory: { chip, query in
                let titleTextColor = TokenColors.Icon.secondary.swiftUI
                
                guard let chip else {
                    guard !query.isSearchActive else {
                        return searchEmptyState(with: titleTextColor)
                    }
                    
                    return defaultEmptyViewAsset()
                }
                
                switch chip.id {
                case SearchChipEntity.docs.id:
                    return .init(
                        image: MEGAAssets.Image.noResultsDocuments,
                        title: Strings.Localizable.Home.Search.Empty.noDocuments,
                        titleTextColor: titleTextColor
                    )
                case SearchChipEntity.audio.id:
                    return .init(
                        image: MEGAAssets.Image.noResultsAudio,
                        title: Strings.Localizable.Home.Search.Empty.noAudio,
                        titleTextColor: titleTextColor
                    )
                case SearchChipEntity.video.id:
                    return .init(
                        image: MEGAAssets.Image.noResultsVideo,
                        title: Strings.Localizable.Home.Search.Empty.noVideos,
                        titleTextColor: titleTextColor
                    )
                case SearchChipEntity.images.id:
                    return .init(
                        image: MEGAAssets.Image.noResultsImages,
                        title: Strings.Localizable.Home.Search.Empty.noImages,
                        titleTextColor: titleTextColor
                    )
                case SearchChipEntity.folders.id:
                    return .init(
                        image: MEGAAssets.Image.noResultsFolders,
                        title: Strings.Localizable.Home.Search.Empty.noFolders,
                        titleTextColor: titleTextColor
                    )
                case SearchChipEntity.pdf.id:
                    return .init(
                        image: MEGAAssets.Image.noResultsDocuments,
                        title: Strings.Localizable.Home.Search.Empty.noPdfs,
                        titleTextColor: titleTextColor
                    )
                case SearchChipEntity.presentation.id:
                    return .init(
                        image: MEGAAssets.Image.noResultsPresentations,
                        title: Strings.Localizable.Home.Search.Empty.noPresentations,
                        titleTextColor: titleTextColor
                    )
                case SearchChipEntity.archives.id:
                    return .init(
                        image: MEGAAssets.Image.noResultsArchives,
                        title: Strings.Localizable.Home.Search.Empty.noArchives,
                        titleTextColor: titleTextColor
                    )
                case SearchChipEntity.spreadsheets.id:
                    return .init(
                        image: MEGAAssets.Image.noResultsDocuments,
                        title: Strings.Localizable.Home.Search.Empty.noSpreadsheets,
                        titleTextColor: titleTextColor
                    )
                default:
                    break
                }
                
                switch chip.type {
                case .timeFrame:
                    return searchEmptyState(with: titleTextColor)
                default:
                    return defaultEmptyViewAsset()
                }
            },
            rowAssets: .init(
                contextImage: MEGAAssets.UIImage.moreList.withTintColorAsOriginal(TokenColors.Icon.secondary),
                itemSelected: MEGAAssets.UIImage.checkBoxSelectedSemantic,
                itemUnselected: MEGAAssets.UIImage.checkBoxUnselected.withTintColorAsOriginal(TokenColors.Border.strong),
                playImage: MEGAAssets.UIImage.videoList,
                downloadedImage: MEGAAssets.UIImage.downloaded,
                moreList: MEGAAssets.UIImage.moreList.withTintColorAsOriginal(TokenColors.Icon.secondary),
                moreGrid: MEGAAssets.UIImage.moreGrid.withTintColorAsOriginal(TokenColors.Icon.secondary)
            ),
            colorAssets: .init(
                unselectedBorderColor: TokenColors.Border.strong.swiftUI,
                selectedBorderColor: TokenColors.Support.success.swiftUI,
                titleTextColor: UIColor.primaryTextColor().swiftUI,
                subtitleTextColor: TokenColors.Text.secondary.swiftUI,
                nodeDescriptionTextNormalColor: TokenColors.Text.secondary.swiftUI,
                tagsTextColor: UIColor.primaryTextColor().swiftUI,
                textHighlightColor: TokenColors.Notifications.notificationSuccess.swiftUI,
                vibrantColor: TokenColors.Text.error.swiftUI,
                resultPropertyColor: TokenColors.Icon.secondary.swiftUI,
                verticalThumbnailFooterText: TokenColors.Text.primary.swiftUI,
                verticalThumbnailFooterBackground: TokenColors.Background.surface1.swiftUI,
                verticalThumbnailPreviewBackground: TokenColors.Background.surface1.swiftUI,
                verticalThumbnailTopIconsBackground: TokenColors.Background.surface2.swiftUI,
                listRowSeparator: TokenColors.Border.strong.swiftUI,
                checkmarkBackgroundTintColor: TokenColors.Support.success.swiftUI,
                listHeaderTextColor: TokenColors.Text.secondary.swiftUI,
                listHeaderBackgroundColor: TokenColors.Background.page.swiftUI
            ),
            contextPreviewFactory: contextPreviewFactory
        )
    }
    
    private static func searchEmptyState(
        with titleTextColor: Color
    ) -> SearchConfig.EmptyViewAssets {
        .init(
            image: MEGAAssets.Image.searchEmptyState,
            title: Strings.Localizable.Home.Search.Empty.noChipSelected,
            titleTextColor: titleTextColor
        )
    }
}
