import CGtk
import Foundation
import Gtk
import SwiftCrossUI

public class BaseWidget: Gtk.Widget {
    private var leftConstraint: Gtk.ConstraintTarget?
    private var topConstraint: Gtk.ConstraintTarget?
    private var widthConstraint: Gtk.ConstraintTarget?
    private var heightConstraint: Gtk.ConstraintTarget?

    var x = 0 {
        didSet {
            if x != oldValue {
                updateLeftConstraint()
            }
        }
    }

    var y = 0 {
        didSet {
            if y != oldValue {
                updateTopConstraint()
            }
        }
    }

    var width = 0 {
        didSet {
            if width != oldValue {
                updateWidthConstraint()
            }
        }
    }

    var height = 0 {
        didSet {
            if height != oldValue {
                updateHeightConstraint()
            }
        }
    }

    init() {
        super.init(UnsafeMutablePointer<Gtk.Widget>(nil))

        // self.translatesAutoresizingMaskIntoConstraints = false
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) is not used for this view")
    }

    private func updateLeftConstraint() {
        // leftConstraint?.isActive = false
        // guard let superview else { return }
        // leftConstraint = self.leftAnchor.constraint(
        //     equalTo: superview.safeAreaLayoutGuide.leftAnchor, constant: CGFloat(x))
        // leftConstraint!.isActive = true
    }

    private func updateTopConstraint() {
        // topConstraint?.isActive = false
        // guard let superview else { return }
        // topConstraint = self.topAnchor.constraint(
        //     equalTo: superview.safeAreaLayoutGuide.topAnchor, constant: CGFloat(y))
        // topConstraint!.isActive = true
    }

    private func updateWidthConstraint() {
        // widthConstraint?.isActive = false
        // widthConstraint = self.widthAnchor.constraint(equalToConstant: CGFloat(width))
        // widthConstraint!.isActive = true
    }

    private func updateHeightConstraint() {
        // heightConstraint?.isActive = false
        // heightConstraint = self.heightAnchor.constraint(equalToConstant: CGFloat(height))
        // heightConstraint!.isActive = true
    }

    public func didMoveToSuperview() {
        //super.didMoveToSuperview()

        updateLeftConstraint()
        updateTopConstraint()
    }
}

// extension GtkBackend {
//     public typealias Widget = BaseWidget
// }

class WrapperWidget<View: Gtk.Widget>: BaseWidget {
    init(child: View) {
        super.init()

        // self.addSubview(child)
        // child.translatesAutoresizingMaskIntoConstraints = false
        // NSLayoutConstraint.activate([
        //     child.topAnchor.constraint(equalTo: self.topAnchor),
        //     child.leadingAnchor.constraint(equalTo: self.leadingAnchor),
        //     child.bottomAnchor.constraint(equalTo: self.bottomAnchor),
        //     child.trailingAnchor.constraint(equalTo: self.trailingAnchor),
        // ])
    }

    // override convenience init() {
    //     self.init(child: View(UnsafeMutablePointer<Widget>(nil)))
    // }

    // var child: View {
    //     subviews[0] as! View
    // }

    // override var intrinsicContentSize: CGSize {
    //     child.intrinsicContentSize
    // }
}
