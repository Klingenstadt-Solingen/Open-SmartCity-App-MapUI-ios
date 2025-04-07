//
//  OSCAMapCategoryCellViewModel.swift
//  OSCAMapUI
//
//  Created by Mammut Nithammer on 25.06.22.
//  Reviewed by Stephan Breidenbach on 14.08.22
//  Copyright © 2020 Stadt Solingen. All rights reserved.
//

import Combine
import Foundation
import OSCAMap

final class OSCAMapCategoryCellViewModel {
  // MARK: Lifecycle

  public init(
    category: OSCAPoiCategory,
    dataModule: OSCAMap,
    at row: Int
  ) {
    self.category = category
    self.dataModule = dataModule
    cellRow = row

    setupBindings()
  }

  // MARK: Internal

  var title: String = ""
  var selectedValue: String = ""

  var category: OSCAPoiCategory

  @Published private(set) var imageData: Data?

  var imageDataFromCache: Data? {
    guard let objectId = category.objectId else { return nil }
    let imageData = self.dataModule.dataCache.object(forKey: NSString(string: objectId))
    return imageData as Data?
  }

  func didSetViewModel() {
    if let imageDataFromCache = self.imageDataFromCache {
      self.imageData = imageDataFromCache
      
    } else {
      self.fetchImage(from: self.category)
    }
  }

  // MARK: Private

  private let dataModule: OSCAMap
  private let cellRow: Int
  private var bindings = Set<AnyCancellable>()

  private func setupBindings() {
    title = category.name ?? ""
  }

  private func fetchImage(from category: OSCAPoiCategory) {
    let publisher: AnyPublisher<OSCAPoiCategory.IconImageData, OSCAMapError> = dataModule
      .fetchImageData(poiCategory: category)
    publisher.sink { _ in
    } receiveValue: { [weak self] imageData in
      guard let self = self else { return }
      self.imageData = imageData.imageData
    }
    .store(in: &bindings)
  }
} 
