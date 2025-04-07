//
//  OSCAMapCategoryDetailCellViewModel.swift
//  OSCAMapUI
//
//  Created by Ömer Kurutay on 13.01.23.
//

import OSCAEssentials
import OSCAMap
import Foundation

public final class OSCAMapCategoryDetailCellViewModel {
  
  let dataModel: OSCAMap
  let filterField: OSCAPoi.Detail.FilterField
  
  // MARK: Initializer
  public init(dataModel: OSCAMap,
              filterField: OSCAPoi.Detail.FilterField) {
    self.dataModel = dataModel
    self.filterField = filterField
  }
  
  var filterName: String { self.filterField.value ?? "" }
}

extension OSCAMapCategoryDetailCellViewModel {
  func fill() {}
}
