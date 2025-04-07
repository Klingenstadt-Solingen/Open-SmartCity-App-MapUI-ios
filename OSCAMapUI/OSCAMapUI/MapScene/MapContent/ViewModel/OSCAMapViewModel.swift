//
//  OSCAMapViewModel.swift
//  OSCAMapUI
//
//  Created by Mammut Nithammer on 24.06.22.
//  Reviewed by Stephan Breidenbach on 15.08.22
//  Copyright © 2020 Stadt Solingen. All rights reserved.
//

import Combine
import Foundation
import OSCAEssentials
import OSCAMap
import OSCANetworkService


// MARK: - OSCAMapViewModel
public final class OSCAMapViewModel: OSCAMapUI.ViewModel {
  /// public initializer with `dependencies`
  /// - parameter dependecies: module's `ViewModel`base class dependencies
  /// - parameter actions: closures from flow coordinator
  public init(
    actions: OSCAMapViewModel.Actions,
    dependencies: OSCAMapUI.ViewModel.Dependencies
  ) {
    self.actions = actions
    super.init(dependencies: dependencies)
  } // end public overriding
  
  // MARK: Internal
  var actions: OSCAMapViewModel.Actions
  // MARK: Private
  private var selectedItemId: String?
  private var selectedItem: OSCAPoi?
  private var center: String?
  private var span: String?
  private var deeplink: String?
  
  // MARK: OUTPUT
  /// map view model state
  @Published private(set) var state: OSCAMapViewModel.State = .loading
  /// list of `OSCAPoi` items
  @Published private(set) var pois: [OSCAPoi] = []
  
  @Published private(set) var selectedPoi: OSCAPoi? {
    didSet {
      /// selected item consumed
      selectedItem = nil
    }// end didSet
  }// end selectedPoi
  
  let imageDataCache = NSCache<NSString, NSData>()
  
} // end public class OSCAMapViewModel

// MARK: - INPUT
extension OSCAMapViewModel {} // end extension public class OSCAMapViewModel

// MARK: - Error
public extension OSCAMapViewModel {
  enum Error {
    case poisFetch
  } // end public enum
} // end extension public class OSCAMapViewModel

// MARK: - OSCAMapViewModel.Error + Swift.Error
extension OSCAMapViewModel.Error: Swift.Error {}

// MARK: - OSCAMapViewModel.Error + Equatable
extension OSCAMapViewModel.Error: Equatable {}

// MARK: - OSCAMapViewModel.Error + CustomStringConvertible
extension OSCAMapViewModel.Error: CustomStringConvertible {
  public var description: String {
    switch self {
    case .poisFetch:
      return "there is a problem by fetching the POIs"
    } // end switch case
  } // end public var description
} // end extension public enum CategoriesViewModel.Error

// MARK: - Actions
public extension OSCAMapViewModel {
  struct Actions {
    // MARK: Lifecycle
    
    public init(
      showDefaultCategories: @escaping (_ deeplink: String?) -> Void,
      showDetails: @escaping (OSCAPoi) -> Void
    ) {
      self.showDefaultCategories = showDefaultCategories
      self.showDetails = showDetails
    } // end public memberwise init
    
    // MARK: Public
    
    public let showDefaultCategories: (_ deeplink: String?) -> Void
    public let showDetails: (OSCAPoi) -> Void
  } // end public struct Actions
} // end extension public class OSCAMapViewModel

// MARK: - States
public extension OSCAMapViewModel {
  enum State {
    case loading
    case finishedLoading
    case error(OSCAMapViewModel.Error)
  } // end public enum State
} // end extension public class OSCAMapViewModel

// MARK: - OSCAMapViewModel.State + Equatable
extension OSCAMapViewModel.State: Equatable {}

// MARK: - data access
extension OSCAMapViewModel {
  /// subscribe asynchronously to map publisher
  /// - parameter to publisher: endpoint publisher function from `OSCAMap` data module
  private func subscribe(to publisher: OSCAMap.OSCAMapPublisher) {
    // transition view model state to .loading
    if state != .loading {
      state = .loading
    } // end if
    var sub: AnyCancellable?
    sub = publisher
      .receive(on: RunLoop.main)
      .sink { [weak self] completion in
        guard let self = self
        else { return }
        self.bindings.remove(sub!)
        switch completion {
        case .finished:
          self.state = .finishedLoading
        case .failure:
          self.state = .error(.poisFetch)
        } // end switch case
      } receiveValue: { pois in
        self.pois = pois
        self.selectItem(with: self.selectedItemId)
      } // end receiveValue closure
    guard let sub = sub else { return }
    bindings.insert(sub)
  } // end private func subscribe to publisher
  
  /// fetch all POIs
  func fetchAllPOIs() {
    state = .finishedLoading
    //      subscribe(to: dataModule.fetchAllCachedPois())
  } // end func fetchAllPOIs
  
  func fetchPOI(with objectId: String) -> Void {
    guard !objectId.isEmpty else { return }
    let query = ["where":"{\"objectId\":\"\(objectId)\"}"]
    let poiPublisher: OSCAMap.OSCAMapPublisher = dataModule
      .fetchAllPOIs(maxCount: 1,
                    query: query)
    var sub: AnyCancellable?
    sub = poiPublisher
      .receive(on: RunLoop.main)
      .sink { [weak self] completion in
        guard let self = self
        else { return }
        self.bindings.remove(sub!)
        switch completion {
        case .finished:
          self.state = .finishedLoading
        case .failure:
          self.state = .error(.poisFetch)
        } // end switch case
      } receiveValue: { pois in
        self.selectedItem = pois.first
        self.selectItem(with: self.selectedItemId)
      } // end receiveValue closure
    guard let sub = sub else { return }
    bindings.insert(sub)
  }// end func fetchPOI with object id
  
  func fetchPOICategory(with sourceId: String) -> Void {
    guard !sourceId.isEmpty else { return }
#warning("there are two unique identifiers in parse class 'POICategory'")
    let query = ["where":"{\"sourceId\":\"\(sourceId)\"}"]
    let publisher = dataModule
      .fetchAllPOICategories(maxCount: 1,
                             query: query)
    // transition view model state to .loading
    if state != .loading {
      state = .loading
    } // end if
    var sub: AnyCancellable?
    sub = publisher
      .receive(on: RunLoop.main)
      .sink { [weak self] completion in
        guard let self = self
        else { return }
        self.bindings.remove(sub!)
        switch completion {
        case .finished:
          self.state = .finishedLoading
        case .failure:
          self.state = .error(.poisFetch)
        } // end switch case
      } receiveValue: { categories in
        guard self.selectedItem != nil else { return }
        
        self.selectedItem!.poiCategoryObject = categories.first
      } // end receiveValue closure
    guard let sub = sub else { return }
    bindings.insert(sub)
  }// end func fetchPOI with object id
  
  /// elastic search
  /// - parameters for query: query string
  func elasticSearch(for query: String) {
    subscribe(to: dataModule.elasticSearch(for: query))
  } // end func elasticSearch for query
  
  /// filter for category with filter fields
  /// - parameter for category: `OSCAPoiCategory`
  /// - parameter with filterFields: list of filter fields
  func fetchAllFilteredPois(
    for category: OSCAPoiCategory,
    with filterFields: [OSCAPoi.Detail.FilterField]
  ) {
    let mapPublisher: OSCAMap.OSCAMapPublisher = dataModule.fetchAllFilteredPois(
      for: category,
      with: filterFields
    )
    
    subscribe(to: mapPublisher)
  } // end func fetchAllFilteredPois for category with filter list
  
  func setSelectedPOI(_ poi: OSCAPoi) {
    pois = [poi]
    selectedPoi = poi
    showDetails(of: poi)
  }
  
  func setPois(_ pois: [OSCAPoi]) {
    self.pois = pois
  }
  
  func getImageData(from urlString: String) -> AnyPublisher<Data, OSCAMapError>? {
    guard let url = URL(string: urlString) else { return nil }
    
    let pubisher: AnyPublisher<Data, OSCAMapError> = dataModule.fetchImageData(url: url)
    return pubisher
  }
  
  func getImageDataFromCache(with urlString: String) -> Data? {
    let imageData = imageDataCache.object(forKey: NSString(string: urlString))
    return imageData as Data?
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
} // end extension public class OSCAMapViewModel

// MARK: - INPUT: view controller lifecycle methods
public extension OSCAMapViewModel {
  override func viewDidLoad() {
#if DEBUG
    print("\(String(describing: self)): \(#function)")
#endif
    super.viewDidLoad()
    actions.showDefaultCategories(self.deeplink)
    fetchAllPOIs()
  } // end public override func viewDidLoad
} // end extension public class OSCAMapViewModel

// MARK: - INPUT: view controller methods
public extension OSCAMapViewModel {
  func elasticSearch(string: String) {
    elasticSearch(for: string)
  } // end public func elasticSearch string
  
  func showDetails(of poi: OSCAPoi) {
    actions.showDetails(poi)
  } // end func showDetails of poi
} // end extension public class OSCAMapViewModel

// MARK: - OUTPUT: localized strings
extension OSCAMapViewModel {} // end extension public class OSCAMapViewModel

// MARK: - OUTPUT:
extension OSCAMapViewModel {
  var initialCoordinates: OSCAGeoPoint {
    return uiModuleConfig.defaultLocation
  }// end var initialCoordinates
  
  var initialRegionSpan: (latSpan: Double, lonSpan: Double) {
    let defaultSpan = uiModuleConfig.defaultLatLngMeters
    return (latSpan: Double(defaultSpan.0), lonSpan: Double(defaultSpan.1))
  }// end var initialRegionSpan
  
  var centerCoordinates: OSCAGeoPoint? {
    if let centerString = self.center,
       let geopoint = OSCAGeoPoint(centerString) {
      /// center consumed
      center = nil
      return geopoint
    } else {
      return nil
    }
  }// end var centerCoordinates
  
  var regionSpan: Double? {
    if let spanString = self.span,
       let spanInt = Double(spanString) {
      /// span consumed
      span = nil
      return spanInt
    } else {
      return nil
    }
  }// end regionSpan
}// end extension public class OSCAMapViewModel

// MARK: - Section
extension OSCAMapViewModel {
  enum Section {
    case poi
  } // end enum Section
} // end extension public class OSCAMapViewModel

// MARK: - Deeplinking
extension OSCAMapViewModel {
  
  private func selectItem(with objectId: String?) -> Void {
    guard let objectId = objectId
    else { return }
    var poi: OSCAPoi?
    if let item = self.pois.first(where: { $0.objectId == objectId}) {
      poi = item
    } else if let item = self.selectedItem {
      poi = item
    }// end if
    if let poi = poi {
      // selected item id consumed
      selectedItemId = nil
      if poi.poiCategory != nil {
        selectedItem = poi
        self.setSelectedPOI(poi)
      }// end if
    } else {
      fetchPOI(with: objectId)
      selectedItemId = objectId
    }// end if
  }// end private func selectItem
  
  func didReceiveDeeplinkDetail(with objectId: String,
                                center: String? = nil,
                                span: String? = nil) -> Void {
    guard !objectId.isEmpty else { return }
    self.selectedItemId = objectId
    self.span = span
    self.center = center
    self.selectItem(with: objectId)
  }// end func didReceiveDeeplinkDetail with objectId, center, span
  
  func didReceiveDeeplink(with objectId: String?) -> Void {
    self.deeplink = objectId
  }
}// end extension public class OSCAMapViewModel
