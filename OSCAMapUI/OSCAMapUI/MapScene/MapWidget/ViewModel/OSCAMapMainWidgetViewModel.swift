//
//  OSCAMapMainWidgetViewModel.swift
//  OSCAMapUI
//
//  Created by Igor Dias on 08.05.23.
//

import OSCAEssentials
import OSCAMap
import Foundation
import Combine
import CoreLocation

public final class OSCAMapMainWidgetViewModel {
  
  let dataModule  : OSCAMap
  let moduleConfig: OSCAMapUIConfig
  let fontConfig  : OSCAFontConfig
  let colorConfig : OSCAColorConfig
  let imageDataCache = NSCache<NSString, NSData>()
  
  private let actions: Actions
  private var bindings = Set<AnyCancellable>()
  
  // MARK: Initializer
  public init(dependencies: Dependencies) {
    self.actions      = dependencies.actions
    self.dataModule   = dependencies.dataModule
    self.moduleConfig = dependencies.moduleConfig
    self.fontConfig   = dependencies.moduleConfig.fontConfig
    self.colorConfig  = dependencies.moduleConfig.colorConfig
  }
  
  // MARK: - OUTPUT
  
  @Published private(set) var pois: [OSCAPoi] = []
  @Published private(set) var state: State = .loading
  
  /**
   Use this to get access to the __Bundle__ delivered from this module's configuration parameter __externalBundle__.
   - Returns: The __Bundle__ given to this module's configuration parameter __externalBundle__. If __externalBundle__ is __nil__, The module's own __Bundle__ is returned instead.
   */
  var bundle: Bundle = {
    if let bundle = OSCAMapUI.configuration.externalBundle {
      return bundle
    }
    else { return OSCAMapUI.bundle }
  }()
  
  func fetchPOIs() {
#if DEBUG
    print("\(String(describing: self)): \(#function)")
#endif
    var publisher: OSCAMap.OSCAMapPublisher
    let locationManager = CLLocationManager()
    
    if let location = OSCAGeoPoint(clLocation: locationManager.location) {
      publisher = dataModule.fetchNearbyPois(geoPoint: location,
                                            distance: 1000,
                                            random: true,
                                            limit: 10)
    } else {
      publisher = dataModule.fetchNearbyPois(geoPoint: self.dataModule.defaultGeoPoint,
                                            distance: 1000,
                                            random: true,
                                            limit: 10)
    }
    publisher
      .sink { subscribers in
        switch subscribers {
        case .finished:
          self.state = .finishedLoading
        case .failure:
          self.state = .error(.poisFetch)
        }
      } receiveValue: { pois in
        self.pois = pois
      }
      .store(in: &bindings)
  }
  
  func showMapTouch() {
    actions.showMapScene()
  }
  
  func getImageDataFromCache(with urlString: String) -> Data? {
#if DEBUG
    print("\(String(describing: self)): \(#function)")
#endif
    let imageData = imageDataCache.object(forKey: NSString(string: urlString))
    return imageData as Data?
  }
  
  func getImageData(from urlString: String) -> AnyPublisher<Data, OSCAMapError>? {
    guard let url = URL(string: urlString) else { return nil }
    
    let pubisher: AnyPublisher<Data, OSCAMapError> = dataModule.fetchImageData(url: url)
    return pubisher
  }
  
  func getIconUrl(for poi: OSCAPoi) -> String {
      if let defaultThematicView = poi.poiCategoryObject?.defaultThematicView {
        print("found defaultThematicView: \(defaultThematicView)")
        if let detail = poi.details?.first(where: { $0?.filterField == defaultThematicView }) {
          print("found detail for defaultThematicView: \(detail?.title ?? "")")
          if var path = detail?.symbolPath, let symbolName = detail?.symbolName, let mimeType = detail?.symbolMimetype {
            if path.last == "/" {
              path.removeLast()
            }
            print("path to image: \(path)/\(symbolName)\(mimeType)")
            return "\(path)/\(symbolName)\(mimeType)"
          }
        }
      }
      
      guard var path = poi.poiCategoryObject?.symbolPath,
            let symbolName = poi.poiCategoryObject?.symbolName,
            let mimeType = poi.poiCategoryObject?.symbolMimetype
      else { return "" }
      
      if path.last == "/" {
        path.removeLast()
      }
      
      print("path to image: \(path)/\(symbolName)\(mimeType)")
      return "\(path)/\(symbolName)\(mimeType)"
    }
}

extension OSCAMapMainWidgetViewModel {
  public struct Dependencies {
    var actions     : Actions
    var dataModule  : OSCAMap
    var moduleConfig: OSCAMapUIConfig
  }
}

extension OSCAMapMainWidgetViewModel {
  public struct Actions {
    let showMapScene: () -> Void
    let showMapSceneWithURL: (URL) -> Void
  }
}

extension OSCAMapMainWidgetViewModel {
  public enum Error: Swift.Error, Equatable {
    case poisFetch
  }
}

extension OSCAMapMainWidgetViewModel {
  public enum State: Equatable {
    case loading
    case finishedLoading
    case error(OSCAMapMainWidgetViewModel.Error)
  }
}

extension OSCAMapMainWidgetViewModel {
  /// Module Navigation view lifecycle method
  func viewDidLoad() {
    self.fetchPOIs()
  }
  
  func refreshContent() {
    self.fetchPOIs()
  }
}

// MARK: - Localized Strings
extension OSCAMapMainWidgetViewModel {
  var widgetTitle: String { NSLocalizedString(
    "map_widget_title",
    bundle: self.bundle,
    comment: "The widget title") }
}
