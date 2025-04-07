//
//  OSCAMapCategoryDetailHeaderReusableViewModel.swift
//  OSCAMapUI
//
//  Created by Ömer Kurutay on 17.01.23.
//

import OSCAEssentials
import OSCAMap
import Foundation

public final class OSCAMapCategoryDetailHeaderReusableViewModel {
  
  let dataModel: OSCAMap
  let filterField: OSCAPoiCategory.FilterField
  
  // MARK: Initializer
  public init(dataModel: OSCAMap,
              filterField: OSCAPoiCategory.FilterField) {
    self.dataModel = dataModel
    self.filterField = filterField
  }
  
  var title: String { self.filterField.title ?? "" }
}

extension OSCAMapCategoryDetailHeaderReusableViewModel {
  func fill() {}
}
