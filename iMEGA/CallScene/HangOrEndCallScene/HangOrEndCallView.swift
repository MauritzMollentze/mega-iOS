import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import SwiftUI

struct HangOrEndCallView: View {
    var viewModel: HangOrEndCallViewModel
    
    private enum Constants {
        static let cornerRadius: CGFloat = 8
        static let shadowOffsetY: CGFloat = 1
        static let shadowOpacity: CGFloat = 0.15
        static let buttonsSpacing: CGFloat = 16
        static let buttonsHeight: CGFloat = 50
        static let buttonsPadding: CGFloat = 36
    }
    
    var body: some View {
        VStack {
            Spacer()
            VStack {
                VStack(spacing: Constants.buttonsSpacing) {
                    Button(action: {
                        viewModel.dispatch(.leaveCall)
                    }, label: {
                        Text(Strings.Localizable.Meetings.LeaveCall.buttonTitle)
                            .font(.headline)
                            .foregroundColor(
                                isDesignTokenEnabled ?
                                    TokenColors.Text.accent.swiftUI :
                                    Color(.green00C29A)
                            )
                            .padding()
                            .frame(maxWidth: .infinity, maxHeight: Constants.buttonsHeight)
                            .background(
                                isDesignTokenEnabled ?
                                    TokenColors.Button.secondary.swiftUI :
                                    Color(.gray363638)
                            )
                            .cornerRadius(Constants.cornerRadius)
                            .shadow(color: shadowColor.opacity(Constants.shadowOpacity), radius: Constants.cornerRadius, x: 0, y: Constants.shadowOffsetY)
                    })
                    
                    Button(action: {
                        viewModel.dispatch(.endCallForAll)
                    }, label: {
                        Text(Strings.Localizable.Meetings.EndForAll.buttonTitle)
                            .font(.headline)
                            .foregroundColor(
                                isDesignTokenEnabled ?
                                    TokenColors.Text.primary.swiftUI :
                                    Color(.whiteFFFFFF)
                            )
                            .padding()
                            .frame(maxWidth: .infinity, maxHeight: Constants.buttonsHeight)
                            .background(
                                isDesignTokenEnabled ?
                                    TokenColors.Components.interactive.swiftUI :
                                    Color(.redFF453A)
                            )
                            .cornerRadius(Constants.cornerRadius)
                            .shadow(color: shadowColor.opacity(Constants.shadowOpacity), radius: Constants.cornerRadius, x: 0, y: Constants.shadowOffsetY)
                    })
                }
                .padding(Constants.buttonsPadding)
            }
            .cornerRadius(Constants.cornerRadius, corners: [.topLeft, .topRight])
            .background((
                isDesignTokenEnabled ?
                    TokenColors.Background.page.swiftUI :
                    Color(.black1C1C1E)
                )
                .edgesIgnoringSafeArea(.bottom)
            )
        }
    }
    
    private var shadowColor: Color {
        isDesignTokenEnabled ?
            TokenColors.Background.page.swiftUI :
            Color(.black000000)
    }
}
