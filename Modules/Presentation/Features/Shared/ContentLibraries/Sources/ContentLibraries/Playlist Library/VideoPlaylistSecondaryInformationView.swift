import MEGAAssets
import MEGADesignToken
import SwiftUI

public struct VideoPlaylistSecondaryInformationView: View {
    private let videosCount: String
    private let totalDuration: String
    private let isPublicLink: Bool
    private let layoutIgnoringOrientation: Bool
    private let isDisabled: Bool
    
    @State private var isPortrait = true
    
    public init(
        videosCount: String,
        totalDuration: String,
        isPublicLink: Bool,
        layoutIgnoringOrientation: Bool,
        isDisabled: Bool = false
    ) {
        self.videosCount = videosCount
        self.totalDuration = totalDuration
        self.isPublicLink = isPublicLink
        self.layoutIgnoringOrientation = layoutIgnoringOrientation
        self.isDisabled = isDisabled
    }
    
    public var body: some View {
        content
            .onOrientationChanged { newOrientation in
                isPortrait = newOrientation.isPortrait
            }
    }
    
    @ViewBuilder
    private var content: some View {
        if layoutIgnoringOrientation || isPortrait {
            horizontalLayoutContent
        } else {
            verticalLayoutContent
        }
    }
    
    private var horizontalLayoutContent: some View {
        HStack(spacing: TokenSpacing._3) {
            secondaryText(text: videosCount)
            
            circleSeparatorImage
            
            secondaryText(text: totalDuration)
            
            circleSeparatorImage
                .opacity(isPublicLink ? 1 : 0)
            
            MEGAAssets.Image.linked
                .foregroundStyle(isDisabled ? TokenColors.Text.disabled.swiftUI : TokenColors.Text.secondary.swiftUI)
                .opacity(isPublicLink ? 1 : 0)
        }
    }
    
    private var verticalLayoutContent: some View {
        VStack(alignment: .leading, spacing: TokenSpacing._3) {
            secondaryText(text: videosCount)
            
            secondaryText(text: totalDuration)
            
            MEGAAssets.Image.linked
                .foregroundStyle(isDisabled ? TokenColors.Text.disabled.swiftUI : TokenColors.Text.secondary.swiftUI)
                .opacity(isPublicLink ? 1 : 0)
        }
    }
    
    private func secondaryText(text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(isDisabled ? TokenColors.Text.disabled.swiftUI : TokenColors.Text.secondary.swiftUI)
    }
    
    private var circleSeparatorImage: some View {
        Image(systemName: "circle.fill")
            .renderingMode(.template)
            .resizable()
            .frame(width: 4, height: 4)
            .foregroundStyle(isDisabled ? TokenColors.Text.disabled.swiftUI : TokenColors.Icon.secondary.swiftUI)
    }
}

#Preview {
    VideoPlaylistSecondaryInformationView(
        videosCount: "24 videos",
        totalDuration: "3:05:20",
        isPublicLink: true,
        layoutIgnoringOrientation: true,
        isDisabled: false
    )
}

#Preview {
    VideoPlaylistSecondaryInformationView(
        videosCount: "24 videos",
        totalDuration: "3:05:20",
        isPublicLink: false,
        layoutIgnoringOrientation: true,
        isDisabled: false
    )
    .preferredColorScheme(.dark)
}

@available(iOS 17.0, *)
#Preview(traits: .landscapeLeft) {
    VideoPlaylistSecondaryInformationView(
        videosCount: "24 videos",
        totalDuration: "3:05:20",
        isPublicLink: false,
        layoutIgnoringOrientation: false,
        isDisabled: false
    )
    .preferredColorScheme(.dark)
}
