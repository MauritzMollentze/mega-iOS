import SwiftUI

@available(iOS 14.0, *)
struct PhotoLibraryContentView: View {
    @ObservedObject var viewModel: PhotoLibraryContentViewModel
    var router: PhotoLibraryContentViewRouting
    
    var body: some View {
        if viewModel.library.isEmpty {
            ProgressView()
                .scaleEffect(1.5)
        } else {
            if #available(iOS 15.0, *) {
                photoContent()
                    .safeAreaInset(edge: .bottom) {
                        pickerFooter()
                    }
            } else {
                ZStack(alignment: .bottom) {
                    photoContent()
                    pickerFooter()
                }
            }
        }
    }
    
    private func pickerFooter() -> some View {
        viewModePicker()
            .blurryBackground(radius: 7)
            .padding(16)
    }
    
    private func viewModePicker() -> some View {
        Picker("View Mode", selection: $viewModel.selectedMode.animation()) {
            ForEach(PhotoLibraryViewMode.allCases) {
                Text($0.title)
                    .font(.headline)
                    .bold()
                    .tag($0)
            }
        }
    }
    
    @ViewBuilder
    private func photoContent() -> some View {
        ZStack {
            switch viewModel.selectedMode {
            case .year:
                PhotoLibraryYearView(
                    viewModel: PhotoLibraryYearViewModel(libraryViewModel: viewModel),
                    router: router
                )
                    .equatable()
            case .month:
                PhotoLibraryMonthView(
                    viewModel: PhotoLibraryMonthViewModel(libraryViewModel: viewModel),
                    router: router
                )
                    .equatable()
            case .day:
                PhotoLibraryDayView(
                    viewModel: PhotoLibraryDayViewModel(libraryViewModel: viewModel),
                    router: router
                )
                    .equatable()
            case .all:
                EmptyView()
            }
            
            PhotoLibraryAllView(
                viewModel: PhotoLibraryAllViewModel(libraryViewModel: viewModel),
                router: router
            )
                .equatable()
                .opacity(viewModel.selectedMode == .all ? 1 : 0)
                .zIndex(viewModel.selectedMode == .all ? 1 : -1)
        }
    }
    
    private func configSegmentedControlAppearance() {
        UISegmentedControl
            .appearance()
            .setTitleTextAttributes(
                [.font: UIFont.systemFont(ofSize: 15, weight: .semibold),
                 .foregroundColor: UIColor.systemBackground],
                for: .selected
            )
        
        UISegmentedControl
            .appearance()
            .setTitleTextAttributes(
                [.font: UIFont.systemFont(ofSize: 13, weight: .medium),
                 .foregroundColor: UIColor.label],
                for: .normal
            )
        
        UISegmentedControl
            .appearance()
            .selectedSegmentTintColor = UIColor.label.withAlphaComponent(0.4)
    }

}

