import Foundation

extension GetLinkViewController: SnackBarPresenting {
    @MainActor
    func layout(snackBarView: UIView?) {
        snackBarContainer?.removeFromSuperview()
        snackBarContainer = snackBarView
        snackBarContainer?.backgroundColor = .clear

        guard let snackBarView else {
            return
        }

        snackBarView.translatesAutoresizingMaskIntoConstraints = false

        [snackBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
         snackBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
         snackBarView.bottomAnchor.constraint(equalTo: view.bottomAnchor)].activate()
    }

    func snackBarContainerView() -> UIView? {
        snackBarContainer
    }

    @objc func configureSnackBarPresenter() {
        SnackBarRouter.shared.configurePresenter(self)
    }

    @objc func removeSnackBarPresenter() {
        SnackBarRouter.shared.removePresenter()
    }
}