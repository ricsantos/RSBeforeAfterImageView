//
//  BeforeAfterView.swift
//  Pixelfix
//
//  Created by Ric Santos on 13/5/2025.
//

import UIKit

public class RSBeforeAfterImageView: UIView {
    public let beforeImageView = UIImageView()
    public let afterImageView = UIImageView()
    private let dividerView = UIView()
    private let touchAreaView = UIView()
    private let grabHandle = UIView()
    private let grabHandleIconView = UIImageView()
    private var maskLayer = CAShapeLayer()
    private var previousBounds: CGRect = .zero
    private var blurView: UIVisualEffectView?
    
    /// The position of the divider, normalized from 0.0 to 1.0
    private var dividerPosition: CGFloat = 0.5 {
        didSet {
            dividerPosition = max(0.0, min(1.0, dividerPosition))
            updateDividerPosition()
        }
    }
    
    /// Sets the position of the divider
    /// - Parameters:
    ///   - position: The normalized position (0.0 to 1.0)
    ///   - animated: Whether to animate the change
    ///   - duration: The duration of the animation in seconds
    ///   - completion: A closure to be called when the animation completes
    public func setDividerPosition(_ position: CGFloat, animated: Bool = true, duration: TimeInterval = 0.5, completion: (() -> Void)? = nil) {
        let newPosition = max(0.0, min(1.0, position))
        
        if animated {
            UIView.animate(withDuration: duration, delay: 0.0, options: .curveEaseInOut, animations: {
                self.dividerPosition = newPosition
            }, completion: { _ in
                completion?()
            })
        } else {
            dividerPosition = newPosition
            completion?()
        }
    }
    
    /// The size of the grab handle
    public var grabHandleSize: CGSize = CGSize(width: 24, height: 40) {
        didSet {
            updateGrabHandleAppearance()
        }
    }
    
    /// The corner radius of the grab handle
    public var grabHandleCornerRadius: CGFloat = 12 {
        didSet {
            updateGrabHandleAppearance()
        }
    }
    
    /// The border color of the grab handle
    public var grabHandleBorderColor: UIColor = .white {
        didSet {
            updateGrabHandleAppearance()
        }
    }
    
    /// The border width of the grab handle
    public var grabHandleBorderWidth: CGFloat = 1.0 {
        didSet {
            updateGrabHandleAppearance()
        }
    }
    
    /// The icon image for the grab handle
    public var grabHandleIcon: UIImage? {
        didSet {
            updateGrabHandleAppearance()
        }
    }
    
    /// The tint color for the grab handle icon
    public var grabHandleIconTintColor: UIColor = .white {
        didSet {
            updateGrabHandleAppearance()
        }
    }
    
    /// The inset for the grab handle icon from the edges
    public var grabHandleIconInset: CGFloat = 4.0 {
        didSet {
            updateGrabHandleAppearance()
        }
    }
    
    /// The type of background for the grab handle
    public enum GrabHandleBackgroundStyle {
        case color(UIColor)
        case blur(UIBlurEffect.Style)
    }
    
    /// The background of the grab handle
    public var grabHandleBackgroundStyle: GrabHandleBackgroundStyle = .color(UIColor(white: 1.0, alpha: 1.0)) {
        didSet {
            updateGrabHandleAppearance()
        }
    }
    
    private func updateGrabHandleAppearance() {
        // Update size
        let handleSize = grabHandleSize
        grabHandle.frame = CGRect(
            x: (touchAreaView.bounds.width - handleSize.width)/2,
            y: (touchAreaView.bounds.height - handleSize.height)/2,
            width: handleSize.width,
            height: handleSize.height
        )
        
        // Update corner radius
        grabHandle.layer.cornerRadius = grabHandleCornerRadius
        
        // Update border
        grabHandle.layer.borderColor = grabHandleBorderColor.cgColor
        grabHandle.layer.borderWidth = grabHandleBorderWidth
        
        // Update background
        switch grabHandleBackgroundStyle {
        case .color(let color):
            blurView?.removeFromSuperview()
            blurView = nil
            grabHandle.backgroundColor = color
            
        case .blur(let style):
            blurView?.removeFromSuperview()
            
            let blurEffect = UIBlurEffect(style: style)
            let newBlurView = UIVisualEffectView(effect: blurEffect)
            newBlurView.frame = grabHandle.bounds
            newBlurView.layer.cornerRadius = grabHandleCornerRadius
            newBlurView.clipsToBounds = true
            grabHandle.insertSubview(newBlurView, at: 0)
            blurView = newBlurView
            
            grabHandle.backgroundColor = .clear
        }
        
        // Update icon
        grabHandleIconView.image = grabHandleIcon
        grabHandleIconView.tintColor = grabHandleIconTintColor
        grabHandleIconView.isHidden = grabHandleIcon == nil
        if grabHandleIcon != nil {
            let inset = grabHandleIconInset
            grabHandleIconView.frame = CGRect(
                x: inset,
                y: inset,
                width: grabHandle.bounds.width - (inset * 2),
                height: grabHandle.bounds.height - (inset * 2)
            )
            grabHandleIconView.contentMode = .scaleAspectFit
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        addPanGesture()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        beforeImageView.contentMode = .scaleAspectFill
        afterImageView.contentMode = .scaleAspectFill

        addSubview(beforeImageView)
        addSubview(afterImageView)
        addSubview(dividerView)
        addSubview(touchAreaView)

        // Style the divider
        dividerView.backgroundColor = .white
        dividerView.layer.shadowColor = UIColor.black.cgColor
        dividerView.layer.shadowOpacity = 0.3
        dividerView.layer.shadowOffset = .zero
        dividerView.layer.shadowRadius = 3
        
        // Set initial divider frame
        dividerView.frame = CGRect(x: 0, y: 0, width: 2, height: bounds.height)

        // Setup touch area
        touchAreaView.backgroundColor = .clear
        touchAreaView.isUserInteractionEnabled = true

        // Style the grab handle
        grabHandle.layer.cornerCurve = .continuous
        grabHandle.layer.shadowColor = UIColor.black.cgColor
        grabHandle.layer.shadowOpacity = 0.2
        grabHandle.layer.shadowOffset = CGSize(width: 0, height: 2)
        grabHandle.layer.shadowRadius = 4
        grabHandle.isUserInteractionEnabled = false
        
        // Setup icon view
        grabHandleIconView.contentMode = .scaleAspectFit
        grabHandleIconView.isHidden = true
        grabHandle.addSubview(grabHandleIconView)
        
        touchAreaView.addSubview(grabHandle)
        
        // Set initial frames
        beforeImageView.frame = bounds
        afterImageView.frame = bounds
        
        // Position touch area centered on divider
        let touchAreaSize = CGSize(width: 64, height: 80)
        touchAreaView.frame = CGRect(
            x: -touchAreaSize.width/2,
            y: (bounds.height - touchAreaSize.height)/2,
            width: touchAreaSize.width,
            height: touchAreaSize.height
        )
        
        // Update grab handle appearance
        updateGrabHandleAppearance()
        
        maskLayer.frame = bounds
        updateMask(x: bounds.midX)
        afterImageView.layer.mask = maskLayer
    }

    private func updateDividerPosition() {
        let x = bounds.width * dividerPosition
        dividerView.frame = CGRect(x: x - 1, y: 0, width: 2, height: bounds.height)
        
        // Update touch area position to stay centered
        let touchAreaSize = CGSize(width: 64, height: 80)
        touchAreaView.frame = CGRect(
            x: x - touchAreaSize.width/2,
            y: (bounds.height - touchAreaSize.height)/2,
            width: touchAreaSize.width,
            height: touchAreaSize.height
        )
        
        updateMask(x: x)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        
        // Update image views to fill the bounds
        beforeImageView.frame = bounds
        afterImageView.frame = bounds
        
        // Only reset divider position if bounds actually changed
        if bounds != previousBounds {
            updateDividerPosition()
            previousBounds = bounds
        }
        
        // Update mask layer frame
        maskLayer.frame = bounds
    }

    private func addPanGesture() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.delegate = self
        pan.maximumNumberOfTouches = 1
        pan.minimumNumberOfTouches = 1
        pan.cancelsTouchesInView = false
        touchAreaView.addGestureRecognizer(pan)
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        print("Tap detected on handle")
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            UIView.animate(withDuration: 0.1) {
                self.grabHandle.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
                self.grabHandle.layer.shadowOpacity = 0.4
                self.grabHandle.layer.shadowRadius = 6
                self.grabHandle.layer.shadowOffset = CGSize(width: 0, height: 3)
                self.grabHandle.layer.borderWidth = 1.5
            }
        case .changed:
            let translation = gesture.translation(in: self)
            let newX = dividerView.center.x + translation.x
            dividerPosition = newX / bounds.width
            gesture.setTranslation(.zero, in: self)
        case .ended, .cancelled, .failed:
            UIView.animate(withDuration: 0.2) {
                self.grabHandle.transform = .identity
                self.grabHandle.layer.shadowOpacity = 0.2
                self.grabHandle.layer.shadowRadius = 4
                self.grabHandle.layer.shadowOffset = CGSize(width: 0, height: 2)
                self.grabHandle.layer.borderWidth = 1
            }
        case .possible:
            break
        }
    }

    private func updateMask(x: CGFloat) {
        let path = UIBezierPath(rect: CGRect(x: 0, y: 0, width: x, height: bounds.height))
        maskLayer.path = path.cgPath
    }

    // Public setup
    public func configure(before: UIImage, after: UIImage) {
        beforeImageView.image = before
        afterImageView.image = after
    }
}

// Add UIGestureRecognizerDelegate to handle gesture recognition
extension RSBeforeAfterImageView: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        print("Should receive touch: \(touch.location(in: self))")
        return true
    }
}
