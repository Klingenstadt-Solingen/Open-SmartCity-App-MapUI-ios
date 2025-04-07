//
//  OSCAMapUI+DIContainer.swift
//  OSCAMapUI
//
//  Created by Stephan Breidenbach on 01.03.22.
//  Reviewed by Stephan Breidenbach on 11.08.22
//  Copyright © 2020 Stadt Solingen. All rights reserved.
//

import OSCAEssentials
import OSCAMap
import UIKit

extension OSCAMapUI {
  final class DIContainer {
    // MARK: Lifecycle

    public init(dependencies: OSCAMapUI.Dependencies) {
      #if DEBUG
        print("\(String(describing: Self.self)): \(#function)")
      #endif
      // init ui module dependencies
      self.dependencies = dependencies
    } // end public init

    // MARK: Internal

    // MARK: - Flow coordinators

    func makeMapFlowCoordinator(router: Router) -> OSCAMapFlowCoordinator {
      OSCAMapFlowCoordinator(router: router, dependencies: self)
    } // end func makeMapFlowCoordinator

    // MARK: Private

    let dependencies: OSCAMapUI.Dependencies
    private var mainViewModel: OSCAMapViewModel!
  } // end final class DIContainer
} // end final class OSCAMapUI

// MARK: - OSCAMap module

extension OSCAMapUI.DIContainer {
  func makeOSCAMapModule() -> OSCAMap {
    dependencies.dataModule
  } // end func makeOSCAEventsModule

  func makeMapUIConfig() -> OSCAMapUI.Config {
    OSCAMapUI.configuration
  } // end makeMapUIConfig

  func makeMapUIColorConfig() -> OSCAColorSettings {
    guard let colorSettings = OSCAMapUI.configuration.colorConfig as? OSCAColorSettings
    else { return OSCAColorSettings() }
    return colorSettings
  } // end func makeMapUIColorConfig

  func makeMapUIFontConfig() -> OSCAFontSettings {
    guard let fontSettings = OSCAMapUI.configuration.fontConfig as? OSCAFontSettings
    else { return OSCAFontSettings() }
    return fontSettings
  } // end func makeMapUIFontConfig
} // end extension final class OSCAMapUI.DIContainer

// MARK: - OSCAMapUI.ViewModel

extension OSCAMapUI.DIContainer {
  func makeOSCAMapUIViewModelDependencies() -> OSCAMapUI.ViewModel.Dependencies {
    let dataModule = makeOSCAMapModule()
    let uiModuleConfig = makeMapUIConfig()
    let colorConfig = makeMapUIColorConfig()
    let fontConfig = makeMapUIFontConfig()
    return OSCAMapUI.ViewModel.Dependencies(
      dataModule: dataModule,
      uiModuleConfig: uiModuleConfig,
      colorConfig: colorConfig,
      fontConfig: fontConfig
    )
  } // end func makeOSCAMapUIViewModelDependencies
} // end extension final class OSCAMapUI.DIContainer

// MARK: - OSCAMapUI.DIContainer + OSCAMapFlowCoordinatorDependencies

extension OSCAMapUI.DIContainer: OSCAMapFlowCoordinatorDependencies {
  /// make map detail view model
  func makePoiDetailsViewModel(
    actions: OSCAPOIDetailViewModel.Actions,
    poi: OSCAPoi
  ) -> OSCAPOIDetailViewModel {
    OSCAPOIDetailViewModel(actions: actions, dependencies: makeOSCAMapUIViewModelDependencies(), poi: poi)
  } // end func makeOSCAMKMapDetailViewModel

  /// make map detail view controller
  func makePoiDetailsViewController(
    actions: OSCAPOIDetailViewModel.Actions,
    poi: OSCAPoi
  ) -> OSCAPOIDetailViewController {
    let viewModel: OSCAPOIDetailViewModel = makePoiDetailsViewModel(
      actions: actions,

      poi: poi
    )
    return OSCAPOIDetailViewController.create(with: viewModel)
  } // end func makePoiDetailsViewController
  
  /// make Map container view model
  func makeContainerViewModel(actions: OSCAMapContainerViewModel.Actions) -> OSCAMapContainerViewModel {
    let dependencies = makeOSCAMapUIViewModelDependencies()
    return OSCAMapContainerViewModel(
      actions: actions,
      dependencies: dependencies
    )
  }

  /// make Map container view controller
  func makeContainerViewController(actions: OSCAMapContainerViewModel.Actions) -> OSCAMapContainerViewController {
    let containerViewModel = makeContainerViewModel(actions: actions)
    return OSCAMapContainerViewController.create(with: containerViewModel)
  }
  
  /// make Map category view model
  func makeCategoriesViewModel(actions: OSCAMapCategoryViewModel.Actions) -> OSCAMapCategoryViewModel {
    let dependencies = makeOSCAMapUIViewModelDependencies()
    return OSCAMapCategoryViewModel(
      actions: actions,
      dependencies: dependencies
    )
  } // end func makeOSCAMKMapCategoryViewModel

  /// make Map category view controller
  func makeCategoryViewController(actions: OSCAMapCategoryViewModel.Actions) -> OSCAMapCategoryViewController {
    let categoriesViewModel = makeCategoriesViewModel(
      actions: actions)
    return OSCAMapCategoryViewController.create(
      with: categoriesViewModel)
  } // end func makeOSCAMKMapCategoryViewController
  
  /// make Map category detail view model
  func makeCategoryDetailViewModel(actions: OSCAMapCategoryDetailViewModel.Actions, category: OSCAPoiCategory) -> OSCAMapCategoryDetailViewModel {
    let dependencies = makeOSCAMapUIViewModelDependencies()
    return OSCAMapCategoryDetailViewModel(
      actions: actions,
      category: category,
      dependencies: dependencies
    )
  }

  /// make Map category detail view controller
  func makeCategoryDetailViewController(actions: OSCAMapCategoryDetailViewModel.Actions, category: OSCAPoiCategory) -> OSCAMapCategoryDetailViewController {
    let categoryDetailViewModel = makeCategoryDetailViewModel(
      actions: actions,
      category: category)
    return OSCAMapCategoryDetailViewController.create(
      with: categoryDetailViewModel)
  }
  
  /// make Map category detail list view model
  func makeCategoryDetailListViewModel(actions: OSCAMapCategoryDetailListViewModel.Actions, category: OSCAPoiCategory, categoryPois: [OSCAPoi]) -> OSCAMapCategoryDetailListViewModel {
    let dependencies = makeOSCAMapUIViewModelDependencies()
    return OSCAMapCategoryDetailListViewModel(
      actions: actions,
      category: category,
      categoryPois: categoryPois,
      dependencies: dependencies
    )
  }

  /// make Map category detail list view controller
  func makeCategoryDetailListViewController(actions: OSCAMapCategoryDetailListViewModel.Actions, category: OSCAPoiCategory, categoryPois: [OSCAPoi]) -> OSCAMapCategoryDetailListViewController {
    let categoryDetailListViewModel = makeCategoryDetailListViewModel(
      actions: actions,
      category: category,
      categoryPois: categoryPois)
    return OSCAMapCategoryDetailListViewController.create(
      with: categoryDetailListViewModel)
  }
  
  /// make Map view model
  func makeMapViewModel(actions: OSCAMapViewModel.Actions) -> OSCAMapViewModel {
    let dependencies = makeOSCAMapUIViewModelDependencies()
    return OSCAMapViewModel(
      actions: actions,
      dependencies: dependencies
    )
  } // end func makeMapViewModel

  /// make Map view controller
  func makeMapViewController(actions: OSCAMapViewModel.Actions) -> OSCAMapViewController {
    let mainViewModel = makeMapViewModel(actions: actions)
    return OSCAMapViewController.create(with: mainViewModel)
  } // end func makeOSCANewMKMapViewController
} // end extension extension final class OSCAMapUI.DIContainer

extension OSCAMapUI.DIContainer: OSCAMapWidgetFlowCoordinatorDependencies {  
  func makeMapMainWidgetViewModel(actions: OSCAMapMainWidgetViewModel.Actions) -> OSCAMapMainWidgetViewModel {
    let dependencies = OSCAMapMainWidgetViewModel.Dependencies(
      actions: actions,
      dataModule: self.dependencies.dataModule,
      moduleConfig: self.dependencies.moduleConfig)
    return OSCAMapMainWidgetViewModel(dependencies: dependencies)
  }
  
  func makeOSCAMapMainWidgetViewController(actions: OSCAMapMainWidgetViewModel.Actions) -> OSCAMapMainWidgetViewController {
    let viewModel = self.makeMapMainWidgetViewModel(actions: actions)
    return OSCAMapMainWidgetViewController.create(with: viewModel)
  }
  
  
  func makeOSCAMapWidgetFlowCoordinator(router: Router) -> OSCAMapWidgetFlowCoordinator {
    return OSCAMapWidgetFlowCoordinator(router: router, dependencies: self)
  }
}
