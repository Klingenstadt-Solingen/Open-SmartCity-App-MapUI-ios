//
//  OSCAPoiAnnotationMarkerView.swift
//  OSCAMapUI
//
//  Created by Stephan Breidenbach on 26.04.22.
//  Copyright © 2020 Stadt Solingen. All rights reserved.
//

import MapKit

/// An annotation view that displays a balloon-shaped marker at the designated location.
/// Used in case the `OSCAPoiCategory` of the referencing `OSCAPoi` has no symbol image data
public class OSCAPoiAnnotationMarkerView: MKMarkerAnnotationView {
  // MARK: Lifecycle

  override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
    super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
    displayPriority = .required
    //            clusteringIdentifier = OSCAPoiAnnotationView.preferredClusteringIdentifier
  } // end override init annotation, reuse identifier

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  } // end init required init coder

  // MARK: Internal

  override public var annotation: MKAnnotation? {
    willSet {
      guard newValue is OSCAPoiAnnotation else { return }
      setupView()
    } // end willSet
  } // end override var annotation

  // MARK: Private

  private func setupView() {
    super.displayPriority = .required
    super.canShowCallout = true
    super.isUserInteractionEnabled = true
    super.tintColor = .orange
    super.canShowCallout = true
    let rightCalloutButton = UIButton(type: .detailDisclosure)
    rightCalloutButton.tintColor = .systemBlue
    super.rightCalloutAccessoryView = rightCalloutButton
  } // end private func setupView
} // end class OSCAPoiAnnotationMarkerView
