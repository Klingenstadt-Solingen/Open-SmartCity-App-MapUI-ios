//
//  OSCAMapCategoryDetailViewModel.swift
//  OSCAMapUI
//
//  Created by Ömer Kurutay on 09.01.23.
//

import OSCAEssentials
import OSCAMap
import Foundation
import Combine

public final class OSCAMapCategoryDetailViewModel: OSCAMapUI.ViewModel {
  // MARK: Lifecycle
  
  /// public initializer with `dependencies`
  /// - parameter dependecies: module's `ViewModel`base class dependencies
  public init(actions: OSCAMapCategoryDetailViewModel.Actions,
              category: OSCAPoiCategory,
              dependencies: OSCAMapUI.ViewModel.Dependencies) {
    self.actions = actions
    self.category = category
    super.init(dependencies: dependencies)
  }
  
  // MARK: Internal
  
  var actions: OSCAMapCategoryDetailViewModel.Actions
  let category: OSCAPoiCategory
  
  
  // MARK: - OUTPUT
  
  /// categories view model state
  @Published private(set) var state: OSCAMapCategoryDetailViewModel.State = .loading
  @Published private(set) var filterFields: [OSCAPoiCategory.FilterField] = []
  @Published private(set) var filteredPois: [OSCAPoi] = []
  @Published private(set) var selectedFilters: [OSCAPoi.Detail.FilterField] = []
  
  var screenTitle: String {
    guard let name = self.category.name
    else { return "Kategorie filtern" }
    return "\(name) filtern"
  }
  
  // MARK: - Private
  
  private func applyFilters(with indexPaths: [IndexPath]) {
    var filterFields: [OSCAPoi.Detail.FilterField] = []
    
    indexPaths.forEach { indexPath in
      let filter = self.filterFields[indexPath.section]
      if let value = filter.values?[indexPath.row],
         let field = filter.field {
        let filterField = OSCAPoi.Detail.FilterField.with(field: field, value: value)
        filterFields.append(filterField)
      }
    }
    
    self.selectedFilters = filterFields
    self.fetchCategoryPois(with: self.selectedFilters)
  }
}

// MARK: - Section
public extension OSCAMapCategoryDetailViewModel {
  enum Section: Hashable {
    case filterField(String)
  }
}

// MARK: - Error
public extension OSCAMapCategoryDetailViewModel {
  enum Error {
    case poiFetch
    case poiCategoryFetch
    case filterFieldFetch
  }
}

// MARK: - OSCAMapCategoryDetailViewModel.Error + Swift.Error
extension OSCAMapCategoryDetailViewModel.Error: Swift.Error {}

// MARK: - OSCAMapCategoryDetailViewModel.Error + Equatable
extension OSCAMapCategoryDetailViewModel.Error: Equatable {}

// MARK: - OSCAMapCategoryDetailViewModel.Error + CustomStringConvertible
extension OSCAMapCategoryDetailViewModel.Error: CustomStringConvertible {
  public var description: String {
    switch self {
    case .poiFetch:
      return "There is a problem with fetching the POI"
    case .poiCategoryFetch:
      return "There is a problem with fetching the POI categories"
    case .filterFieldFetch:
      return "There is a problem with fetching the POI filter fields"
    }
  }
}

// MARK: - States
public extension OSCAMapCategoryDetailViewModel {
  enum State {
    case loading
    case finishedLoading
    case error(OSCAMapCategoryDetailViewModel.Error)
  }
}

// MARK: - Actions
public extension OSCAMapCategoryDetailViewModel {
  struct Actions {
    let showCategoryDetailList: (OSCAPoiCategory, [OSCAPoi]) -> Void
  }
}

// MARK: - Data access
public extension OSCAMapCategoryDetailViewModel {
  func fetchCategoryPois() {
    self.state = .loading
    self.dataModule.fetchAllFilteredPois(for: self.category, with: [])
      .sink { subscription in
        switch subscription {
        case .finished:
          self.state = .finishedLoading
          
        case .failure:
          self.state = .error(.filterFieldFetch)
        }
      } receiveValue: { result in
        self.filteredPois = result
      }
      .store(in: &self.bindings)
  }
  
  func fetchCategoryPois(with filterFields: [OSCAPoi.Detail.FilterField]) {
    self.state = .loading
    
    self.dataModule.fetchAllFilteredPois(for: self.category, with: filterFields)
      .sink { subscription in
        switch subscription {
        case .finished:
          self.state = .finishedLoading
          
        case .failure:
          self.state = .error(.filterFieldFetch)
        }
      } receiveValue: { result in
        self.filteredPois = result
      }
      .store(in: &self.bindings)
  }
  
  func fetchCategoryPoisForSelectedFilters() {
    fetchCategoryPois(with: self.selectedFilters)
  }
  
  /// fetch all `OSCAPoiCategory.FilterField` items asynchronously
  func fetchAllFilterFields() {
    self.state = .loading
    
    self.dataModule
      .fetchAllFilterFields(for: self.category)
      .sink { completion in
        switch completion {
        case .finished:
          self.state = .finishedLoading
          
        case .failure:
          self.state = .error(.filterFieldFetch)
        }
      } receiveValue: { filterFieldsFromNetwork in
        self.filterFields = filterFieldsFromNetwork
      }
      .store(in: &self.bindings)
  }
}

// MARK: - INPUT: lifecycle methods
public extension OSCAMapCategoryDetailViewModel {
  override func viewDidLoad() {
    #if DEBUG
      print("\(String(describing: self)): \(#function)")
    #endif
    super.viewDidLoad()
    self.fetchCategoryPois()
    self.fetchAllFilterFields()
  }

  override func viewWillAppear() {
    #if DEBUG
      print("\(String(describing: self)): \(#function)")
    #endif
    super.viewWillAppear()
  }
}

// MARK: INPUT
public extension OSCAMapCategoryDetailViewModel {
  func fullListButtonTouch() {
    self.actions.showCategoryDetailList(self.category, self.filteredPois)
  }
  
  func didSelectFilters(at indexPaths: [IndexPath]) {
    self.applyFilters(with: indexPaths)
  }
}

// MARK: Localized Strings
extension OSCAMapCategoryDetailViewModel {
  var emptyFilterMessage: String { NSLocalizedString(
    "map_category_detail_empty_message",
    bundle: OSCAMapUI.bundle,
    comment: "The message to show when poi category filters are empty") }
}
