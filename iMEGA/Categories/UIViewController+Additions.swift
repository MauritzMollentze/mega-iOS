
import Foundation

extension UIViewController {
    
    static var isAlreadyPresented: Bool {
        var presentedViewController: UIViewController? = UIApplication.mnz_presentingViewController()
        if presentedViewController is Self {
            return true
        } else {
            while presentedViewController?.presentingViewController != nil {
                presentedViewController = presentedViewController?.presentingViewController
                if presentedViewController is Self {
                    return true
                }
            }
        }
        
        return false
    }
    
    @objc func add(_ child: UIViewController, container: UIView, animate: Bool = true) {
        if animate {
            UIView.transition(with: view, duration: 0.5, options: .transitionCrossDissolve, animations: {
                self.add(child: child, container: container)
            })
        } else {
            add(child: child, container: container)
        }
    }
    
    private func add(child: UIViewController, container: UIView) {
        addChild(child)
        
        child.view.frame = CGRect(x: 0, y: 0, width: container.frame.width, height: container.frame.height)
        child.view.alpha = 1
        container.addSubview(child.view)
        child.didMove(toParent: self)
        
        addConstraints(child.view, in: container)
    }
    
    private func addConstraints(_ contentView: UIView, in container: UIView) {
        contentView.translatesAutoresizingMaskIntoConstraints = false
        container.addConstraints([
            NSLayoutConstraint(item: container, attribute: .centerX, relatedBy: .equal, toItem: contentView, attribute: .centerX, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: container, attribute: .centerY, relatedBy: .equal, toItem: contentView, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: container, attribute: .width, relatedBy: .equal, toItem: contentView, attribute: .width, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: container, attribute: .height, relatedBy: .equal, toItem: contentView, attribute: .height, multiplier: 1.0, constant: 0.0)
        ])
    }
    
    /// A Boolean value indicating whether the view is currently loaded into memory and the view has been added to a window.
    @objc func isViewReady() -> Bool {
        isViewLoaded && (view.window != nil)
    }
}
