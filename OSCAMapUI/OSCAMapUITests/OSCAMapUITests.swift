// reviewed by Stephan Breidenbach on 21.06.22
//  Copyright © 2020 Stadt Solingen. All rights reserved.
#if canImport(XCTest) && canImport(OSCATestCaseExtension)
import OSCAEssentials
import OSCAMap
@testable import OSCAMapUI
import OSCANetworkService
import OSCATestCaseExtension
import XCTest

final class OSCAMapUITests: XCTestCase {
  static let moduleVersion = "1.0.4"
  override func setUpWithError() throws {
    try super.setUpWithError()
  } // end override fun setUp
  
  func testModuleInit() throws {
    let uiModule = try makeDevUIModule()
    XCTAssertNotNil(uiModule)
    XCTAssertEqual(uiModule.version, OSCAMapUITests.moduleVersion)
    XCTAssertEqual(uiModule.bundlePrefix, "de.osca.map.ui")
    let bundle = OSCAMap.bundle
    XCTAssertNotNil(bundle)
    let uiBundle = OSCAMapUI.bundle
    XCTAssertNotNil(uiBundle)
    let configuration = OSCAMapUI.configuration
    XCTAssertNotNil(configuration)
    XCTAssertNotNil(devPlistDict)
    XCTAssertNotNil(productionPlistDict)
  } // end func testModuleInit
  
  func testContactUIConfiguration() throws {
    _ = try makeDevUIModule()
    let uiModuleConfig = try makeUIModuleConfig()
    XCTAssertEqual(OSCAMapUI.configuration.title, uiModuleConfig.title)
    XCTAssertEqual(OSCAMapUI.configuration.colorConfig.accentColor, uiModuleConfig.colorConfig.accentColor)
    XCTAssertEqual(OSCAMapUI.configuration.fontConfig.bodyHeavy, uiModuleConfig.fontConfig.bodyHeavy)
  } // end func testEventsUIConfiguration
} // end finla Class OSCATemplateTests

// MARK: - factory methods

extension OSCAMapUITests {
  func makeDevModuleDependencies() throws -> OSCAMap.Dependencies {
    let networkService = try makeDevNetworkService()
    let userDefaults = try makeUserDefaults(domainString: "de.osca.map.ui")
    let dependencies = OSCAMap.Dependencies(
      networkService: networkService,
      userDefaults: userDefaults
    )
    return dependencies
  } // end public func makeDevModuleDependencies
  
  func makeDevModule() throws -> OSCAMap {
    let devDependencies = try makeDevModuleDependencies()
    // initialize module
    let module = OSCAMap.create(with: devDependencies)
    return module
  } // end public func makeDevModule
  
  func makeProductionModuleDependencies() throws -> OSCAMap.Dependencies {
    let networkService = try makeProductionNetworkService()
    let userDefaults = try makeUserDefaults(domainString: "de.osca.map.ui")
    let dependencies = OSCAMap.Dependencies(
      networkService: networkService,
      userDefaults: userDefaults
    )
    return dependencies
  } // end public func makeProductionModuleDependencies
  
  func makeProductionModule() throws -> OSCAMap {
    let productionDependencies = try makeProductionModuleDependencies()
    // initialize module
    let module = OSCAMap.create(with: productionDependencies)
    return module
  } // end public func makeProductionModule
  
  func makeUIModuleConfig() throws -> OSCAMapUI.Config {
    OSCAMapUI.Config(
      title: "OSCAMapUI",
      fontConfig: OSCAFontSettings(),
      colorConfig: OSCAColorSettings()
    )
  } // end public func makeUIModuleConfig
  
  func makeDevUIModuleDependencies() throws -> OSCAMapUI.Dependencies {
    let module = try makeDevModule()
    let uiConfig = try makeUIModuleConfig()
    return OSCAMapUI.Dependencies(
      moduleConfig: uiConfig,
      dataModule: module
    )
  } // end public func makeDevUIModuleDependencies
  
  func makeDevUIModule() throws -> OSCAMapUI {
    let devDependencies = try makeDevUIModuleDependencies()
    // init ui module
    let uiModule = OSCAMapUI.create(with: devDependencies)
    return uiModule
  } // end public func makeUIModule
  
  func makeProductionUIModuleDependencies() throws -> OSCAMapUI.Dependencies {
    let module = try makeProductionModule()
    let uiConfig = try makeUIModuleConfig()
    return OSCAMapUI.Dependencies(
      moduleConfig: uiConfig,
      dataModule: module
    )
  } // end public func makeProductionUIModuleDependencies
  
  func makeProductionUIModule() throws -> OSCAMapUI {
    let productionDependencies = try makeProductionUIModuleDependencies()
    // init ui module
    let uiModule = OSCAMapUI.create(with: productionDependencies)
    return uiModule
  } // end public func makeProductionUIModule
} // end extension OSCAMapUITests
#endif
