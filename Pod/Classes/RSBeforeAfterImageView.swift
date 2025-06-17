//
//  BeforeAfterView.swift
//  Pixelfix
//
//  Created by Ric Santos on 13/5/2025.
//

import UIKit

public class RSBeforeAfterImageView: UIView {

    private let beforeImageView = UIImageView()
    private let afterImageView = UIImageView()
    private let dividerView = UIView()
    private let grabHandle = UIView()

    private var maskLayer = CAShapeLayer()

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

        // Style the divider
        dividerView.backgroundColor = .white
        dividerView.layer.shadowColor = UIColor.black.cgColor
        dividerView.layer.shadowOpacity = 0.3
        dividerView.layer.shadowOffset = .zero
        dividerView.layer.shadowRadius = 3

        grabHandle.layer.cornerRadius = 10
        grabHandle.layer.cornerCurve = .continuous
        grabHandle.backgroundColor = .white
        dividerView.addSubview(grabHandle)

        maskLayer.frame = bounds
        updateMask(x: bounds.midX)
        afterImageView.layer.mask = maskLayer
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        
        // Update image views to fill the bounds
        beforeImageView.frame = bounds
        afterImageView.frame = bounds
        
        // Update divider position
        dividerView.frame = CGRect(x: bounds.midX - 1, y: 0, width: 2, height: bounds.height)
        
        // Update grab handle position
        grabHandle.frame = CGRect(x: -10, y: bounds.midY - 25, width: 20, height: 50)
        
        // Update mask layer frame and path
        maskLayer.frame = bounds
        updateMask(x: dividerView.center.x)
    }

    private func addPanGesture() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        dividerView.addGestureRecognizer(pan)
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self)
        var newX = dividerView.center.x + translation.x
        newX = max(0, min(bounds.width, newX))
        gesture.setTranslation(.zero, in: self)

        dividerView.center.x = newX
        updateMask(x: newX)
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
