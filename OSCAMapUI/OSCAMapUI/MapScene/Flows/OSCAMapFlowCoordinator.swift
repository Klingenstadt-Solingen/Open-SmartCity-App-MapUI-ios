//
//  OSCAMapFlowCoordinator.swift
//  OSCAMapUI
//
//  Created by Stephan Breidenbach on 14.08.22.
//  Reviewed by Stephan Breidenbach on 08.09.22
//  Copyright © 2020 Stadt Solingen. All rights reserved.
//

import MessageUI
import OSCAEssentials
import OSCAMap
import SafariServices
import UIKit

// MARK: - OSCAMapFlowCoordinatorDependencies

public protocol OSCAMapFlowCoordinatorDependencies {
  var deeplinkScheme: String { get }
  func makeMapViewController(actions: OSCAMapViewModel.Actions) -> OSCAMapViewController
  func makeContainerViewController(actions: OSCAMapContainerViewModel.Actions) -> OSCAMapContainerViewController
  func makeCategoryViewController(actions: OSCAMapCategoryViewModel.Actions) -> OSCAMapCategoryViewController
  func makeCategoryDetailViewController(actions: OSCAMapCategoryDetailViewModel.Actions, category: OSCAPoiCategory) -> OSCAMapCategoryDetailViewController
  func makeCategoryDetailListViewController(actions: OSCAMapCategoryDetailListViewModel.Actions, category: OSCAPoiCategory, categoryPois: [OSCAPoi]) -> OSCAMapCategoryDetailListViewController
  func makePoiDetailsViewController(
    actions: OSCAPOIDetailViewModel.Actions,
    poi: OSCAPoi
  ) -> OSCAPOIDetailViewController
} // end public protocol OSCAMapFlowCoordinatorDependencies

// MARK: - OSCAMapFlowCoordinator

public final class OSCAMapFlowCoordinator: NSObject, Coordinator {
  // MARK: Lifecycle

  public init(
    router: Router,
    dependencies: OSCAMapFlowCoordinatorDependencies
  ) {
    self.router = router
    self.dependencies = dependencies
  } // end public init

  // MARK: Public

  /**
   `children`property for conforming to `Coordinator` protocol is a list of `Coordinator`s
   */
  public var children: [Coordinator] = []

  /**
   router injected via initializer: `router` will be used to push and pop view controllers
   */
  public var router: Router
  
  // MARK: - Poi category detail list
  
  private func showCategoryDetailList(category: OSCAPoiCategory, categoryPois: [OSCAPoi]) {
    if let vc = self.categoryDetailListVC,
       vc.viewModel.category == category,
       vc.viewModel.categoryPois == categoryPois {
      self.containerNC?.pushViewController(vc, animated: true)
      
    } else {
      let actions = OSCAMapCategoryDetailListViewModel.Actions()
      
      let vc = self.dependencies.makeCategoryDetailListViewController(
        actions: actions,
        category: category,
        categoryPois: categoryPois)
      vc.delegate = self
      vc.delegateContainer = self.containerVC.self
      self.categoryDetailListVC = vc
      
      self.containerNC?.pushViewController(vc, animated: true)
    }
  }
  
  // MARK: - Poi category detail
  
  
  private func skipToCategoryItemFullList() {
    guard let categoryDetailVC = self.categoryDetailVC,
          let category = self.categoryDetailVC?.viewModel.category,
          categoryDetailVC.viewModel.filterFields.isEmpty
    else { return }
    
    self.showCategoryDetailList(category: category, categoryPois: [])
    self.categoryDetailListVC?.viewModel.fetchCategoryPois()
  }
  
  private func showCategoryDetail(category: OSCAPoiCategory) {
    if let categoryVC = self.categoryVC {
      if let nc = self.containerNC,
         let categoryDetailVC = self.categoryDetailVC,
         categoryDetailVC.viewModel.category == category {
        
        if category.filterFields != nil && category.filterFields!.isEmpty {
          skipToCategoryItemFullList()
        } else if nc.viewControllers.contains(categoryDetailVC) {
          nc.popToViewController(categoryDetailVC, animated: true)
        } else {
          self.containerNC?.popToViewController(categoryVC, animated: false)
          self.containerNC?.pushViewController(categoryDetailVC, animated: true)
        }
        
        
      } else {
        let actions = OSCAMapCategoryDetailViewModel.Actions(
          showCategoryDetailList: self.showCategoryDetailList
        )
        
        let categoryDetailVC = self.dependencies.makeCategoryDetailViewController(
          actions: actions,
          category: category)
        categoryDetailVC.delegate = self
        categoryDetailVC.delegateContainer = self.containerVC.self
        self.categoryDetailVC = categoryDetailVC
        
        if category.filterFields != nil && category.filterFields!.isEmpty {
          skipToCategoryItemFullList()
        } else {
          self.containerNC?.popToViewController(categoryVC, animated: false)
          self.containerNC?.pushViewController(categoryDetailVC, animated: true)
        }
      }
    }
  }
  
  
  // MARK: - Poi category
  
  public func showCategories(with deeplink: String? = nil) {
    print(#function)
    // ensure parent view controller exits
    guard let mapVC = self.mapVC else { return }

    let actions = OSCAMapContainerViewModel.Actions()
    
    // there is already a category bottom sheet
    if let containerVC = self.containerVC {
//      // remove the current category sheet
//      mapVC.removeBottomSheet(containerVC, animated: true)
      containerVC.show()
    } else {
      let categoryActions = OSCAMapCategoryViewModel.Actions(
        showCategoryDetail: self.showCategoryDetail)
      let categoryVC = dependencies.makeCategoryViewController(
        actions: categoryActions)
      
      let viewController = dependencies.makeContainerViewController(
        actions: actions
      )
      
      categoryVC.delegate = self
      categoryVC.delegateContainer = viewController.self
      categoryVC.didReceiveDeeplink(with: deeplink)
      
      self.categoryVC = categoryVC
      
      let containerNC = UINavigationController(rootViewController: categoryVC)
      self.containerNC = containerNC

      viewController.addChild(containerNC)
      containerNC.view.frame = viewController.view.bounds
      viewController.container.addSubview(containerNC.view)
      
      containerNC.view.translatesAutoresizingMaskIntoConstraints = false
      NSLayoutConstraint.activate([
        containerNC.view.leadingAnchor.constraint(equalTo: viewController.container.leadingAnchor),
        containerNC.view.trailingAnchor.constraint(equalTo: viewController.container.trailingAnchor),
        containerNC.view.topAnchor.constraint(equalTo: viewController.container.topAnchor),
        containerNC.view.bottomAnchor.constraint(equalTo: viewController.container.bottomAnchor)])

      containerNC.didMove(toParent: viewController)
      
      self.containerVC = viewController
      
      let offset: CGFloat = UIDevice.current.userInterfaceIdiom == .phone ? 300 : 500
      mapVC.addBottomSheet(
        viewController,
        initialStickyPointOffset: offset,
        animated: true
      )
    }
    
  }

  // MARK: - Poi details
  
  let detailsInitialStickyPointOffset: CGFloat = UIDevice.current.userInterfaceIdiom == .phone ? 300 : 500
  let detailsClosingPosition: CGFloat = 100

  public func showDetails(of poi: OSCAPoi) {
    // ensure parent view controller exits
    guard let mapVC = mapVC else { return }

    let actions = OSCAPOIDetailViewModel.Actions(
      closeDetailSheet: closeDetailSheet,
      openWebsite: openWebsite(_:),
      initPhoneCall: initPhoneCall(_:),
      openMenu: openMenu(_:),
      share: share(_:),
      sentEmail: sendEmail(_:),
      openDirections: calcDirections(_:),
      showFullscreenImage: openFullscreenImage(_:)
    )// end actions

    // there is already a poi details bottom sheet
    if let poiDetailsVC = poiDetailsVC {
      // remove the current poi details sheet
      mapVC.removeBottomSheet(poiDetailsVC, animated: true)

      // let's create a new one
      let viewController = dependencies
        .makePoiDetailsViewController(actions: actions,
                                      poi: poi)
      self.poiDetailsVC = viewController
      mapVC.addBottomSheet(viewController,
                           initialStickyPointOffset: detailsInitialStickyPointOffset,
                           animated: true,
                           onBottomSheetMoved: closeDetailsIfNeeded
      )
    } else {
      let viewController = dependencies
        .makePoiDetailsViewController(actions: actions,
                                      poi: poi)
      poiDetailsVC = viewController
      mapVC.addBottomSheet(viewController,
                           initialStickyPointOffset: detailsInitialStickyPointOffset,
                           animated: true,
                           onBottomSheetMoved: closeDetailsIfNeeded
      )
    }// end if
    
    closeCategoriesSheet()
  } // end public func show details of poi

  public func closeDetailSheet() {
    guard let mapVC = mapVC,
          let poiDetailsVC = poiDetailsVC else { return }

    if let categoryDetailViewModel = self.categoryDetailVC?.viewModel {
      categoryDetailViewModel.fetchCategoryPoisForSelectedFilters()
    }
    
    mapVC.removeBottomSheet(poiDetailsVC, animated: true)
    self.poiDetailsVC = nil
    
    showCategories()
  }// end public func closeDetailSheet
  
  private func closeDetailsIfNeeded(yPosition: CGFloat) {
    if yPosition < detailsClosingPosition {
      closeDetailSheet()
    }
  }
  
  public func closeCategoriesSheet() {
    guard let _ = mapVC else { return }
    if let containerVC = self.containerVC {
//      mapVC.removeBottomSheet(containerVC, animated: true)
      containerVC.hide()
    }
  }

  public func openWebsite(_ url: URL) {
    let viewController = SFSafariViewController(url: url)
    viewController.preferredControlTintColor = OSCAMapUI.configuration.colorConfig.accentColor

    router.present(viewController, animated: true)
  }// end func openWebsite

  public func openFullscreenImage(_ image: UIImage) {
    let imageView = UIImageView(image: image)
    imageView.frame = UIScreen.main.bounds
    imageView.backgroundColor = .clear
    imageView.contentMode = .scaleAspectFit
    imageView.isUserInteractionEnabled = true
    let tap = UITapGestureRecognizer(target: self, action: #selector(dismissFullscreenImage))
    imageView.addGestureRecognizer(tap)
    let pinchMethod = UIPinchGestureRecognizer(target: self, action: #selector(pinchImage(sender:)))
    imageView.addGestureRecognizer(pinchMethod)
    let panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.panActionmoveImage))
    panGesture.minimumNumberOfTouches = 1
    panGesture.maximumNumberOfTouches = 2
    imageView.addGestureRecognizer(panGesture)
    let blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffect.Style.dark))
    blurEffectView.frame = (mapVC?.view.bounds)!
    blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    mapVC?.view.addSubview(blurEffectView)
    mapVC?.view.addSubview(imageView)
    mapVC?.navigationController?.isNavigationBarHidden = true
    mapVC?.tabBarController?.tabBar.isHidden = true
  }// end func openFullscreenImage
    
    @objc func pinchImage(sender: UIPinchGestureRecognizer) {
        if let scale = (sender.view?.transform.scaledBy(x: sender.scale, y: sender.scale)) {
          guard scale.a > 1.0 else { return }
          guard scale.d > 1.0 else { return }
          sender.view?.transform = scale
          sender.scale = 1.0
        }
    }
    @objc func panActionmoveImage(gesture: UIPanGestureRecognizer) {
        var state = gesture.state;

        if (state == .began || state == .changed) {
            var view = gesture.view;
            var translation = gesture.translation(in: view)
            
            view!.center = CGPoint(x: view!.center.x + translation.x, y: view!.center.y + translation.y)
            gesture.setTranslation(CGPoint.zero, in: view)
        }
    }

  @objc func dismissFullscreenImage(_ sender: UITapGestureRecognizer) {
    mapVC?.navigationController?.isNavigationBarHidden = false
    mapVC?.tabBarController?.tabBar.isHidden = false
    mapVC?.view?.subviews.filter{$0 is UIVisualEffectView}.forEach{ blurView in
        blurView.removeFromSuperview()
    }
    sender.view?.removeFromSuperview()
  }// end func dismissFullscreenImage

  public func initPhoneCall(_ phoneNumber: String) {
    if let phoneCallURL = URL(string: "tel://\(phoneNumber)") {
      let application = UIApplication.shared
      if application.canOpenURL(phoneCallURL) {
        application.open(phoneCallURL, options: [:], completionHandler: nil)
      }
    }
  }// end func initPhoneCall

  public func openMenu(_ url: URL) {
    let viewController = SFSafariViewController(url: url)
    viewController.preferredControlTintColor = OSCAMapUI.configuration.colorConfig.primaryColor

    router.present(viewController, animated: true)
  }// end func openMenu

  public func share(_ poi: OSCAPoi) {
    guard let mapVC = mapVC else { return }
    let shareItems =
    [
      "TODO: Text muss noch definiert werden!\n\nGeteiltes Objekt:\nObjectId: \(poi.objectId ?? "")\nName: \(poi.name ?? "")",
    ]
    let activityController = UIActivityViewController(activityItems: shareItems,
                                                      applicationActivities: nil)
    if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
      activityController.popoverPresentationController?.sourceView = mapVC.view
      activityController.popoverPresentationController?.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2, width: 0, height: 0)
    }// end if
    mapVC.present(activityController,
                  animated: true)
  }// end func share

  public func calcDirections(_ poi: OSCAPoi) {
    let alert = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
    let googleAction = UIAlertAction(
      title: NSLocalizedString(
        "CALC_DIRECTIONS_GOOGLE_TITLE",
        bundle: OSCAMapUI.bundle,
        comment: "CALC_DIRECTIONS_GOOGLE_TITLE"
      ),
      style: .default,
      handler: { _ in
        guard let lat = poi.geopoint?.latitude, let lon = poi.geopoint?.longitude else { return }

        var travelmode = "driving"

        switch poi.routeType {
        case .car:
          travelmode = "driving"
        case .walk:
          travelmode = "walking"
        case .bicycle:
          travelmode = "bicycling"
        case .none:
          break
        }

        let urlString = "https://www.google.com/maps/dir/?api=1&destination=\(lat),\(lon)&travelmode=\(travelmode)"
        if let url = URL(string: urlString) {
          if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
          }
        }
      }
    )
    let mapsAction = UIAlertAction(
      title: NSLocalizedString(
        "CALC_DIRECTIONS_MAPS_TITLE",
        bundle: OSCAMapUI.bundle,
        comment: "CALC_DIRECTIONS_MAPS_TITLE"
      ),
      style: .default,
      handler: { _ in
        guard let lat = poi.geopoint?.latitude, let lon = poi.geopoint?.longitude else { return }

        var travelmode = "d"

        switch poi.routeType {
        case .car:
          travelmode = "d"
        case .walk:
          travelmode = "w"
        case .bicycle:
          break
        case .none:
          break
        }

        let urlString = "https://maps.apple.com/?daddr=\(lat),\(lon)&dirflg=\(travelmode)&t=m"
        if let url = URL(string: urlString) {
          if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
          }
        }
      }
    )
    let cancelAction = UIAlertAction(
      title: NSLocalizedString(
        "CALC_DIRECTIONS_CANCEL_TITLE",
        bundle: OSCAMapUI.bundle,
        comment: "CALC_DIRECTIONS_CANCEL_TITLE"
      ),
      style: .cancel
    )

    alert.addAction(googleAction)
    alert.addAction(mapsAction)
    alert.addAction(cancelAction)

    mapVC?.present(alert, animated: true)
  }// func calcDirections

  public func sendEmail(_ address: String) {
    if MFMailComposeViewController.canSendMail() {
      let mail = MFMailComposeViewController()
      mail.mailComposeDelegate = self
      mail.setToRecipients([address])
      mail.setMessageBody("", isHTML: true)

      mapVC?.present(mail, animated: true)
    } else {
      let alert = UIAlertController(
        title: NSLocalizedString(
          "ERROR_MAIL_NOT_AVAILABLE_TITLE",
          bundle: OSCAMapUI.bundle,
          comment: "ERROR_MAIL_NOT_AVAILABLE_TITLE"
        ),
        message: NSLocalizedString(
          "ERROR_MAIL_NOT_AVAILABLE_MESSAGE",
          bundle: OSCAMapUI.bundle,
          comment: "ERROR_MAIL_NOT_AVAILABLE_MESSAGE"
        ),
        preferredStyle: .alert
      )
      alert.addAction(
        UIAlertAction(
          title: NSLocalizedString(
            "ERROR_MAIL_NOT_AVAILABLE_ACTION",
            bundle: OSCAMapUI.bundle,
            comment: "ERROR_MAIL_NOT_AVAILABLE_ACTION"
          ),
          style: .default
        )
      )
      mapVC?.present(alert, animated: true)
    }
  }// end func sendEmail

  // MARK: - Map

  public func showMap(animated: Bool, onDismissed: (() -> Void)?) -> Void {
    if let mapVC = self.mapVC {
      self.router.present(
        mapVC,
        animated: true)
      
    } else {
      // Note: here we keep strong reference with actions, this way this flow do not need to be strong referenced
      let actions = OSCAMapViewModel.Actions(
        showDefaultCategories: self.showCategories(with:),
        showDetails: showDetails(of:)
      )// end actions
      // instantiate view controller
      let viewController = dependencies.makeMapViewController(actions: actions)

      router.present(
        viewController,
        animated: animated,
        onDismissed: onDismissed
      )// end present
      mapVC = viewController
    }
  } // end public func showMap

  public func present(animated: Bool, onDismissed: (() -> Void)?) -> Void {
    #if DEBUG
      print("\(String(describing: self)): \(#function)")
    #endif
    showMap(animated: animated,
            onDismissed: onDismissed)
  } // end public func present

  /**
   dependencies injected via initializer DI conforming to the `OSCAMKOSCAMapFlowCoordinatorDependencies` protocol
   */
  let dependencies: OSCAMapFlowCoordinatorDependencies
  
  let imageDataCache = NSCache<NSString, NSData>()
  
  /// weak handle to the map view controller
  weak var mapVC: OSCAMapViewController?
  /// weak handle to the category view controller
  private weak var containerVC: OSCAMapContainerViewController?
  weak var containerNC: UINavigationController?
  /// weak handle to the category view controller
  weak var categoryVC: OSCAMapCategoryViewController?
  /// weak handle to the category detail view controller
  weak var categoryDetailVC: OSCAMapCategoryDetailViewController?
  /// weak handle to the category detail list view controller
  private weak var categoryDetailListVC: OSCAMapCategoryDetailListViewController?
  /// weak handle to the poi details view controller
  private weak var poiDetailsVC: OSCAPOIDetailViewController?
  /// weak handle to the bottom sheet view controller
  private weak var bottomSheetVC: BottomSheetController?
} // end public final class OSCAMapFlowCoordinator

// MARK: OSCAMapCategoryDelegate

extension OSCAMapFlowCoordinator: OSCAMapCategoryDelegate {  
  func categorySheet(with pois: [OSCAPoi]) {
    guard let map = self.mapVC else { return }
    map.viewModel.setPois(pois)
  }

  func categorySheet(didSelect poi: OSCAPoi) {
    guard let map = self.mapVC else { return }
    map.viewModel.setSelectedPOI(poi)
  }
}// enxtension final class OSCAMapFlowCoordinator

// MARK: MFMailComposeViewControllerDelegate

extension OSCAMapFlowCoordinator: MFMailComposeViewControllerDelegate {
  public func mailComposeController(
    _ controller: MFMailComposeViewController,
    didFinishWith _: MFMailComposeResult,
    error _: Error?
  ) {
    controller.dismiss(animated: true)
  }// end public func mailComposeController
}// enxtension final class OSCAMapFlowCoordinator
