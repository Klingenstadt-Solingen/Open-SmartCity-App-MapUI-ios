//
//  MapDI+DeeplinkHandler.swift
//  OSCAMapUI
//
//  Created by Stephan Breidenbach on 08.09.22.
//  Copyright © 2020 Stadt Solingen. All rights reserved.
//

import Foundation
extension OSCAMapUI.DIContainer {
  var deeplinkScheme: String {
    return self
      .dependencies
      .moduleConfig
      .deeplinkScheme
  }// end var deeplinkScheme
}// end extension final class OSCAMapUI.DIContainer
