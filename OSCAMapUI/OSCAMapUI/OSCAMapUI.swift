//
//  OSCAMapUI.swift
//  OSCAMapUI
//
//  Created by Stephan Breidenbach on 01.03.22.
//  Reviewed by Stephan Breidenbach on 11.08.22
//  Copyright © 2020 Stadt Solingen. All rights reserved.
//

import Combine
import Foundation
import OSCAEssentials
import OSCAMap
import UIKit

// MARK: - OSCAMapUI

/// map ui module
public struct OSCAMapUI: OSCAModule {
  // MARK: Lifecycle
  /// public initializer with module configuration
  /// - Parameter config: module configuration
  public init(with config: OSCAUIModuleConfig) {
#if SWIFT_PACKAGE
    // Self.bundle = .module
    Self.bundle = .module
#else
    guard let bundle = Bundle(identifier: bundlePrefix)
    else { fatalError("Module bundle not initialized!") }
    Self.bundle = bundle
#endif
    guard let extendedConfig = config as? OSCAMapUI.Config
    else { fatalError("Config couldn't be initialized!") }
    OSCAMapUI.configuration = extendedConfig
  } // end public init

  // MARK: Open
  open class ViewModel {
    // MARK: Lifecycle

    public init(dependencies: OSCAMapUI.ViewModel.Dependencies) {
      self.dependencies = dependencies
    } // end public init with dependencies

    // MARK: Open

    open var bindings: Set<AnyCancellable> = .init()

    // MARK: Internal

    let dependencies: OSCAMapUI.ViewModel.Dependencies
  } // end open class ViewModel

  // MARK: Public

  ///  module configuration
  public internal(set) static var configuration: OSCAMapUI.Config!

  /// module `Bundle`
  /// **available after module initialization only!!!**
  public internal(set) static var bundle: Bundle!

  /// version of the module
  public var version: String = "1.0.4"
  /// bundle prefix of the module
  public var bundlePrefix: String = "de.osca.map.ui"

  /**
   create module and inject module dependencies
   - Parameter mduleDependencies: module dependencies
   */
  public static func create(with moduleDependencies: OSCAMapUI.Dependencies) -> OSCAMapUI {
    var module = Self(with: moduleDependencies.moduleConfig)
    module.moduleDIContainer = OSCAMapUI.DIContainer(dependencies: moduleDependencies)
    return module
  } // end public static func create

  public func getMapFlowCoordinator(router: Router) -> OSCAMapFlowCoordinator {
    let flow = moduleDIContainer.makeMapFlowCoordinator(router: router)
    return flow
  } // end public func getMapFlowCoordinator

  // MARK: Private

  /// module DI container
  private var moduleDIContainer: OSCAMapUI.DIContainer!
} // end public func OSCAMapUI

// MARK: - Dependencies
extension OSCAMapUI {
  public struct Dependencies {
    public init(moduleConfig: OSCAMapUI.Config,
                dataModule: OSCAMap,
                analyticsModule: OSCAAnalyticsModule? = nil
    ) {
      self.moduleConfig = moduleConfig
      self.dataModule = dataModule
      self.analyticsModule = analyticsModule
    }// end public memberwise init
    public let moduleConfig: OSCAMapUI.Config
    public let dataModule: OSCAMap
    public let analyticsModule: OSCAAnalyticsModule?
  }// end public struct OSCAMas
}// end extension public struct OSCAMapUI

// MARK: - Config
public protocol OSCAMapUIConfig: OSCAUIModuleConfig {
  /// typeface configuration
  var fontConfig: OSCAFontConfig { get set }
  /// color configuration
  var colorConfig: OSCAColorConfig { get set }
  /// default location
  var defaultLocation: OSCAGeoPoint { get set }
  ///  app deeplink scheme
  var deeplinkScheme: String { get set }
} // end public protocol OSCAMapUIConfig

public extension OSCAMapUI {
  /// The configuration of the `OSCAMapUI` module
  struct Config: OSCAMapUIConfig {
    // MARK: Lifecycle
    
    public init(
      title: String?,
      externalBundle: Bundle? = nil,
      fontConfig: OSCAFontSettings,
      colorConfig: OSCAColorSettings,
      cornerRadius: Double = 10.0,
      shadow: OSCAShadowSettings = OSCAShadowSettings(
        opacity: 0.2,
        radius: 10,
        offset: CGSize(width: 0, height: 2)),
      defaultLocation: OSCAGeoPoint = OSCAGeoPoint(latitude: 51.17724517968174, longitude: 7.084675786820801),
      deeplinkScheme: String = "solingen",
      defaultLatLngMeters: (Int, Int) = (20000, 20000),
      defaultZoomRange: Double = 3000,
      maxDimmedAlpha: Float = 0.6,
      dimmingAnimationTime: Double = 0.8,
      defaultPoiCategories: OSCAPoiCategory.DefaultCategories = OSCAPoiCategory
        .DefaultCategories(list: ["sport26"]),
      loadPOIsOnStart: Bool = false
    ) {
#if DEBUG
      print("\(String(describing: Self.self)): \(#function)")
#endif
      self.title = title
      self.externalBundle = externalBundle
      self.fontConfig = fontConfig
      self.colorConfig = colorConfig
      self.cornerRadius = cornerRadius
      self.shadow = shadow
      self.deeplinkScheme = deeplinkScheme
      self.defaultLocation = defaultLocation
      self.defaultLatLngMeters = defaultLatLngMeters
      self.defaultZoomRange = defaultZoomRange
      self.maxDimmedAlpha = maxDimmedAlpha
      self.dimmingAnimationTime = dimmingAnimationTime
      self.defaultPoiCategories = defaultPoiCategories
      self.loadPOIsOnStart = loadPOIsOnStart
    } // end public memberwise init
    
    // MARK: Public
    
    /// module title
    public var title: String?
    public var externalBundle: Bundle?
    /// `UIView` corner radius
    public var cornerRadius: Double = 10.0
    /// `UIView` border thickness
    public var borderThickness: Double = 1.5
    /// `UIView` shadow
    public var shadow = OSCAShadowSettings(opacity: 0.2,
                                           radius: 10,
                                           offset: CGSize(width: 0, height: 2))
    /// typeface configuration
    public var fontConfig: OSCAFontConfig
    /// color configuration
    public var colorConfig: OSCAColorConfig
    /// placeholder for category icon
    public var placeholderIcon: UIImage?
    /// default location
    public var defaultLocation: OSCAGeoPoint
    /// default latitudinal, longitudinal meters tuple
    public var defaultLatLngMeters: (Int, Int)
    /// default zoom range
    public var defaultZoomRange: Double
    /// max alpha for dimmed views
    public var maxDimmedAlpha: Float
    /// dimming animation time
    public var dimmingAnimationTime: Double
    /// default poi categories
    public var defaultPoiCategories: OSCAPoiCategory.DefaultCategories
    /// app deeplink scheme URL part before `://`
    public var deeplinkScheme: String = "solingen"
    ///
    public var loadPOIsOnStart: Bool
  } // end public struct Config
} // end extension public struct OSCAMapUI

// MARK: - Keys
extension OSCAMapUI {
  /// Widget keys
  public enum Keys: String {
    case mapWidgetVisibility = "Map_Widget_Visibility"
    case mapWidgetPosition   = "Map_Widget_Position"
  }
}

public extension OSCAMapUI {
  
  func getMapWidgetFlowCoordinator(router: Router) -> OSCAMapWidgetFlowCoordinator {
    let flow = moduleDIContainer.makeOSCAMapWidgetFlowCoordinator(router: router)
    return flow
  } // end public func getMapFlowCoordinator
}
