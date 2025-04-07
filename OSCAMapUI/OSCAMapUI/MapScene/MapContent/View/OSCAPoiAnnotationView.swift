//
//  OSCAPoiAnnotationView.swift
//  OSCAMapUI
//
//  Created by Stephan Breidenbach on 29.04.22.
//  Copyright © 2020 Stadt Solingen. All rights reserved.
//

import MapKit

/// An annotation view that displays a customized marker at the designated location.
/// Used in case the `OSCAPoiCategory` of the referencing `OSCAPoi` has symbol image data
class OSCAPoiAnnotationView: MKAnnotationView {
  // MARK: Lifecycle

  override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
    super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
    displayPriority = .required
  } // end override init annotation, reuse identifier

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  } // end init required init coder

  // MARK: Internal

  override var annotation: MKAnnotation? {
    willSet {
      guard let poiAnnotation = newValue as? OSCAPoiAnnotation else { return }
      setupView(with: poiAnnotation)
    } // end willSet
  } // end override var annotation

  // MARK: Private

  private func setupView(with annotation: OSCAPoiAnnotation) {
    displayPriority = .required
    canShowCallout = true
    isUserInteractionEnabled = true
    // right accessory
    let rightAccessoryButton = UIButton(type: .detailDisclosure)
    if let uiSettings = annotation.uiSettings {
      // symbol
      if let image = uiSettings.image {
        self.image = image
      } // end if
      // tint color
      if let tintColor = uiSettings.tintColor {
        self.tintColor = tintColor
        detailCalloutAccessoryView?.tintColor = tintColor
        rightAccessoryButton.tintColor = tintColor
      } // end if
      // type face
      if let typeFace = uiSettings.typeFace {
        rightAccessoryButton.titleLabel?.font = typeFace
      } // end if
    } // end if
    rightCalloutAccessoryView = rightAccessoryButton
  } // end private func setupView
} // end class OSCAPoiAnnotationView
