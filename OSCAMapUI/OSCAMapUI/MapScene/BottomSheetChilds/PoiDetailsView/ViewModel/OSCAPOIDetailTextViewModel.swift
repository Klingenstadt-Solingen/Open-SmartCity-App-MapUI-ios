//
//  OSCAPOIDetailTextCellViewModel.swift
//  OSCAMapUI
//
//  Created by Mammut Nithammer on 25.06.22.
//  Reviewed by Stephan Breidenbach on 15.08.22
//  Copyright © 2020 Stadt Solingen. All rights reserved.
//

import Foundation
import OSCAMap

final class OSCAPOIDetailTextCellViewModel {
  // MARK: Lifecycle

  init(detail: OSCAPoiDetailGroup) {
    self.detail = detail
  } // end init

  // MARK: Internal

  var detail: OSCAPoiDetailGroup
}
