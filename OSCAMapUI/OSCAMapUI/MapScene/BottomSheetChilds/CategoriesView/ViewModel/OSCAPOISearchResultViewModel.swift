//
//  OSCAPOISearchResultViewModel.swift
//  OSCAMapUI
//
//  Created by Mammut Nithammer on 23.08.22.
//  Copyright © 2020 Stadt Solingen. All rights reserved.
//

import Combine
import Foundation
import OSCAMap
import CoreLocation

final class OSCAPOISearchResultViewModel {
  // MARK: Lifecycle

  public init(
    poi: OSCAPoi,
    dataModule: OSCAMap,
    at row: Int
  ) {
    self.poi = poi
    self.dataModule = dataModule
    cellRow = row

    setupBindings()
  }

  // MARK: Internal

  var title: String = ""
  var category: String = ""
  @Published private(set) var distance: String = ""

  var poi: OSCAPoi

  @Published private(set) var imageData: Data?

  var imageDataFromCache: Data? {
    guard let objectId = poi.objectId else { return nil }
    let imageData = self.dataModule.dataCache.object(forKey: NSString(string: objectId))
    return imageData as Data?
  }

  func didSetViewModel() {
    if imageDataFromCache == nil {
      let urlString = getIconUrl()
      fetchImage(from: urlString)
    } else {
      imageData = imageData as Data?
    }
  }

  // MARK: Private

  private let dataModule: OSCAMap
  private let cellRow: Int
  private var bindings = Set<AnyCancellable>()

  private func setupBindings() {
    title = poi.name ?? ""
    category = poi.poiCategoryObject?.name ?? ""
    if let lat = poi.geopoint?.latitude, let lon = poi.geopoint?.longitude {
      distance = getDistance(to: CLLocation(latitude: lat, longitude: lon))
    } else {
      distance = ""
    }
  }

  private func fetchImage(from urlString: String) {
    guard let url = URL(string: urlString) else { return }

    let publisher: AnyPublisher<Data, OSCAMapError> = dataModule.fetchImageData(url: url)
    publisher.sink { completion in
      switch completion {
      case .finished:
        print("\(Self.self): finished \(#function)")

      case let .failure(error):
        print(urlString)
        print(error)
        print("\(Self.self): .sink: failure \(#function)")
      }
    } receiveValue: { imageData in
      self.dataModule.dataCache.setObject(
        NSData(data: imageData),
        forKey: NSString(string: urlString)
      )
      self.imageData = imageData
    }
    .store(in: &bindings)
  }

  private func getIconUrl() -> String {
    var urlString = ""
    if let defaultThematicView = poi.poiCategoryObject?.defaultThematicView {
      if let detail = poi.details?.first(where: { $0?.filterField == defaultThematicView }) {
        if var path = detail?.symbolPath, let iconName = detail?.symbolName, let mimeType = detail?.symbolMimetype {
          if path.last == "/" {
            path.removeLast()
          }
          urlString = "\(path)/\(iconName)\(mimeType)"
        }
        return urlString
      }
    }

    guard var path = poi.poiCategoryObject?.symbolPath,
          let iconName = poi.poiCategoryObject?.symbolName,
          let mimeType = poi.poiCategoryObject?.symbolMimetype else { return "" }
    
    if path.last == "/" {
      path.removeLast()
    }
    
    return "\(path)/\(iconName)\(mimeType)"
  }
} // end final class OSCAPOISearchResultViewModel

extension OSCAPOISearchResultViewModel {
  public func getDistance(to: CLLocation) -> String {
    var unit = "m"
    let locationManager = CLLocationManager()
    locationManager.requestWhenInUseAuthorization()
    if let userLocation = locationManager.location {
      var distance = to.distance(from: userLocation)
      if distance >= 1000 {
        distance /= 1000
        unit = "km"
      }
      let numberFormatter = NumberFormatter()
      numberFormatter.locale = Locale.current
      numberFormatter.maximumFractionDigits = 1

      if let distanceString = numberFormatter.string(from: NSNumber(value: distance)) {
        return "\(distanceString) \(unit)"
      }
    }

    return ""
  }
}
