//
//  OSCAMapCategoryDetailListViewModel.swift
//  OSCAMapUI
//
//  Created by Ömer Kurutay on 10.01.23.
//

import OSCAEssentials
import OSCAMap
import Foundation
import Combine

public final class OSCAMapCategoryDetailListViewModel: OSCAMapUI.ViewModel {
  // MARK: Lifecycle

  /// public initializer with `dependencies`
  /// - parameter dependecies: module's `ViewModel`base class dependencies
  public init(actions: OSCAMapCategoryDetailListViewModel.Actions,
              category: OSCAPoiCategory,
              categoryPois: [OSCAPoi],
              dependencies: OSCAMapUI.ViewModel.Dependencies) {
    self.actions = actions
    self.category = category
    self.categoryPois = categoryPois
    super.init(dependencies: dependencies)
  }

  // MARK: Internal

  var actions: OSCAMapCategoryDetailListViewModel.Actions
  let category: OSCAPoiCategory
  var categoryPois: [OSCAPoi]
  
  
  // MARK: - OUTPUT
  
  @Published private(set) var state: OSCAMapCategoryDetailListViewModel.State = .loading
  @Published private(set) var filteredPois: [OSCAPoi] = []
  
  var screenTitle: String { self.category.name ?? "" }
  
  // MARK: - Private
  
  private func search(with text: String) {
    self.filteredPois = self.categoryPois.filter { poi in
      let name = poi.name ?? ""
      let district = poi.district ?? ""
      let address = poi.address ?? ""
      
      return name.contains(text) || district.contains(text) || address.contains(text) ? true : false
    }
  }
}

extension OSCAMapCategoryDetailListViewModel {
  public func fetchCategoryPois() {
    self.state = .loading
    self.dataModule.fetchAllFilteredPois(for: self.category, with: [])
      .sink { subscription in
        switch subscription {
        case .finished:
          self.state = .finishedLoading
          
        case .failure:
          break
        }
      } receiveValue: { result in
        self.categoryPois = result
        self.filteredPois = result
      }
      .store(in: &self.bindings)
  }
}

// MARK: - Section
extension OSCAMapCategoryDetailListViewModel {
  enum Section {
    case poi
  }
}

// MARK: - Actions
public extension OSCAMapCategoryDetailListViewModel {
  struct Actions {}
}

// MARK: - INPUT: lifecycle methods
public extension OSCAMapCategoryDetailListViewModel {
  override func viewDidLoad() {
    #if DEBUG
      print("\(String(describing: self)): \(#function)")
    #endif
    super.viewDidLoad()
    self.filteredPois = self.categoryPois
  }

  override func viewWillAppear() {
    #if DEBUG
      print("\(String(describing: self)): \(#function)")
    #endif
    super.viewWillAppear()
  }
}

// MARK: - INPUT
public extension OSCAMapCategoryDetailListViewModel {
  func searchBar(didChange text: String) {
    if text.count > 3 {
      self.search(with: text)
    }
  }
}
