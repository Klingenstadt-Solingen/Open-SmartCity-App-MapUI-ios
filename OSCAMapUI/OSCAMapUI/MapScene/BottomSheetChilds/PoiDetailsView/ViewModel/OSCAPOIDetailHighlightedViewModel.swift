//
//  OSCAPOIDetailHighlightedViewModel.swift
//  OSCAMapUI
//
//  Created by Mammut Nithammer on 24.08.22.
//  Copyright © 2020 Stadt Solingen. All rights reserved.
//

import Foundation
import OSCAMap

final class OSCAPOIDetailHighlightedViewModel {
  // MARK: Lifecycle

  init(detail: OSCAPoiDetailGroup) {
    self.detail = detail
  } // end init

  // MARK: Internal

  var detail: OSCAPoiDetailGroup
}
