import MEGAL10n
import SwiftUI

struct AutoMediaDiscoveryBannerView: View {
    @Binding var showBanner: Bool
    var onDismiss: (() -> Void)?
    
    @Environment(\.colorScheme) private var colorScheme
    
    private enum Constants {
        static let descriptionTextVerticalPadding: CGFloat = 14
        static let defaultPadding: CGFloat = 16
        static let bannerBorderWidth = 0.5
        static let bannerBorderOpacityDarkMode = 0.65
        static let bannerBorderOpacityLightMode = 0.3
    }
    
    var body: some View {
        HStack(spacing: .zero) {
            bannerDescription
            closeButton
        }
        .background(bannerBackgroundColor)
        .border(bannerBorderColor,
                width: Constants.bannerBorderWidth)
    }
    
    private var bannerDescription: some View {
        Text(Strings.Localizable.Photos.MediaDiscovery.AutoMediaDiscoveryBanner.title)
            .font(Font.system(size: 12, weight: .regular, design: Font.Design.default))
            .padding(.vertical, Constants.descriptionTextVerticalPadding)
            .padding(.horizontal, Constants.defaultPadding)
            .frame(maxWidth: .infinity)
    }
    
    private var closeButton: some View {
        Button {
            withAnimation {
                showBanner = false
                onDismiss?()
            }
        } label: {
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(closeImageColor)
        }
        .padding(.trailing, Constants.defaultPadding)
    }
    
    private var closeImageColor: Color {
        Color(colorScheme == .dark ? UIColor.grayD1D1D1 :
                UIColor.gray515151)
    }
    
    private var bannerBackgroundColor: Color {
        Color(colorScheme == .dark ? UIColor.black2C2C2E :
                UIColor.whiteFFFFFF)
    }
    
    private var bannerBorderColor: Color {
        colorScheme == .dark ? Color(UIColor.gray545458).opacity(Constants.bannerBorderOpacityDarkMode) :
        Color(UIColor.gray3C3C43).opacity(Constants.bannerBorderOpacityLightMode)
    }
}

struct AutoMediaDiscoveryBannerView_Previews: PreviewProvider {
    static var previews: some View {
        AutoMediaDiscoveryBannerView(showBanner: .constant(true))
        .previewLayout(.sizeThatFits)
    }
}
