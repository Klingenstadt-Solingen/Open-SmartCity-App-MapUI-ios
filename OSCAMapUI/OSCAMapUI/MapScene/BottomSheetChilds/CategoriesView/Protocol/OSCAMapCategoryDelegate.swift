//
//  OSCAMapCategoryDelegate.swift
//  OSCAMapUI
//
//  Created by Mammut Nithammer on 23.08.22.
//  Copyright © 2020 Stadt Solingen. All rights reserved.
//

import Foundation
import OSCAMap

protocol OSCAMapCategoryDelegate: AnyObject {
  func categorySheet(with pois: [OSCAPoi])
  func categorySheet(didSelect poi: OSCAPoi)
}
