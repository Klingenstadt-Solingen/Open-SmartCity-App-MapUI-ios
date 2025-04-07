//
//  OSCAMapUI+ViewModel.swift
//  OSCAMapUI
//
//  Created by Stephan Breidenbach on 15.08.22.
//  Copyright © 2020 Stadt Solingen. All rights reserved.
//

import Combine
import Foundation
import OSCAEssentials
import OSCAMap

// MARK: - ViewModel
extension OSCAMapUI {} // end extension public struct

// MARK: - Dependencies
public extension OSCAMapUI.ViewModel {
  struct Dependencies {
    // MARK: Lifecycle

    public init(
      dataModule: OSCAMap,
      uiModuleConfig: OSCAMapUI.Config,
      colorConfig: OSCAColorSettings,
      fontConfig: OSCAFontSettings
    ) {
      self.dataModule = dataModule
      uiModuleConf = uiModuleConfig
      colorConf = colorConfig
      fontConf = fontConfig
    } // end memberwise init

    // MARK: Public

    /// data module instance
    public let dataModule: OSCAMap
    /// UIModule configuration instance
    public let uiModuleConf: OSCAMapUI.Config
    /// color configuration instance
    public let colorConf: OSCAColorSettings
    /// typeface configuration instance
    public let fontConf: OSCAFontSettings
  } // end public struct Dependencies
} // end extension

// MARK: - INPUT lifecycle
extension OSCAMapUI.ViewModel {
  @objc
  open func viewDidLoad() {
    #if DEBUG
      print("\(String(describing: self)): \(#function)")
    #endif
  } // end public func viewDidLoad

  @objc
  open func viewWillLayoutSubviews() {
    #if DEBUG
      print("\(String(describing: self)): \(#function)")
    #endif
  } // end public func viewDidLoad

  @objc
  open func viewDidLayoutSubviews() {
    #if DEBUG
      print("\(String(describing: self)): \(#function)")
    #endif
  } // end public func viewDidLayoutSubviews

  @objc
  open func viewWillAppear() {
    #if DEBUG
      print("\(String(describing: self)): \(#function)")
    #endif
  } // end public func viewWillAppear

  @objc
  open func viewDidAppear() {
    #if DEBUG
      print("\(String(describing: self)): \(#function)")
    #endif
  } // end public func viewDidAppear

  @objc
  open func viewWillDisappear() {
    #if DEBUG
      print("\(String(describing: self)): \(#function)")
    #endif
  } // end public func viewWillDisappear

  @objc
  open func viewDidDisappear() {
    #if DEBUG
      print("\(String(describing: self)): \(#function)")
    #endif
  } // end public func viewDidDisappear
} // end extension public class ViewModel

// MARK: - OUTPUT
public extension OSCAMapUI.ViewModel {
  var dataModule: OSCAMap {
    dependencies.dataModule
  } // end public var dataModule

  var uiModuleConfig: OSCAMapUI.Config {
    dependencies.uiModuleConf
  } // end public var uiModuleConfig

  var colorConfig: OSCAColorConfig {
    dependencies.colorConf
  } // end public var colorConfig

  var fontConfig: OSCAFontConfig {
    dependencies.fontConf
  } // end public var fontConfig
} // end extension public class ViewModel

// MARK: - OUTPUT localized strings
extension OSCAMapUI.ViewModel {
  public var alertTitleError: String {
    NSLocalizedString(
      "alert_title_error",
      bundle: OSCAMapUI.bundle,
      comment: "The alert title for an error"
    )
  }

  public var alertActionConfirm: String {
    NSLocalizedString(
      "alert_title_confirm",
      bundle: OSCAMapUI.bundle,
      comment: "The alert action title to confirm"
    )
  }
} // end extension public class ViewModel

// MARK: - State
public extension OSCAMapUI.ViewModel {
  enum State {
    case loading
    case finishedLoading
    case error
  } // end public enum State
} // end extension public class MapViewModel
