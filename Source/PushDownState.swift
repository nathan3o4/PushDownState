//
//  PushDownState.swift
//  PushDownState
//
//  Created by Nathan Ansel on 2/25/17.
//  Copyright © 2017 Nathan Ansel. All rights reserved.
//

import UIKit

internal enum DefaultValues {
	static let pushDownDuration: TimeInterval = 0.1
	static let pushDownScale: CGFloat = 0.95
	static let pushDownRoundCorners: Bool = true
}

internal extension UIView {
	enum PushState {
		case up
		case down
	}
}

@objc internal protocol PushDownView: class {
	/// The duration for the push down animation to last. Default value is 0.1
	/// seconds.
	var pushDownDuration: TimeInterval { get set }
	
	/// The scale for the push down effect to take. Default value is 0.95.
	/// Values should be a percent between 0.0 and 1.0.
	var pushDownScale: CGFloat { get set }
	
	/// Whether or not the corners of the UIView should be rounded. If true, the
	/// corners will be rounded to a value of 8. If the corners are already
	/// rounded to a value greater than 8, the corner radius will not change.
	/// Default value is true.
	var pushDownRoundCorners: Bool { get set }
	
	var pushDownBackgroundColor: UIColor? { get set }
	
	var originalBackgroundColor: UIColor? { get set }
	var originalCornerRadius: CGFloat { get set }
	var originalMasksToLayer: Bool { get set }
	var isAnimating: Bool { get set }
	var animationsToComplete: (()->())? { get set }
}

internal extension PushDownView where Self: UIView {
	func animatePush(toState: UIView.PushState) {
		if !isAnimating {
			isAnimating = true
			UIView.animate(
				withDuration: pushDownDuration,
				delay: 0,
				options: .curveEaseInOut,
				animations: { [weak self] in
					self?.snapPush(toState: toState)
				}, completion: { [weak self] _ in
					self?.isAnimating = false
					self?.animationsToComplete?()
					self?.animationsToComplete = nil
			})
		} else {
			animationsToComplete = { [weak self] in
				self?.animatePush(toState: toState)
			}
		}
	}
	
	func snapPush(toState: PushState) {
		switch toState {
		case .up:
			transform = CGAffineTransform.identity
			if let _ = pushDownBackgroundColor {
				backgroundColor = originalBackgroundColor
			}
			if pushDownRoundCorners {
				if originalCornerRadius < 8 {
					layer.masksToBounds = originalMasksToLayer
					let animation = CABasicAnimation(keyPath: "cornerRadius")
					animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
					animation.fromValue = layer.cornerRadius
					animation.toValue = originalCornerRadius
					animation.duration = pushDownDuration
					layer.add(animation, forKey: animation.keyPath)
					layer.cornerRadius = originalCornerRadius
				}
			}
		case .down:
			transform = CGAffineTransform.identity.scaledBy(x: pushDownScale, y: pushDownScale)
			originalBackgroundColor = backgroundColor
			if let color = pushDownBackgroundColor {
				backgroundColor = color
			}
			if pushDownRoundCorners {
				originalCornerRadius = layer.cornerRadius
				if originalCornerRadius < 8 {
					layer.masksToBounds = true
					let animation = CABasicAnimation(keyPath: "cornerRadius")
					animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
					animation.fromValue = layer.cornerRadius
					animation.toValue = 8
					animation.duration = pushDownDuration
					layer.add(animation, forKey: animation.keyPath)
					layer.cornerRadius = 8
				}
			}
		}
	}
}

// MARK: - UIButton

open class PushDownButton: UIButton, PushDownView {
	@IBInspectable public var pushDownDuration: TimeInterval = DefaultValues.pushDownDuration
	@IBInspectable public var pushDownScale: CGFloat = DefaultValues.pushDownScale
	@IBInspectable public var pushDownRoundCorners = DefaultValues.pushDownRoundCorners
	@IBInspectable public var pushDownBackgroundColor: UIColor?
	internal var originalBackgroundColor: UIColor?
	internal var originalCornerRadius: CGFloat = 0
	internal var originalMasksToLayer = false
	internal var isAnimating = false
	internal var animationsToComplete: (()->())?
	
	public override init(frame: CGRect) {
		super.init(frame: frame)
		commonInit()
	}
	
	public required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		commonInit()
	}
	
	private func commonInit() {
		addTarget(self, action: #selector(animatePushDown), for: [.touchDown, .touchDragEnter])
		addTarget(self, action: #selector(animateRelease), for: [.touchUpInside, .touchCancel, .touchDragExit])
	}
	
	@objc private func animatePushDown() {
		animatePush(toState: .down)
	}
	
	@objc private func animateRelease() {
		animatePush(toState: .up)
	}
}

// MARK: - UITableViewCell

open class PushDownTableViewCell: UITableViewCell, PushDownView {
	@IBInspectable public var pushDownDuration: TimeInterval = DefaultValues.pushDownDuration
	@IBInspectable public var pushDownScale: CGFloat = DefaultValues.pushDownScale
	@IBInspectable public var pushDownRoundCorners = DefaultValues.pushDownRoundCorners
	@IBInspectable public var pushDownBackgroundColor: UIColor?
	internal var originalBackgroundColor: UIColor?
	internal var originalCornerRadius: CGFloat = 0
	internal var originalMasksToLayer = false
	internal var isAnimating = false
	internal var animationsToComplete: (()->())?
	
	open override func setHighlighted(_ highlighted: Bool, animated: Bool) {
		super.setHighlighted(highlighted, animated: animated)
		let toState: PushState = highlighted ? .down : .up
		animatePush(toState: toState)
	}
}

// MARK: - UICollectionViewCell

open class PushDownCollectionViewCell: UICollectionViewCell, PushDownView {
	@IBInspectable public var pushDownDuration: TimeInterval = DefaultValues.pushDownDuration
	@IBInspectable public var pushDownScale: CGFloat = DefaultValues.pushDownScale
	@IBInspectable public var pushDownRoundCorners = DefaultValues.pushDownRoundCorners
	@IBInspectable public var pushDownBackgroundColor: UIColor?
	internal var originalBackgroundColor: UIColor?
	internal var originalCornerRadius: CGFloat = 0
	internal var originalMasksToLayer = false
	internal var isAnimating = false
	internal var animationsToComplete: (()->())?
	
	open override var isHighlighted: Bool {
		didSet {
			let toState: PushState = isHighlighted ? .down : .up
			animatePush(toState: toState)
		}
	}
}

