//
//  OSCAPoiAnnotation.swift
//  OSCAMapUI
//
//  Created by Stephan Breidenbach on 25.04.22.
//  Copyright © 2020 Stadt Solingen. All rights reserved.
//
import Foundation
import MapKit
import OSCAEssentials

public class OSCAPoiAnnotation: NSObject, MKAnnotation {
  // MARK: Lifecycle

  public init(
    title: String,
    subtitle: String? = nil,
    coordinate: CLLocationCoordinate2D,
    poiObjectId: String,
    imageUrl: String?,
    uiSettings: OSCAPoiAnnotation.UISettings?
  ) {
    self.title = title
    self.subtitle = subtitle
    self.coordinate = coordinate
    self.poiObjectId = poiObjectId
    self.imageUrl = imageUrl
    self.uiSettings = uiSettings
    // invoke super class init
    super.init()
  } // end init

  // MARK: Internal

  public var title: String?
  public var subtitle: String?
  public var coordinate: CLLocationCoordinate2D
  public var poiObjectId: String?
  public var imageUrl: String?
  public var uiSettings: OSCAPoiAnnotation.UISettings?
} // end class OSCAPoiAnnotation

extension OSCAPoiAnnotation {
  public struct UISettings {
    init(
      image: UIImage? = nil,
      tintColor: UIColor? = nil,
      typeFace: UIFont? = nil
    ) {
      self.image = image
      self.tintColor = tintColor
      self.typeFace = typeFace
    } // end init
    
    // MARK: Internal
    
    var image: UIImage?
    var tintColor: UIColor?
    var typeFace: UIFont?
  } // end struct UISettings
}// end extension OSCAPoiAnnotation
