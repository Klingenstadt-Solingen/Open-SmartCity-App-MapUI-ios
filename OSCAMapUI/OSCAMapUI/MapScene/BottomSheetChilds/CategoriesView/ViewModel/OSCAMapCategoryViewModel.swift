//
//  OSCAMapCategoryViewModel.swift
//  OSCAMapUI
//
//  Created by Mammut Nithammer on 24.06.22.
//  Reviewed by Stephan Breidenbach on 14.08.22
//  Copyright © 2020 Stadt Solingen. All rights reserved.
//

import Combine
import Foundation
import OSCAEssentials
import OSCAMap

// MARK: - OSCAMapCategoryViewModel

public final class OSCAMapCategoryViewModel: OSCAMapUI.ViewModel {
  // MARK: Lifecycle

  /// public initializer with `dependencies`
  /// - parameter dependecies: module's `ViewModel`base class dependencies
  public init(
    actions: OSCAMapCategoryViewModel.Actions,
    dependencies: OSCAMapUI.ViewModel.Dependencies
  ) {
    self.actions = actions
    super.init(dependencies: dependencies)
  } // end public init

  // MARK: Internal

  var actions: OSCAMapCategoryViewModel.Actions

  // MARK: - OUTPUT poi categories

  /// categories view model state
  @Published private(set) var state: OSCAMapCategoryViewModel.State = .loading
  /// list of `OSCAPoiCategory` items
  @Published private(set) var categories: [OSCAPoiCategory] = []
  @Published private(set) var selectedCategory: OSCAPoiCategory?
  @Published private(set) var isSearching: Bool = false
  @Published private(set) var filteredPois: [OSCAPoi] = []
  
  private var pois: [OSCAPoi] = []
  private var deeplink: String? = nil
} // public class end OSCAMapCategoryViewModel

// MARK: - Error

public extension OSCAMapCategoryViewModel {
  func getFilterValueIndex(of value: String, in filter: OSCAPoiCategory.FilterField) -> Int? {
    return filter.values?.firstIndex(of: value)
  }
}

public extension OSCAMapCategoryViewModel {
  enum Error {
    case poiCategoryFetch
    case filterFieldFetch
  } // end public enum OSCAMapCategoryViewModel.Error
} // end extension public final class OSCAMapCategoryViewModel

// MARK: - OSCAMapCategoryViewModel.Error + Swift.Error

extension OSCAMapCategoryViewModel.Error: Swift.Error {}

// MARK: - OSCAMapCategoryViewModel.Error + Equatable

extension OSCAMapCategoryViewModel.Error: Equatable {}

// MARK: - OSCAMapCategoryViewModel.Error + CustomStringConvertible

extension OSCAMapCategoryViewModel.Error: CustomStringConvertible {
  public var description: String {
    switch self {
    case .poiCategoryFetch:
      return "There is a problem with fetching the POI categories"
    case .filterFieldFetch:
      return "There is a problem with fetching the POI filter fields"
    } // end switch case
  } // end public var description
} // end extension public enum OSCAMapCategoryViewModel.Error

// MARK: - Actions

public extension OSCAMapCategoryViewModel {
  struct Actions {
    let showCategoryDetail: (OSCAPoiCategory) -> Void
  } // end public struct Actions
} // end extension public final class OSCAMapCategoryViewModel

// MARK: - States

public extension OSCAMapCategoryViewModel {
  enum State {
    case loading
    case finishedLoading
    case error(OSCAMapCategoryViewModel.Error)
  } // end public enum State
} // end extension public final class OSCAMapCategoryViewModel

// MARK: - OSCAMapCategoryViewModel.State + Equatable

extension OSCAMapCategoryViewModel.State: Equatable {}

// MARK: - Data access

extension OSCAMapCategoryViewModel {
  private func fetchAllPOIs() {
#if DEBUG
    print("\(String(describing: self)): \(#function)")
#endif
    self.dataModule.fetchAllCachedPois()
      .sink { subscribers in
        switch subscribers {
        case .finished:
#if DEBUG
          print("\(String(describing: self)): \(#function) .finished " +
                "with poi count: \(self.pois.count)")
#endif
          
        case let .failure(error):
#if DEBUG
          print("\(String(describing: self)): \(#function) .failure " +
                "with error: \(error.description)")
#endif
        }
        
      } receiveValue: { fetchedPOIs in
        self.pois = fetchedPOIs
        
        self.filteredPois = fetchedPOIs
      }
      .store(in: &self.bindings)
  }
  
  /// subscribe asynchronously to map category publisher
  /// - parameter to publisher: endpoint publisher function from `OSCAMap` data module
  private func subscribe(to publisher: OSCAMap.OSCAMapCategoryPublisher) {
    if state != .loading {
      state = .loading
    } // end if
    var sub: AnyCancellable?
    sub = publisher
      .sink { [weak self] completion in
        guard let self = self
        else { return }
        self.bindings.remove(sub!)
        switch completion {
        case .finished:
          break
        case .failure:
          self.state = .error(OSCAMapCategoryViewModel.Error.poiCategoryFetch)
        } // end switch case
      } receiveValue: { [weak self] result in
        guard let self = self
        else { return }
        self.categories = result
        if self.deeplink != nil {
          DispatchQueue.main.sync {
            self.selectCategory(from: result)
          }
        }
      } // end receiveValue scope
    bindings.insert(sub!)
  } // end private func subscribe to publisher

  /// fetch all `OSCAPoiCategory` items asynchronously
  func fetchAllCategories() {
    subscribe(to: dataModule.fetchAllPOICategories(
      query: [
        "order": "position",
        "where": "{\"showCategory\": \"true\"}"
      ]))
  } // end func fetchAllCategories
  

  /// fetch default `OSCAPoiCategory` items asynchronously
  func fetchDefaultCategories(_ defaultCategories: OSCAPoiCategory.DefaultCategories? = nil) {
    if let defaultCategories = defaultCategories {
      subscribe(to: dataModule.fetchDefaultCategories(defaultCategories))
    } else {
      subscribe(to: dataModule.fetchDefaultCategories())
    } // end if
  } // end func fetchDefaultCategories

  func search(string: String) {
    let publisher: AnyPublisher<[OSCAPoi], OSCAMapError> = dataModule.elasticSearch(for: string)
    publisher
      .sink { [weak self] subscription in
        guard let self = self else { return }
        switch subscription {
        case .finished:
          self.isSearching = true
        case .failure:
          self.isSearching = false
          self.state = .error(OSCAMapCategoryViewModel.Error.poiCategoryFetch)
        }
      } receiveValue: { [weak self] result in
        guard let self = self else { return }
        self.filteredPois = result
      }
      .store(in: &self.bindings)
  }

  func endSearching() {
    self.isSearching = false
    self.filteredPois = self.pois
  }
} // end extension public final class OSCAMapCategoryViewModel

// MARK: - INPUT: lifecycle methods

public extension OSCAMapCategoryViewModel {
  override func viewDidLoad() {
    #if DEBUG
      print("\(String(describing: self)): \(#function)")
    #endif
    super.viewDidLoad()
    if self.dependencies.uiModuleConf.loadPOIsOnStart {
      self.fetchAllPOIs()
    }
    self.fetchAllCategories()
  } // end public override func viewDidLoad

  override func viewDidLayoutSubviews() {
    #if DEBUG
      print("\(String(describing: self)): \(#function)")
    #endif
    super.viewDidLayoutSubviews()
  } // end public override func viewDidLoad
} // end extension public final class OSCAMapCategoryViewModel

// MARK: - INPUT

public extension OSCAMapCategoryViewModel {
  func showDefaultCategories() {
    fetchDefaultCategories()
  } // end public func showDefaultCategories
  
  func didSelectItem(at index: Int) {
    self.actions.showCategoryDetail(self.categories[index])
  }
} // end extension public final class OSCAMapCategoryViewModel

// MARK: - OUTPUT: localized strings
extension OSCAMapCategoryViewModel {
  var searchPlaceholder: String {
    return NSLocalizedString(
      "searchbar_placeholder",
      bundle: OSCAMapUI.bundle,
      comment: "Placeholder for searchbar")
  }
} // end extension public final class OSCAMapCategoryViewModel

// MARK: - Section

extension OSCAMapCategoryViewModel {
  enum Section {
    case category
    case filterField
    case poi
  } // end enum Section
} // end extension public final class OSCAMapCategoryViewModel

// MARK: - Deeplinking
extension OSCAMapCategoryViewModel {
  func didReceiveDeeplink(with objectId: String?) -> Void {
    self.deeplink = objectId
    
    if !self.categories.isEmpty {
      self.selectCategory(from: self.categories)
    }
  }
  
  func selectCategory(from categories: [OSCAPoiCategory]) -> Void {
    let category = categories.first { category in
      category.objectId == self.deeplink || category.sourceId == self.deeplink
    }
    
    if let category = category {
      self.actions.showCategoryDetail(category)
    }
    
    self.deeplink = nil
  }
}
