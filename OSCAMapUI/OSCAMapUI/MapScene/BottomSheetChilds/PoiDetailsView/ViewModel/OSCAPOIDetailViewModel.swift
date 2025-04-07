//
//  OSCAPOIDetailViewModel.swift
//  OSCAMapUI
//
//  Created by Mammut Nithammer on 25.06.22.
//  Reviewed by Stephan Breidenbach on 15.08.22
//  Copyright © 2020 Stadt Solingen. All rights reserved.
//

import CoreLocation
import Foundation
import OSCAMap
import UIKit

// MARK: - OSCAPOIDetailViewModel

public final class OSCAPOIDetailViewModel: OSCAMapUI.ViewModel {
  // MARK: Lifecycle

  public init(
    actions: OSCAPOIDetailViewModel.Actions,
    dependencies: OSCAMapUI.ViewModel.Dependencies,
    poi: OSCAPoi
  ) {
    self.actions = actions
    self.poi = poi
    super.init(dependencies: dependencies)
  } // end

  // MARK: Internal

  enum Section {
    case details
    case image
  } // end enum Section

  var actions: OSCAPOIDetailViewModel.Actions

  // MARK: - OUTPUT

  @Published private(set) var title: String = ""
  @Published private(set) var category: String = ""
  @Published private(set) var distance: String = ""
  @Published private(set) var phone: String = ""
  @Published private(set) var hasMenu: Bool = false
  @Published private(set) var menuUrl: String = ""
  @Published private(set) var hasWebsite: Bool = false
  @Published private(set) var websiteUrl: String = ""
  @Published private(set) var details: [OSCAPoiDetailGroup] = []
  @Published private(set) var hasImages: Bool = false
  @Published private(set) var images: [OSCAPoi.Image] = []
  @Published private(set) var hasPhone: Bool = false
  
  /**
   Use this to get access to the __Bundle__ delivered from this module's configuration parameter __externalBundle__.
   - Returns: The __Bundle__ given to this module's configuration parameter __externalBundle__. If __externalBundle__ is __nil__, The module's own __Bundle__ is returned instead.
   */
  var bundle: Bundle = {
    if let bundle = OSCAMapUI.configuration.externalBundle {
      return bundle
    }
    else { return OSCAMapUI.bundle }
  }()
  
  private(set) var poi: OSCAPoi
} // end public final class PoiDetailsViewModel

// MARK: - Actions

extension OSCAPOIDetailViewModel {
  public struct Actions {
    public let closeDetailSheet: () -> Void
    public let openWebsite: (_ url: URL) -> Void
    public let initPhoneCall: (_ phoneNumber: String) -> Void
    public let openMenu: (_ url: URL) -> Void
    public let share: (_ poi: OSCAPoi) -> Void
    public let sentEmail: (_ address: String) -> Void
    public let openDirections: (_ poi: OSCAPoi) -> Void
    public let showFullscreenImage: (_ image: UIImage) -> Void
  } // end public struct

  func showDetails() {
    title = poi.name ?? ""
    category = poi.poiCategoryObject?.name ?? ""

    if let websiteUrl = getValue(for: .url, from: poi.details) {
      hasWebsite = true
      self.websiteUrl = websiteUrl
    } else {
      hasWebsite = false
    }

    if let details = poi.details {
      let nonNilDetails = details.compactMap { $0 }
      let detailGroups = OSCAPoiDetailGroup.convert(from: nonNilDetails)
      self.details = detailGroups.sorted(by: { $0.position < $1.position })
    }

    if let images = poi.images,
       !images.compactMap({ $0 }).isEmpty {
      self.images = images.compactMap { $0 }
      hasImages = true
    } else {
      hasImages = false
    }

    if let lat = poi.geopoint?.latitude, let lon = poi.geopoint?.longitude {
      distance = getDistance(to: CLLocation(latitude: lat, longitude: lon))
    } else {
      distance = ""
    }

    if let phone = getValue(for: .tel, from: poi.details) {
      self.phone = phone
      hasPhone = true
    } else {
      hasPhone = false
    }
  }
} // end extension PoiDetailsViewModel

// MARK: - Data access

extension OSCAPOIDetailViewModel {} // end extension PoiDetailsViewModel

// MARK: - INPUT

extension OSCAPOIDetailViewModel {
  private func getValue(for type: OSCAPoi.Detail.DetailType, from details: [OSCAPoi.Detail?]?) -> String? {
    guard let details = details else { return nil }

    let nonNilDetails = details.compactMap { $0 }

    let sorted = nonNilDetails.sorted(by: { $0.position ?? 9999 < $1.position ?? 9999 })
    if let detail = sorted.first(where: { $0.type == type }) {
      return detail.value
    }

    return nil
  }

  // swiftlint:disable:next identifier_name
  private func getDistance(to: CLLocation) -> String {
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
} // end extension PoiDetailsViewModel

// MARK: Localized Strings
extension OSCAPOIDetailViewModel {
  var poiShareText: String { NSLocalizedString(
    "map_poi_details_share_poi_message",
    bundle: self.bundle,
    comment: "The text sharing a poi") }
}
