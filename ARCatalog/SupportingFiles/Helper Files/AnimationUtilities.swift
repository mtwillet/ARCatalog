//
//  Utilities2.swift
//  ARCatalog
//
//  Created by Mathew Willett on 3/24/19.
//  Copyright © 2019 Mathew Willett. All rights reserved.
//


import QuartzCore

/// CAAnimation Delegation class implementation
class CAAnimationHandler: NSObject, CAAnimationDelegate {
    /// start: A block (closure) object to be executed when the animation starts. This block has no return value and takes no argument.
    var start: (() -> Void)?
    
    /// completion: A block (closure) object to be executed when the animation ends. This block has no return value and takes a single Boolean argument that indicates whether or not the animations actually finished.
    var completion: ((Bool) -> Void)?
    
    /// startTime: animation start date
    fileprivate var startTime: Date!
    fileprivate var animationDuration: TimeInterval!
    fileprivate var animatingTimer: Timer!
    
    /// animating: A block (closure) object to be executed when the animation is animating. This block has no return value and takes a single CGFloat argument that indicates the progress of the animation (From 0 ..< 1)
    var animating: ((CGFloat) -> Void)? {
        willSet {
            if animatingTimer == nil {
                animatingTimer = Timer(timeInterval: 0, target: self, selector: #selector(CAAnimationHandler.animationIsAnimating(_:)), userInfo: nil, repeats: true)
            }
        }
    }
    
    /**
     Called when the animation begins its active duration.
     
     - parameter theAnimation: the animation about to start
     */
    func animationDidStart(_ theAnimation: CAAnimation) {
        start?()
        if animating != nil {
            animationDuration = theAnimation.duration
            startTime = Date()
            RunLoop.current.add(animatingTimer, forMode: RunLoopMode.defaultRunLoopMode)
        }
    }
    
    /**
     Called when the animation completes its active duration or is removed from the object it is attached to.
     
     - parameter theAnimation: the animation about to end
     - parameter finished:     A Boolean value indicates whether or not the animations actually finished.
     */
    func animationDidStop(_ theAnimation: CAAnimation, finished: Bool) {
        completion?(finished)
        animatingTimer?.invalidate()
    }
    
    /**
     Called when the animation is executing
     
     - parameter timer: timer
     */
    @objc func animationIsAnimating(_ timer: Timer) {
        let progress = CGFloat(Date().timeIntervalSince(startTime) / animationDuration)
        if progress <= 1.0 {
            animating?(progress)
        }
    }
}

public extension CAAnimation {
    /// A block (closure) object to be executed when the animation starts. This block has no return value and takes no argument.
    public var start: (() -> Void)? {
        set {
            if let animationDelegate = delegate as? CAAnimationHandler {
                animationDelegate.start = newValue
            } else {
                let animationDelegate = CAAnimationHandler()
                animationDelegate.start = newValue
                delegate = animationDelegate
            }
        }
        
        get {
            if let animationDelegate = delegate as? CAAnimationHandler {
                return animationDelegate.start
            }
            
            return nil
        }
    }
    
    /// A block (closure) object to be executed when the animation ends. This block has no return value and takes a single Boolean argument that indicates whether or not the animations actually finished.
    public var completion: ((Bool) -> Void)? {
        set {
            if let animationDelegate = delegate as? CAAnimationHandler {
                animationDelegate.completion = newValue
            } else {
                let animationDelegate = CAAnimationHandler()
                animationDelegate.completion = newValue
                delegate = animationDelegate
            }
        }
        
        get {
            if let animationDelegate = delegate as? CAAnimationHandler {
                return animationDelegate.completion
            }
            
            return nil
        }
    }
    
    /// A block (closure) object to be executed when the animation is animating. This block has no return value and takes a single CGFloat argument that indicates the progress of the animation (From 0 ..< 1)
    public var animating: ((CGFloat) -> Void)? {
        set {
            if let animationDelegate = delegate as? CAAnimationHandler {
                animationDelegate.animating = newValue
            } else {
                let animationDelegate = CAAnimationHandler()
                animationDelegate.animating = newValue
                delegate = animationDelegate
            }
        }
        
        get {
            if let animationDelegate = delegate as? CAAnimationHandler {
                return animationDelegate.animating
            }
            
            return nil
        }
    }
    
    /// Alias to `animating`
    public var progress: ((CGFloat) -> Void)? {
        set {
            animating = newValue
        }
        
        get {
            return animating
        }
    }
}

public extension CALayer {
    /**
     Add the specified animation object to the layer’s render tree. Could provide a completion closure.
     
     - parameter anim:       The animation to be added to the render tree. This object is copied by the render tree, not referenced. Therefore, subsequent modifications to the object are not propagated into the render tree.
     - parameter key:        A string that identifies the animation. Only one animation per unique key is added to the layer. The special key kCATransition is automatically used for transition animations. You may specify nil for this parameter.
     - parameter completion: A block object to be executed when the animation ends. This block has no return value and takes a single Boolean argument that indicates whether or not the animations actually finished before the completion handler was called. Default value is nil.
     */
    func add(_ anim: CAAnimation, forKey key: String?, withCompletion completion: ((Bool) -> Void)?) {
        anim.completion = completion
        add(anim, forKey: key)
    }
}
