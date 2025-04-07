//
//  MapFlow+OSCADeeplinkHandeble.swift
//  OSCAMapUI
//
//  Created by Stephan Breidenbach on 08.09.22.
//  Copyright © 2020 Stadt Solingen. All rights reserved.
//

import Foundation
import OSCAEssentials

extension OSCAMapFlowCoordinator: OSCADeeplinkHandeble {
  // swiftlint:disable comments_space
  /// ```console
  /// xcrun simctl openurl booted \
  /// "solingen://poi/detail?object=TFAc70U6mg&center=51.1861354,7.0843591&span=100"
  /// ```
  public func canOpenURL(_ url: URL) -> Bool {
    let deeplinkScheme: String = dependencies
      .deeplinkScheme
    return url.absoluteString.hasPrefix("\(deeplinkScheme)://poi")
  }// end public func canOpenURL
  // swiftlint:enable comments_space
  
  public func openURL(_ url: URL,
                      onDismissed:(() -> Void)?) throws -> Void {
    guard canOpenURL(url)
    else { return }
    let deeplinkParser = DeeplinkParser()
    if let payload = deeplinkParser.parse(content: url) {
      switch payload.target {
      case "detail":
        let objectId = payload.parameters["object"]
        let center = payload.parameters["center"]
        let span = payload.parameters["span"]
        showMap(with: objectId, center, span, onDismissed: onDismissed)
        
      case "categories":
        self.closeDetailSheet()
        let objectId = payload.parameters["object"]
        self.showMapCategory(with: objectId, onDismissed: onDismissed)
        
      case "emergency_services":
        self.closeDetailSheet()
        self.showMapCategory(with: "notdienste", onDismissed: onDismissed)
        
      default:
        self.closeDetailSheet()
        if let navigation = self.containerNC {
          navigation.popToRootViewController(animated: false)
        }
        showMap(animated: true,
                onDismissed: onDismissed)
      }
    } else {
      self.closeDetailSheet()
      if let navigation = self.containerNC {
        navigation.popToRootViewController(animated: false)
      }
      showMap(animated: true,
              onDismissed: onDismissed)
    }// end if
  }// end public func openURL
  
  public func showMap(with objectId: String? = nil,
                      _ center: String? = nil,
                      _ span: String? = nil,
                      onDismissed:(() -> Void)?) -> Void {
#if DEBUG
    print("\(String(describing: self)): \(#function): objectId: \(objectId ?? "NIL") center: \(center ?? "NIL") span: \(span ?? "NIL")")
#endif
    if let objectId = objectId {
      self.showMap(animated: true,
                   onDismissed: onDismissed)
      guard let mapVC = self.mapVC
      else { return }
      mapVC.didReceiveDeeplinkDetail(with: objectId,
                                     center,
                                     span)
    }// end if
  }// end showMap
  
  public func showMapCategory(with objectId: String?, onDismissed:(() -> Void)?) -> Void {
#if DEBUG
    print("\(String(describing: self)): \(#function): objectId: \(String(describing: objectId))")
#endif
    if let categorVC = self.categoryVC {
      self.showMap(animated: true,
                   onDismissed: onDismissed)
      mapVC?.didReceiveDeeplink(with: objectId)
      
      categorVC.didReceiveDeeplink(with: objectId)
      
    } else {
      self.showMap(animated: true,
                   onDismissed: onDismissed)
      guard let mapVC = self.mapVC else { return }
      mapVC.didReceiveDeeplink(with: objectId)
    }
  }
}// end extension OSCAMapFlowCoordinator
