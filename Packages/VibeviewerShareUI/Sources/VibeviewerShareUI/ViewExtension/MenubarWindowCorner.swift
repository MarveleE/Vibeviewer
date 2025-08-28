import SwiftUI

extension NSObject {
    
    /// Swap the given named instance method of the given named class with the given
    /// named instance method of this class.
    /// - Parameters:
    ///   - method: The name of the instance method whose implementation will be exchanged.
    ///   - className: The name of the class whose instance method implementation will be exchanged.
    ///   - newMethod: The name of the instance method on this class which will replace the first given method.
    static func exchange(method: String, in className: String, for newMethod: String) {
        guard let classRef = objc_getClass(className) as? AnyClass,
              let original = class_getInstanceMethod(classRef, Selector((method))),
              let replacement = class_getInstanceMethod(self, Selector((newMethod)))
        else {
            fatalError("Could not exchange method \(method) on class \(className).");
        }
        
        method_exchangeImplementations(original, replacement);
    }
    
}

// MARK: - Custom Window Corner Mask Implementation

/// Exchange Flag
///
var __SwiftUIMenuBarExtraPanel___cornerMask__didExchange = false;

/// Custom Corner Radius
///
fileprivate let kWindowCornerRadius: CGFloat = 32;

extension NSObject {
    
    @objc func __SwiftUIMenuBarExtraPanel___cornerMask() -> NSImage? {
        let width = kWindowCornerRadius * 2;
        let height = kWindowCornerRadius * 2;
        
        let image = NSImage(size: CGSizeMake(width, height));
        
        image.lockFocus();
        
        /// Draw a rounded-rectangle corner mask.
        ///
        NSColor.black.setFill();
        NSBezierPath(
            roundedRect: CGRectMake(0, 0, width, height),
            xRadius: kWindowCornerRadius,
            yRadius: kWindowCornerRadius).fill();
        
        image.unlockFocus();

        image.capInsets = .init(
            top: kWindowCornerRadius,
            left: kWindowCornerRadius,
            bottom: kWindowCornerRadius,
            right: kWindowCornerRadius);
        
        return image;
    }
    
}

// MARK: - Context Window Accessor

public struct MenuBarExtraWindowHelperView: NSViewRepresentable {

    public init() {}
    
    public class WindowHelper: NSView {
        
        public override func viewWillDraw() {
            if __SwiftUIMenuBarExtraPanel___cornerMask__didExchange { return }
            
            guard
                let window: AnyObject = self.window,
                let windowClass = window.className
            else { return }
            

            NSObject.exchange(
                method: "_cornerMask",
                in: windowClass,
                for: "__SwiftUIMenuBarExtraPanel___cornerMask");
            
            let _ = window.perform(Selector(("_cornerMaskChanged")));
            
            __SwiftUIMenuBarExtraPanel___cornerMask__didExchange = true;
           
        }
        
    }
    
    public func updateNSView(_ nsView: WindowHelper, context: Context) { }
    
    public func makeNSView(context: Context) -> WindowHelper { WindowHelper() }
}

public extension View {
    func menuBarExtraWindowCorner() -> some View {
        self.background(MenuBarExtraWindowHelperView())
    }
}