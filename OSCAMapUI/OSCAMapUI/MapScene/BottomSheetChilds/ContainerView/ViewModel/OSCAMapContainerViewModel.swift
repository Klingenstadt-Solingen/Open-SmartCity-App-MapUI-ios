//
//  OSCAMapContainerViewModel.swift
//  OSCAMapUI
//
//  Created by Ömer Kurutay on 05.01.23.
//

import Foundation

public final class OSCAMapContainerViewModel: OSCAMapUI.ViewModel {
  // MARK: Lifecycle
  
  /// public initializer with `dependencies`
  /// - parameter dependecies: module's `ViewModel`base class dependencies
  public init(
    actions: OSCAMapContainerViewModel.Actions,
    dependencies: OSCAMapUI.ViewModel.Dependencies
  ) {
    self.actions = actions
    super.init(dependencies: dependencies)
  }
  
  var actions: OSCAMapContainerViewModel.Actions
}

// MARK: - Actions
public extension OSCAMapContainerViewModel {
  struct Actions {}
}
