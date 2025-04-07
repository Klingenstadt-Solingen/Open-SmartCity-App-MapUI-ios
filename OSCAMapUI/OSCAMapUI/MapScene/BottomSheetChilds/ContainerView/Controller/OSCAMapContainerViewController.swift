//
//  OSCAMapContainerViewController.swift
//  OSCAMapUI
//
//  Created by Ömer Kurutay on 05.01.23.
//

import OSCAEssentials
import UIKit

protocol OSCAMapContainerViewControllerDelegate: AnyObject {
  var stickyPoints: [CGFloat] { get }
  func bottomSheet(moveTo visiblePoint: CGFloat, animated: Bool, completion: (() -> Void)?)
}

public final class OSCAMapContainerViewController: BottomSheetController {
  
  @IBOutlet private var dragView: UIView! {
    didSet {
      self.dragView.layer.cornerRadius = self.dragView.frame.height / 2
    }
  }
  
  @IBOutlet private var visualEffectView: UIVisualEffectView!
  @IBOutlet var container: UIView!
  
  // MARK: - BottomSheet config
  var initialPointOffset: CGFloat {
    switch self.initialState {
    case .contracted:
      return 71
    case .expanded:
      return self.bottomSheetPreferredSize.height
    }
  }
  
  enum InitialState {
    case contracted
    case expanded
  }

  var initialState: InitialState = .contracted
  
  public var portraitSize: CGSize = .zero

  override public var bottomSheetPreferredSize: CGSize {
    CGSize(
      width: min(UIScreen.main.bounds.width, UIScreen.main.bounds.height),
      height: self.container.bounds.maxY)
  }
  
  public override var bottomSheetPreferredLandscapeFrame: CGRect {
    CGRect(
      origin: CGPoint(x: 10, y: 10),
      size: CGSize(width: max(UIScreen.main.bounds.width, UIScreen.main.bounds.height) * 0.35,
                   height: self.container.bounds.maxY - 20))
  }

  public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    coordinator.animate { _ in
      self.updatePreferredFrameIfNeeded(animated: true)
      let corners: CACornerMask = size.width < size.height
        ? [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        : [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
      self.view.layer.maskedCorners = corners
    }
  }
  
  override public var bottomSheetMiddleStickyPoints: [CGFloat] {
    switch self.initialState {
    case .contracted:
      return [74]
    case .expanded:
      return [self.container.frame.maxY]
    }
  }

  override public var bottomSheetBounceOffset: CGFloat {
    10
  }
  
  override public func bottomSheetAnimate(
    action: BottomSheetController.Action,
    withDuration _: TimeInterval,
    animations: @escaping () -> Void,
    completion: ((Bool) -> Void)?
  ) {
    switch action {
    case .move:
      UIView.animate(
        withDuration: 0.3,
        delay: 0,
        usingSpringWithDamping: 0.7,
        initialSpringVelocity: 0,
        options: .curveEaseInOut,
        animations: animations,
        completion: completion
      )
    default:
      UIView.animate(
        withDuration: 0.3,
        animations: animations,
        completion: completion
      )
    }
  }
  
  override public func bottomSheetWillMove(to point: CGFloat) {
    if point <= self.keyboardHeight {
      view.endEditing(true)
    }
  }
  
  private var viewModel: OSCAMapContainerViewModel!
  
  private var keyboardHeight: CGFloat = 0.0
  
  public override func viewDidLoad() {
    super.viewDidLoad()
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.keyboardWillShow),
      name: UIResponder.keyboardWillShowNotification,
      object: nil)
    
    self.setupViews()
  }
  
  private func setupViews() {
    self.view.backgroundColor = self.viewModel
      .colorConfig.backgroundColor
    self.view.layer.masksToBounds = true
    self.view.layer.cornerRadius = self.viewModel.dependencies
      .uiModuleConf.cornerRadius
    let corners: CACornerMask = self.isPortrait
      ? [.layerMinXMinYCorner, .layerMaxXMinYCorner]
      : [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
    self.view.layer.maskedCorners = corners
    
    self.dragView.backgroundColor = self.viewModel
      .colorConfig.grayColor
    self.container.backgroundColor = .clear
    
    self.dragView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dragViewTapped)))
  }
  
  @objc func dragViewTapped() {
    self.switchExpansionState()
  }
  
  @objc private func keyboardWillShow(_ notification: Notification) {
    if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
      let keyboardRectangle = keyboardFrame.cgRectValue
      self.keyboardHeight = keyboardRectangle.minY
    }
  }
}

// MARK: StoryboardInstantiable
extension OSCAMapContainerViewController: StoryboardInstantiable {
  /// function call: var vc = OSCAMapContainerViewController.create(viewModel)
  public static func create(with viewModel: OSCAMapContainerViewModel) -> OSCAMapContainerViewController {
    #if DEBUG
      print("\(String(describing: self)): \(#function)")
    #endif
    var bundle: Bundle
    #if SWIFT_PACKAGE
      bundle = OSCAMapUI.bundle
    #else
      bundle = Bundle(for: Self.self)
    #endif
    let viewController = Self.instantiateViewController(bundle)
    viewController.viewModel = viewModel
    return viewController
  }
}

// MARK: OSCAMapContainerViewControllerDelegate
extension OSCAMapContainerViewController: OSCAMapContainerViewControllerDelegate {
  var stickyPoints: [CGFloat] { self.bottomSheetAllStickyPoints }
  
  func bottomSheet(moveTo visiblePoint: CGFloat, animated: Bool, completion: (() -> Void)?) {
    self.bottomSheetMoveToVisiblePoint(visiblePoint, animated: animated, completion: completion)
  }
}
