//
//  BottomSheetController.swift
//  OSCAMapUI
//
//  Created by Mammut Nithammer on 24.06.22.
//  Reviewed by Stephan Breidenbach on 15.08.22
//  Copyright © 2020 Stadt Solingen. All rights reserved.
//

import UIKit
import OSCAEssentials

// MARK: - BottomSheetController

open class BottomSheetController: UIViewController {
  // MARK: Open
  open var bottomSheetPreferredSize: CGSize {
    CGSize(width: UIScreen.main.bounds.width, height: 400)
  } // end open var bottomSheetPreferredSize

  open var bottomSheetPreferredLandscapeFrame: CGRect {
    CGRect(x: 10, y: 10, width: 300, height: UIScreen.main.bounds.height - 20)
  } // end open var bottomSheetPreferredLandscapeFrame

  open var bottomSheetMiddleStickyPoints: [CGFloat] {
    []
  } // end open var bottomSheetMiddleStickyPoints

  open var bottomSheetBounceOffset: CGFloat {
    0
  } // end open var bottomSheetBounceOffset

  open var bottomSheetCurrentPointOffset: CGFloat {
    guard
      let parentViewHeight = parent?.view.frame.height
    else { return 0 }
    return parentViewHeight - (topConstraint?.constant ?? 0)
  } // end open var bottomSheetCurrentPointOffset

  // swiftlint:disable:next identifier_name
  open var bottomSheetSkipPointVerticalVelocityThreshold: CGFloat {
    700
  } // end open var bottomSheetSkipPointVerticalVelocityThreshold

  open func bottomSheetWillMove(to _: CGFloat) {}
  
  open func bottomSheetDidMove(to position: CGFloat) {
    onBottomSheetMoved?(position)
  }
  
  open func bottomSheetDidDrag(to _: CGFloat) {}

  open func bottomSheetMoveToVisiblePoint(_ visiblePoint: CGFloat, animated: Bool, completion: (() -> Void)?) {
    guard
      isPortrait,
      let parentViewHeight = parent?.view.frame.height
    else { return }
    topConstraint?.constant = parentViewHeight - visiblePoint
    bottomSheetWillMove(to: visiblePoint)
    bottomSheetAnimate(
      action: .move,
      withDuration: animated ? 0.3 : 0,
      animations: { [weak self] in
        self?.parent?.view?.layoutIfNeeded()
      },
      completion: { [weak self] _ in
        self?.bottomSheetDidMove(to: visiblePoint)
        completion?()
      }
    )
  } // end open func bottomSheetMoveToVisiblePoint

  open func updatePreferredFrameIfNeeded(animated: Bool) {
    guard
      let parentView = parent?.view
    else { return }
    refreshConstraints(
      newSize: parentView.frame.size,
      customTopOffset: (bottomSheetAllStickyPoints.first ?? 0)
    )

    bottomSheetAnimate(
      action: .move,
      withDuration: animated ? 0.3 : 0,
      animations: { [weak self] in
        self?.view.layoutIfNeeded()
      },
      completion: nil
    )
  } // end open func updatePreferredFrameIfNeeded

  open func bottomSheetAnimate(
    action _: Action,
    withDuration duration: TimeInterval,
    animations: @escaping () -> Void,
    completion: ((Bool) -> Void)?
  ) {
    UIView.animate(withDuration: duration, animations: animations, completion: completion)
  } // end open func bottomSheetAnimate

  override open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    let isNewSizePortrait = size.height > size.width
    var targetStickyPoint: CGFloat?

    if !isNewSizePortrait {
      portraitPreviousStickyPointIndex = currentStickyPointIndex
    } else if
      let portraitPreviousStickyPointIndex = portraitPreviousStickyPointIndex,
      portraitPreviousStickyPointIndex < bottomSheetAllStickyPoints.count
    {
      targetStickyPoint = bottomSheetAllStickyPoints[portraitPreviousStickyPointIndex]
      self.portraitPreviousStickyPointIndex = nil
    } // end if

    coordinator.animate(alongsideTransition: { [weak self] _ in
      self?.refreshConstraints(
        newSize: size,
        customTopOffset: (self?.bottomSheetAllStickyPoints.first ?? 0))
      if let targetStickyPoint = targetStickyPoint {
        self?.bottomSheetMoveToVisiblePoint(targetStickyPoint, animated: true, completion: nil)
      }
    }) // end animate closure
  } // end override open func viewWillTransition

  // MARK: Public

  public enum Action {
    case add
    case remove
    case move
  } // end public enum Action

  public final var bottomSheetAllStickyPoints: [CGFloat] {
    var scAllStickyPoints = [initialStickyPointOffset, ((self.parent?.view.bounds.height ?? 0) - (self.parent?.view.safeAreaInsets.top ?? 0))].compactMap { $0 }
    scAllStickyPoints.append(contentsOf: bottomSheetMiddleStickyPoints)
    return scAllStickyPoints.sorted()
  } // end public final var bottomSheetAllStickyPoints

  // MARK: Fileprivate

  /*fileprivate*/ weak var internalScrollView: UIScrollView?
  
  private var onBottomSheetMoved: ((CGFloat) -> Void)?

  /*fileprivate*/ func setup(superview: UIView, initialStickyPointOffset: CGFloat, onBottomSheetMoved: ((CGFloat) -> Void)? = nil) {
    self.initialStickyPointOffset = initialStickyPointOffset
    self.onBottomSheetMoved = onBottomSheetMoved
    view.translatesAutoresizingMaskIntoConstraints = false
    
    superview.addSubview(view)
    view.frame = CGRect(
      origin: CGPoint(
        x: view.frame.origin.x,
        y: superview.bounds.height
      ),
      size: view.frame.size
    )

    setupPanGestureRecognizer()
    setupConstraints()
    refreshConstraints(
      newSize: superview.frame.size,
      customTopOffset: superview.frame.height - initialStickyPointOffset
    )
  } // end fileprivate func setup superview

  /*fileprivate*/ func addInternalScrollViewPanGesture() {
    internalScrollView?.panGestureRecognizer.addTarget(self, action: #selector(handleScrollViewGestureRecognizer(_:)))
  } // end fileprivate func addInternalScrollViewPanGesture

  /*fileprivate*/ func removeInternalScrollViewPanGestureRecognizer() {
    internalScrollView?.panGestureRecognizer.removeTarget(
      self,
      action: #selector(handleScrollViewGestureRecognizer(_:))
    )
  } // end fileprivate func removeInternalScrollViewPanGestureRecognizer

  /*fileprivate*/ func hide() {
    guard let parentViewHeight = parent?.view.frame.height
    else { return }
    topConstraint?.constant = parentViewHeight
  } // end fileprivate func hide
  
  func show() {
    guard let parentViewHeight = parent?.view.frame.height
    else { return }
    topConstraint?.constant = parentViewHeight / 2
  }
  
  func expandBottomSheet(completion: (() -> Void)? = nil) {
    guard let lastStickyPoint = bottomSheetAllStickyPoints.last
    else { return }
    self.bottomSheetMoveToVisiblePoint(lastStickyPoint, animated: true, completion: completion)
  }
  
  func halfExpandBottomSheet(completion: (() -> Void)? = nil) {
    guard let initialStickyPointOffset = self.initialStickyPointOffset
    else { return }
    self.bottomSheetMoveToVisiblePoint(initialStickyPointOffset, animated: true, completion: completion)
  }
  
  func contractBottomSheet(completion: (() -> Void)? = nil) {
    guard let firstStickyPoint = bottomSheetAllStickyPoints.first
    else { return }
    self.bottomSheetMoveToVisiblePoint(firstStickyPoint, animated: true, completion: completion)
  }
  
  var expansionState: ExpansionState {
    guard self.currentStickyPointIndex <= self.bottomSheetAllStickyPoints.count
    else { return .unknown }
    
    let currentStickyPoint = self.bottomSheetAllStickyPoints[self.currentStickyPointIndex]
    switch(currentStickyPoint){
    case self.initialStickyPointOffset: return .middle
    case self.bottomSheetAllStickyPoints.first: return .contracted
    case self.bottomSheetAllStickyPoints.last: return .expanded
    default: return .unknown
    }
  }
  
  open func getNextExpansionState() -> ExpansionState {
    switch self.expansionState {
    case .contracted: return .middle
    case .middle: return .expanded
    case .expanded: return .contracted
    default: return .unknown
    }
  }
  
  public func switchExpansionState() {
    guard isPortrait else { return }
    let nextState = self.getNextExpansionState()
    
    switch nextState {
    case .contracted:
      self.contractBottomSheet()
    case .middle:
      self.halfExpandBottomSheet()
    case .expanded:
      self.expandBottomSheet()
    case .unknown:
#if DEBUG
      print("\(String(describing: self)): \(#function) - Unknown bottom sheet state")
#endif
    }
  }

  // MARK: Private

  private var leftConstraint: NSLayoutConstraint?
  private var topConstraint: NSLayoutConstraint?
  private var bottomConstraint: NSLayoutConstraint?
  private var widthConstraint: NSLayoutConstraint?
  private var heightConstraint: NSLayoutConstraint?
  private var panGestureRecognizer: UIPanGestureRecognizer?

  private var portraitPreviousStickyPointIndex: Int?

  private var initialInternalScrollViewContentOffset: CGPoint = .zero
  private var initialStickyPointOffset: CGFloat?

  var isPortrait: Bool {
    UIScreen.main.bounds.height > UIScreen.main.bounds.width
  } // end private var isPortrait

  private var currentStickyPointIndex: Int {
    let stickyPointTreshold = (parent?.view.frame.height ?? 0) - (topConstraint?.constant ?? 0)
    let stickyPointsLessCurrentPosition = bottomSheetAllStickyPoints.map { abs($0 - stickyPointTreshold) }
    guard let minStickyPointDifference = stickyPointsLessCurrentPosition.min() else { return 0 }
    return stickyPointsLessCurrentPosition.firstIndex(of: minStickyPointDifference) ?? 0
  } // end private var currentStickyPointIndex

  private func setupPanGestureRecognizer() {
    addInternalScrollViewPanGesture()
    panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGestureRecognizer(_:)))
    panGestureRecognizer?.minimumNumberOfTouches = 1
    panGestureRecognizer?.maximumNumberOfTouches = 1
    if let panGestureRecognizer = panGestureRecognizer {
      view.addGestureRecognizer(panGestureRecognizer)
    } // end if
  } // end private func setupPanGestureRecognizer

  private func setupConstraints() {
    guard
      let parentView = parent?.view
    else { return }

    topConstraint = view.topAnchor.constraint(equalTo: parentView.topAnchor)
    leftConstraint = view.leftAnchor.constraint(equalTo: parentView.leftAnchor)
    widthConstraint = view.widthAnchor.constraint(equalToConstant: bottomSheetPreferredSize.width)
    heightConstraint = view.heightAnchor.constraint(equalToConstant: bottomSheetPreferredSize.height)
    heightConstraint?.priority = .defaultLow
    bottomConstraint = parentView.bottomAnchor.constraint(equalTo: view.bottomAnchor)

    let constraintsToActivate = [
      topConstraint,
      leftConstraint,
      widthConstraint,
      heightConstraint,
      bottomConstraint
    ].compactMap { $0 }
    NSLayoutConstraint.activate(constraintsToActivate)
  } // end private setupConstraints

  private func refreshConstraints(newSize: CGSize, customTopOffset: CGFloat? = nil) {
    if newSize.height > newSize.width {
      setPortraitConstraints(parentViewSize: newSize, customTopOffset: customTopOffset)
    } else {
      setLandscapeConstraints()
    }
  } // end private func refreshConstraints

  private func nearestStickyPointY(yVelocity: CGFloat) -> CGFloat {
    var currentStickyPointIndex = currentStickyPointIndex
    if abs(yVelocity) > bottomSheetSkipPointVerticalVelocityThreshold {
      if yVelocity > 0 {
        currentStickyPointIndex = max(currentStickyPointIndex - 1, 0)
      } else {
        currentStickyPointIndex = min(currentStickyPointIndex + 1, bottomSheetAllStickyPoints.count - 1)
      } // end if
    } // end if

    return (parent?.view.frame.height ?? 0) - bottomSheetAllStickyPoints[currentStickyPointIndex]
  } // end private func nearestStickyPointY

  @objc private func handleScrollViewGestureRecognizer(_ gestureRecognizer: UIPanGestureRecognizer) {
    guard
      isPortrait,
      let scrollView = internalScrollView,
      let topConstraint = topConstraint,
      let lastStickyPoint = bottomSheetAllStickyPoints.last,
      let parentViewHeight = parent?.view.bounds.height
    else { return }

    let isFullOpened = topConstraint.constant <= parentViewHeight - lastStickyPoint
    let yTranslation = gestureRecognizer.translation(in: scrollView).y
    let isScrollingDown = gestureRecognizer.velocity(in: scrollView).y > 0
    
    /*
     The user should be able to drag the view down through the internal scroll view when
     - the scroll direction is down (`isScrollingDown`)
     - the internal scroll view is scrolled to the top (`scrollView.contentOffset.y <= 0`)
     */
    let shouldDragViewDown = isScrollingDown && scrollView.contentOffset.y <= 0

    /*
     The user should be able to drag the view up through the internal scroll view when
     - the scroll direction is up (`!isScrollingDown`)
     - the PullUpController's view is fully opened. (`topConstraint.constant <= parentViewHeight - lastStickyPoint`)
     */
    let shouldDragViewUp = !isScrollingDown && !isFullOpened
    let shouldDragView = shouldDragViewDown || shouldDragViewUp

    if shouldDragView {
      scrollView.bounces = false
      scrollView.setContentOffset(.zero, animated: false)
    } // end if

    switch gestureRecognizer.state {
    case .began:
      initialInternalScrollViewContentOffset = scrollView.contentOffset

    case .changed:
      guard
        shouldDragView
      else { break }
      setTopOffset(topConstraint.constant + yTranslation - initialInternalScrollViewContentOffset.y)
      gestureRecognizer.setTranslation(initialInternalScrollViewContentOffset, in: scrollView)

    case .ended:
      scrollView.bounces = true
      goToNearestStickyPoint(verticalVelocity: gestureRecognizer.velocity(in: view).y)

    default:
      break
    } // end if
  } // end @objc private func handleScrollViewGestureRecognizer

  @objc private func handlePanGestureRecognizer(_ gestureRecognizer: UIPanGestureRecognizer) {
    guard
      isPortrait,
      let topConstraint = topConstraint
    else { return }

    let yTranslation = gestureRecognizer.translation(in: view).y

    switch gestureRecognizer.state {
    case .changed:
      setTopOffset(topConstraint.constant + yTranslation, allowBounce: true)
      gestureRecognizer.setTranslation(.zero, in: view)

    case .ended:
      goToNearestStickyPoint(verticalVelocity: gestureRecognizer.velocity(in: view).y)

    default:
      break
    }
  } // end @objc private func handlePanGestureRecognizer

  private func goToNearestStickyPoint(verticalVelocity: CGFloat) {
    guard
      isPortrait,
      let topConstraint = topConstraint
    else { return }
    let targetTopOffset = nearestStickyPointY(yVelocity: verticalVelocity) // v = px/s
    let distanceToConver = topConstraint.constant - targetTopOffset // px
    let animationDuration = max(0.08, min(0.3, TimeInterval(abs(distanceToConver / verticalVelocity)))) // s = px/v
    setTopOffset(targetTopOffset, animationDuration: animationDuration)
  } // end private func goToNearestStickyPoint

  private func setTopOffset(
    _ value: CGFloat,
    animationDuration: TimeInterval? = nil,
    allowBounce: Bool = false
  ) {
    var minTopPosition = CGFloat(0.0)
    let current: UIDevice = UIDevice.current
    let hasNotch: Bool = current.hasNotch
    
    if !hasNotch {
      minTopPosition = parent?.topBarHeight ?? 0.0
    }
    
    guard
      let parentViewHeight = parent?.view.frame.height
        
    else { return }
    // Apply right value bounding for the provided bounce offset if needed
    let value: CGFloat = {
      guard
        let firstStickyPoint = bottomSheetAllStickyPoints.first,
        let lastStickyPoint = bottomSheetAllStickyPoints.last
      else {
        return value
      }
      let bounceOffset = allowBounce ? bottomSheetBounceOffset : 0
      let minValue = parentViewHeight - lastStickyPoint - bounceOffset
      let maxValue = parentViewHeight - firstStickyPoint + bounceOffset
      
      return max(min(value, maxValue), minValue, minTopPosition)
    }()

    let targetPoint = parentViewHeight - value
    
    /*
     `willMoveToStickyPoint` and `didMoveToStickyPoint` should be
     called only if the user has ended the gesture
     */
    let shouldNotifyObserver = animationDuration != nil
    topConstraint?.constant = value
    
    bottomSheetDidDrag(to: targetPoint)
    if shouldNotifyObserver {
      bottomSheetWillMove(to: targetPoint)
    } // end if
    bottomSheetAnimate(
      action: .move,
      withDuration: animationDuration ?? 0,
      animations: { [weak self] in
        self?.parent?.view.layoutIfNeeded()
      },
      completion: { [weak self] _ in
        if shouldNotifyObserver {
          self?.bottomSheetDidMove(to: targetPoint)
        } // end if
      } // end closure
    ) // end bottomSheetAnimate
  } // end private func setTopOffset

  private func setPortraitConstraints(parentViewSize: CGSize, customTopOffset: CGFloat? = nil) {
    if let customTopOffset = customTopOffset {
      topConstraint?.constant = customTopOffset
    } else {
      topConstraint?.constant = nearestStickyPointY(yVelocity: 0)
    } // end if

    leftConstraint?.constant = (parentViewSize.width - min(bottomSheetPreferredSize.width, parentViewSize.width)) / 2
    widthConstraint?.constant = bottomSheetPreferredSize.width
    heightConstraint?.constant = bottomSheetPreferredSize.height
    heightConstraint?.priority = .defaultLow
    bottomConstraint?.constant = 0
  } // end private func setPortraitConstraints

  private func setLandscapeConstraints() {
    let landscapeFrame = bottomSheetPreferredLandscapeFrame
    topConstraint?.constant = landscapeFrame.origin.y + (bottomSheetAllStickyPoints.first ?? 0)
    leftConstraint?.constant = landscapeFrame.origin.x
    widthConstraint?.constant = landscapeFrame.width
    heightConstraint?.constant = landscapeFrame.height
    heightConstraint?.priority = .defaultLow
    bottomConstraint?.constant = landscapeFrame.origin.y
  } // end private func setLandscapeConstraints
} // end open class BottomSheetController


extension BottomSheetController {
  public enum ExpansionState {
    case expanded
    case middle
    case contracted
    case unknown
  }
}
