//
//  OSCAMapFilterCellViewModel.swift
//  OSCAMapUI
//
//  Created by Igor Dias on 13.10.22.
//  Copyright © 2020 Stadt Solingen. All rights reserved.
//


import Combine
import Foundation
import OSCAMap

final class OSCAMapFilterCellViewModel {
  // MARK: Lifecycle

  public init(
    category: OSCAPoiCategory,
    filter: OSCAPoiCategory.FilterField,
    selectedValueIndex: Int = 0,
    dataModule: OSCAMap,
    at row: Int,
    didSelectFilter: ((OSCAPoiCategory, OSCAPoiCategory.FilterField, Int) -> Void)? = nil
  ) {
    self.category = category
    self.filter = filter
    self.dataModule = dataModule
    self.didSelectFilter = didSelectFilter
    self.currentlySelectedOption = filter.values?[selectedValueIndex] ?? ""
    cellRow = row

    setupBindings()
  }

  // MARK: Internal

  var title: String = ""
  
  @Published private(set) var currentlySelectedOption: String = ""
  var category: OSCAPoiCategory
  var filter: OSCAPoiCategory.FilterField
  var didSelectFilter: ((OSCAPoiCategory, OSCAPoiCategory.FilterField, Int) -> Void)?
  
  // MARK: Private

  private let dataModule: OSCAMap
  private let cellRow: Int
  private var bindings = Set<AnyCancellable>()
  
  public func didSetViewModel(){
    setupBindings()
  }

  public func onOptionSelected(valueIndex: Int) {
    didSelectFilter?(self.category, self.filter, valueIndex)
    currentlySelectedOption = self.filter.values?[valueIndex] ?? ""
  }
  private func setupBindings() {
    title = filter.title ?? "no data"
  }

} // end final class OSCAMapCategoryCellViewModel
