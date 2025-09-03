import SwiftUI
import AppKit

public struct MenuBarExtraTransparencyHelperView: NSViewRepresentable {
    public init() {}

    public class WindowConfiguratorView: NSView {
        public override func viewWillDraw() {
            super.viewWillDraw()
            self.configure(window: self.window)
        }
        public override func viewWillMove(toWindow newWindow: NSWindow?) {
            super.viewWillMove(toWindow: newWindow)
            self.configure(window: newWindow)
        }

        public override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            self.configure(window: self.window)
        }

        private func configure(window: NSWindow?) {
            guard let window else { return }

            // Make the underlying Menu Bar Extra panel/window transparent
            window.styleMask.insert(.fullSizeContentView)
            window.isOpaque = false
            window.backgroundColor = .clear
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.hasShadow = true

            guard let contentView = window.contentView else { return }
            // Ensure content view is fully transparent
            contentView.wantsLayer = true
            contentView.layer?.backgroundColor = NSColor.clear.cgColor
            contentView.layer?.isOpaque = false

            // Clear any default backgrounds across the entire ancestor chain
            self.clearBackgroundUpwards(from: contentView)

            // If you want translucent blur instead of fully transparent, uncomment the block below
            // addBlur(in: contentView)
        }

        private func clearBackgroundRecursively(in view: NSView?) {
            guard let view else { return }
            view.wantsLayer = true
            view.layer?.backgroundColor = NSColor.clear.cgColor
            view.layer?.isOpaque = false

            if let eff = view as? NSVisualEffectView, eff.identifier?.rawValue != "vv_transparent_blur" {
                // 移除系统默认的模糊/材质背景视图，确保完全透明
                eff.removeFromSuperview()
                return
            }

            for sub in view.subviews { clearBackgroundRecursively(in: sub) }
        }

        private func clearBackgroundUpwards(from view: NSView) {
            var current: NSView? = view
            while let node = current {
                clearBackgroundRecursively(in: node)
                current = node.superview
            }
        }

        private func addBlur(in contentView: NSView) {
            let identifier = NSUserInterfaceItemIdentifier("vv_transparent_blur")
            if contentView.subviews.contains(where: { $0.identifier == identifier }) { return }

            let blurView = NSVisualEffectView()
            blurView.identifier = identifier
            blurView.blendingMode = .withinWindow
            blurView.state = .active
            blurView.material = .hudWindow
            blurView.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(blurView, positioned: .below, relativeTo: nil)

            NSLayoutConstraint.activate([
                blurView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                blurView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                blurView.topAnchor.constraint(equalTo: contentView.topAnchor),
                blurView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
            ])
        }
    }

    public func makeNSView(context: Context) -> WindowConfiguratorView {
        WindowConfiguratorView()
    }

    public func updateNSView(_ nsView: WindowConfiguratorView, context: Context) { }
}

public extension View {
    /// 为 MenuBarExtra 的窗口启用透明背景（并添加系统模糊）。
    /// 使用方式：将其作为菜单根视图的一个背景层即可。
    func menuBarExtraTransparentBackground() -> some View {
        self.background(MenuBarExtraTransparencyHelperView())
    }
}


