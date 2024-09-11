import Combine
import MEGADesignToken
import MEGAPresentation
import MEGASwiftUI
import SwiftUI

struct PageTabView: View {
    @ObservedObject private var viewModel: PagerTabViewModel
    @Environment(\.colorScheme) var colorScheme
    
    private var tabForgroundColor: Color {
        if !viewModel.isEditing {
            return TokenColors.Text.primary.swiftUI
        } else {
            return TokenColors.Text.primary.swiftUI
        }
    }
    
    init(viewModel: PagerTabViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 10) {
                HStack {
                    Button {
                        withAnimation {
                            viewModel.tabOffset = 0
                            viewModel.selectedTab = .timeline
                        }
                    } label: {
                        Text(viewModel.timeLineTitle)
                            .font(Font.system(.subheadline, design: .default).weight(.medium))
                            .frame(maxWidth: proxy.size.width, alignment: .center)
                            .foregroundColor(viewModel.selectedTab == .timeline ? TokenColors.Button.brand.swiftUI : tabForgroundColor)
                    }
                    
                    Button {
                        withAnimation {
                            viewModel.tabOffset = proxy.size.width / 2
                            viewModel.selectedTab = .album
                        }
                        
                    } label: {
                        Text(viewModel.albumsTitle)
                            .font(Font.system(.subheadline, design: .default).weight(.medium))
                            .frame(maxWidth: proxy.size.width, alignment: .center)
                            .foregroundColor(viewModel.selectedTab == .album ? TokenColors.Button.brand.swiftUI : tabForgroundColor)
                    }
                }
                .padding(.vertical, 10)
            }
            .frame(height: 40)
            .background(TokenColors.Background.surface1.swiftUI)
            .overlay(
                BottomIndicator(width: proxy.size.width, height: 1, offset: viewModel.tabOffset, color: TokenColors.Button.brand.swiftUI),
                alignment: .bottom
            )
        }
        .ignoresSafeArea()
    }
}
