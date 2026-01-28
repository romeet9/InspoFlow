import SwiftUI
import UIKit

struct ThemeTransition {
    static func toggleTheme(isDarkMode: Binding<Bool>, from location: CGPoint? = nil) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            // Fallback if no window found
            withAnimation {
                isDarkMode.wrappedValue.toggle()
            }
            return
        }
        
        // 1. Snapshot the current state
        guard let snapshotView = window.snapshotView(afterScreenUpdates: false) else {
            isDarkMode.wrappedValue.toggle()
            return
        }
        snapshotView.frame = window.bounds
        window.addSubview(snapshotView)
        
        // 2. Change the theme immediately behind the snapshot
        isDarkMode.wrappedValue.toggle() 
        // Force layout pass to ensure the new theme is rendered behind the snapshot
        window.overrideUserInterfaceStyle = isDarkMode.wrappedValue ? .dark : .light
        
        // 3. Create the mask animation
        // Default start point: Top Right (approximating the button location)
        let startPoint = location ?? CGPoint(x: window.bounds.width - 40, y: 60)
        
        let circleMask = CAShapeLayer()
        let startPath = UIBezierPath(ovalIn: CGRect(origin: startPoint, size: .zero)).cgPath
        
        // Calculate radius to cover the screen from the start point
        let x = max(startPoint.x, window.bounds.width - startPoint.x)
        let y = max(startPoint.y, window.bounds.height - startPoint.y)
        let radius = sqrt(x * x + y * y)
        
        let endRect = CGRect(x: startPoint.x - radius, y: startPoint.y - radius, width: radius * 2, height: radius * 2)
        let endPath = UIBezierPath(ovalIn: endRect).cgPath
        
        circleMask.path = endPath
        circleMask.position = .zero
        
        // We are masking the SNAPSHOT. So we want the snapshot to disappear in a circle?
        // Actually, normally you want the NEW content to appear. 
        // So let's put the snapshot ON TOP (which it is) and mask it to REVEAL the content below?
        // No, typically you mask the top view to shrink it, OR mask the top view to expand a hole.
        
        // Let's Mask the "New Theme" approach:
        // Easier approach: Snapshot is the OLD theme. We want to "wipe away" the old theme.
        // So we animate the mask of the Snapshot from Full Screen -> Zero? 
        // OR we animate a "hole" growing in the snapshot.
        
        // Let's try: "Growing Circle of the NEW theme on top of the OLD theme"
        // 1. Snapshot OLD theme.
        // 2. Add Snapshot to window.
        // 3. Change actual window theme (New Theme is now "under" snapshot).
        // Wait, if New Theme is under, we need to remove the snapshot.
        
        // BETTER APPROACH for "Circular Reveal":
        // 1. Snapshot OLD theme. Add to window.
        // 2. Snapshot NEW theme (ghost view). Add to window ON TOP of Old Snapshot.
        // 3. Mask the NEW Snapshot with a growing circle.
        
        // Simplified approach that works well:
        // 1. Take snapshot of CURRENT (Old) view. Add it to window.
        // 2. Toggle state. Window updates to NEW theme (underneath the snapshot).
        // 3. Mask the SNAPSHOT with a "shrinking circle" or inverted mask to reveal what's under?
        // Easier: Mask the SNAPSHOT with a path that goes from Full -> Empty?
        
        // Let's go with: MASK the SHAPSHOT (Old View).
        // We want the New View to "grow" from the top right.
        // That means the Old View (on top) needs to "shrink" or be "cut out" starting from top right.
        // CAShapeLayer mask on snapshotView. 
        // Start Path: Full Rect (Visible)
        // End Path: Full Rect MINUS the Growing Circle? Complex.
        
        // ALTERNATIVE:
        // 1. Toggle Theme.
        // 2. Snapshot NEW Theme.
        // 3. Revert Theme (temporarily) OR put OLD snapshot on bottom?
        // 
        // Let's stick to the most robust one:
        // 1. Snapshot OLD (top view).
        // 2. Toggle Theme (underneath).
        // 3. Mask the OLD view with a circle that shrinks to zero? No, that looks like closing.
        // 4. We want OPENING.
        // So we want the HOLE in the OLD view to Grow.
        
        // Implementing Hole-Growing Mask:
        // Mask needs 'fillRule = .evenOdd'
        // Path = FullRectPath + CirclePath
        // Animate CirclePath growing.
        
        let finalMaskLayer = CAShapeLayer()
        finalMaskLayer.fillRule = .evenOdd
        snapshotView.layer.mask = finalMaskLayer
        
        let fullRectPath = UIBezierPath(rect: window.bounds)
        
        // Start: Circle is size 0 at touch point
        let startCirclePath = UIBezierPath(ovalIn: CGRect(origin: startPoint, size: .zero))
        let startCombinedPath = UIBezierPath()
        startCombinedPath.append(fullRectPath)
        startCombinedPath.append(startCirclePath)
        
        // End: Circle covers screen
        let endCirclePath = UIBezierPath(ovalIn: endRect)
        let endCombinedPath = UIBezierPath()
        endCombinedPath.append(fullRectPath)
        endCombinedPath.append(endCirclePath)
        
        finalMaskLayer.path = endCombinedPath.cgPath // Final state
        
        let animation = CABasicAnimation(keyPath: "path")
        animation.fromValue = startCombinedPath.cgPath
        animation.toValue = endCombinedPath.cgPath
        animation.duration = 0.6
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.delegate = AnimationDelegate {
            snapshotView.removeFromSuperview()
        }
        
        finalMaskLayer.add(animation, forKey: "circularReveal")
    }
}

// Helper for CAAnimation delegate
class AnimationDelegate: NSObject, CAAnimationDelegate {
    let completion: () -> Void
    
    init(completion: @escaping () -> Void) {
        self.completion = completion
    }
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        completion()
    }
}
