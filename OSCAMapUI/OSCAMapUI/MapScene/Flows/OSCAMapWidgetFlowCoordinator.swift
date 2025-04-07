//
//  OSCAMapWidgetFlowCoordinator.swift
//  OSCAMapUI
//
//  Created by Igor Dias on 08.05.23.
//


import OSCAEssentials
import Foundation

public protocol OSCAMapWidgetFlowCoordinatorDependencies {
  func makeOSCAMapMainWidgetViewController(actions: OSCAMapMainWidgetViewModel.Actions) -> OSCAMapMainWidgetViewController
  
  func makeMapFlowCoordinator(router: Router) -> OSCAMapFlowCoordinator
}

public final class OSCAMapWidgetFlowCoordinator: Coordinator {
  /**
   `children`property for conforming to `Coordinator` protocol is a list of `Coordinator`s
   */
  public var children: [Coordinator] = []
  /**
   router injected via initializer: `router` will be used to push and pop view controllers
   */
  public let router: Router
  /**
   dependencies injected via initializer DI conforming to the `OSCAMapWidgetFlowCoordinatorDependencies` protocol
   */
  let dependencies: OSCAMapWidgetFlowCoordinatorDependencies
  /**
   waste view controller `OSCAMapMainWidgetViewController`
   */
  var childFlow: Coordinator?
  public weak var mapMainWidgetVC: OSCAMapMainWidgetViewController?
  public weak var mapFlow: OSCAMapFlowCoordinator?
  
  public init(router: Router, dependencies: OSCAMapWidgetFlowCoordinatorDependencies) {
    self.router = router
    self.dependencies = dependencies
  }
  
  func showMapMainWidget(animated: Bool, onDismissed: (() -> Void)?) -> Void {
#if DEBUG
    print("\(String(describing: self)): \(#function)")
#endif
    let actions = OSCAMapMainWidgetViewModel.Actions(
      showMapScene: self.showMapScene,
      showMapSceneWithURL: self.showMapSceneWithURL(url:)
    )
    let vc = self.dependencies
      .makeOSCAMapMainWidgetViewController(actions: actions)
    self.mapMainWidgetVC = vc
  }
  
  
  func getMapFlow() -> OSCAMapFlowCoordinator? {
    let mapFlow = self.mapFlow ?? dependencies.makeMapFlowCoordinator(router: self.router)
    self.mapFlow = mapFlow
    return self.mapFlow
  }
  
  func showMapScene() {
    guard let mapFlow = getMapFlow() else { return }
    self.presentChild(mapFlow, animated: true)
  }
  
  func showMapSceneWithURL(url: URL){
    guard let mapFlow = getMapFlow() else { return }
    do {
      if mapFlow.canOpenURL(url) {
        try mapFlow.openURL(url, onDismissed: nil)
      }
    } catch {
      return
    }
  }
  
  public func present(animated: Bool, onDismissed: (() -> Void)?) {
#if DEBUG
    print("\(String(describing: self)): \(#function)")
#endif
    self.showMapMainWidget(
      animated: animated,
      onDismissed: onDismissed)
  }
}

extension OSCAMapWidgetFlowCoordinator {
  /**
   add `child` `Coordinator`to `children` list of `Coordinator`s and present `child` `Coordinator`
   */
  public func presentChild(_ child: Coordinator, animated: Bool, onDismissed: (() -> Void)? = nil) {
    self.children.append(child)
    child.present(animated: animated) { [weak self, weak child] in
      guard let self = self, let child = child else { return }
      self.removeChild(child)
      onDismissed?()
    }
  }
  
  private func removeChild(_ child: Coordinator) {
    /// `children` includes `child`!!
    guard let index = self.children.firstIndex(where: { $0 === child })
    else { return }
    self.children.remove(at: index)
  }
}
