import SwiftUI

struct NameCollisionView: View {
    @ObservedObject var viewModel: NameCollisionViewModel

    @Environment(\.colorScheme) private var colorScheme
    
    private enum Constants {
        static let verticalSpacing: CGFloat = 12
    }
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Text( Strings.Localizable.NameCollision.DuplicatedItem.title)
                    .font(.headline)
                Spacer()
                Button(Strings.Localizable.cancel) {
                    viewModel.cancelResolveNameCollisions()
                }
                .accentColor(Color.primary)
            }
            .padding()
            
            ScrollView(.vertical) {
                VStack(spacing: Constants.verticalSpacing) {
                    HeaderView(viewModel: HeaderViewModel(isFile: viewModel.duplicatedItem.isFile, name: viewModel.duplicatedItem.name))
                    
                    if !viewModel.duplicatedItem.isFile {
                        ItemView(name: viewModel.duplicatedItem.name, size: viewModel.duplicatedItem.collisionFileSize, date: viewModel.duplicatedItem.collisionFileDate, imageUrl: viewModel.thumbnailCollisionUrl, imagePlaceholder: viewModel.duplicatedItem.itemPlaceholder)
                            .padding()
                    }
                    ActionsView(collisionType: viewModel.collisionType, duplicatedItem: viewModel.duplicatedItem, imageUrl: viewModel.thumbnailUrl, collisionImageUrl: viewModel.thumbnailCollisionUrl, actions: viewModel.actionsForCurrentDuplicatedItem()) { action in
                        viewModel.selectedAction(action)
                    }
                }
            }
        }
        .background(colorScheme == .dark ? Color(Colors.General.Black._1c1c1e.name) : Color(Colors.General.White.f7F7F7.name))
        .onAppear {
            viewModel.onViewAppeared()
        }
    }
}
