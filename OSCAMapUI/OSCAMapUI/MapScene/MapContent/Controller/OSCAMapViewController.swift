//
//  OSCAOSCAMapViewController.swift
//  OSCAMapUI
//
//  Created by Mammut Nithammer on 24.06.22.
//  Reviewed by Stephan Breidenbach on 15.08.22
//  Copyright © 2020 Stadt Solingen. All rights reserved.
//

import Combine
import MapKit
import OSCAEssentials
import OSCAMap
import UIKit

// MARK: - OSCAMapViewController

public final class OSCAMapViewController: UIViewController {
  let locationManager = CLLocationManager()
  var currentLocation: CLLocation?

  /// handle to the activity indicator
  public lazy var activityIndicatorView = ActivityIndicatorView(style: .large)

  override public func viewDidLoad() {
    super.viewDidLoad()

    mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: "Annotation")

    bind(to: viewModel)
    setupMapView()
    setupLocationManager()
    setupActivityIndicator()
    viewModel.viewDidLoad()
  } // end override public func viewDidLoad
  
  public override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    let colorConfig = self.viewModel.colorConfig
    let navigationBar = self.navigationController?.navigationBar
    navigationBar?.prefersLargeTitles = false
    navigationBar?.tintColor = colorConfig.primaryColor
    
    let barAppearance = UINavigationBarAppearance()
    barAppearance.configureWithTransparentBackground()
    barAppearance.titleTextAttributes = [
      .foregroundColor: colorConfig.navigationTitleTextColor]
    barAppearance.backgroundColor = .clear
    
    navigationBar?.standardAppearance = barAppearance
    
    barAppearance.backgroundColor = .clear
    
    barAppearance.shadowColor = .clear
    navigationBar?.scrollEdgeAppearance = barAppearance
  }
  
  // MARK: Internal

  var viewModel: OSCAMapViewModel!

  let imageDataCache = NSCache<NSString, NSData>()

  func bind(to viewModel: OSCAMapViewModel) {
    viewModel.$state
      .receive(on: RunLoop.main)
      .sink { [weak self] state in
        guard let self = self else { return }
        switch state {
        case .loading:
          self.startLoading()

        case .finishedLoading:
          self.finishLoading()

        case let .error(error):
          self.finishLoading()
          self.showAlert(
            title: self.viewModel.alertTitleError,
            error: error,
            actionTitle: self.viewModel.alertActionConfirm
          )
        }
      }
      .store(in: &bindings)

    viewModel.$pois
      .receive(on: RunLoop.main)
      .dropFirst()
      .sink(receiveValue: { [weak self] pois in
        guard let self = self else { return }
        self.removeAllPOIs()
        self.addPOIsToMapView(pois)
      })
      .store(in: &bindings)

    viewModel.$selectedPoi
      .receive(on: RunLoop.main)
      .dropFirst()
      .sink(receiveValue: { [weak self] poi in
        guard let self = self else { return }
        if let poi = poi {
          self.removeAllPOIs()
          self.addPOIsToMapView([poi])
          
          var region: MKCoordinateRegion?
          if let centerCoordinates = viewModel.centerCoordinates {
            if let regionSpan = viewModel.regionSpan {
              region = MKCoordinateRegion(center: centerCoordinates.clLocationCoordinate2D,
                                          latitudinalMeters: regionSpan,
                                          longitudinalMeters: regionSpan)
            } else {
              region = MKCoordinateRegion(center: centerCoordinates.clLocationCoordinate2D,
                                          latitudinalMeters: 500,
                                          longitudinalMeters: 500)
            }// end if
          } else {
            if let regionSpan = viewModel.regionSpan {
              if let lat = poi.geopoint?.latitude,
                 let lon = poi.geopoint?.longitude {
                 let center = CLLocationCoordinate2DMake(lat, lon)
                region = MKCoordinateRegion(center: center,
                                          latitudinalMeters: regionSpan,
                                          longitudinalMeters: regionSpan)
              }// end if
            } else {
              if let lat = poi.geopoint?.latitude,
                 let lon = poi.geopoint?.longitude {
                let center = CLLocationCoordinate2DMake(lat, lon)
                region = MKCoordinateRegion(center: center,
                                            latitudinalMeters: 500,
                                            longitudinalMeters: 500)
              }// end if
            }// end if
          }// end if
        if let region = region {
          self.mapView.setRegion(region, animated: true)
        }// end if
          
        selectAnnotationOf(poi)
      }// end if
      })
      .store(in: &bindings)
  } // end func bind to map view model
  
  public func selectAnnotationOf(_ poi: OSCAPoi) {
    let annotationsList = mapView.annotations.compactMap { $0 as? OSCAPoiAnnotation }
    guard let annotation = annotationsList.first(where: { $0.poiObjectId == poi.objectId }) else { return }
    mapView.selectAnnotation(annotation, animated: true)
  }

  // MARK: Private

  @IBOutlet private var mapView: MKMapView!

  private var bindings = Set<AnyCancellable>()

  private var originalBottomSheetSize: CGSize = .zero

  private func startLoading() {
    activityIndicatorView.isHidden = false
    activityIndicatorView.startAnimating()
  } // end private func startLoading

  private func finishLoading() {
    activityIndicatorView.stopAnimating()
  } // end private func finishLoading

  private func removeAllPOIs() {
    let allAnnotations = mapView.annotations
    mapView.removeAnnotations(allAnnotations)
  }

  private func addPOIsToMapView(_ pois: [OSCAPoi]) {
    var annotations: [OSCAPoiAnnotation] = []
    for poi in pois {
      guard let geopoint = OSCAGeoPoint(poi.geopoint),
            let objectId = poi.objectId else { return }
      let coordinates = geopoint.clLocationCoordinate2D
      let imageUrl = viewModel.getIconUrl(for: poi)
      let annotation = OSCAPoiAnnotation(
        title: poi.name ?? "",
        subtitle: poi.poiCategoryObject?.name ?? "",
        coordinate: coordinates,
        poiObjectId: objectId,
        imageUrl: imageUrl,
        uiSettings: nil
      )

      annotations.append(annotation)
    } // end for poi
    mapView.addAnnotations(annotations)
    
    if annotations.count == 1 {
      guard let selectedAnnotation = annotations.first else { return }
      moveMapCameraTo(annotation: selectedAnnotation)
    }
  } // end private func addPOIsToMapView
  
  private func moveMapCameraTo(annotation: OSCAPoiAnnotation){
    let region = MKCoordinateRegion(
      center: annotation.coordinate,
      span: mapView.region.span
    )
    mapView.setRegion(region, animated: true)
  }
} // public final class OSCAMapViewController

// MARK: - annotation reuse identifiers

public extension OSCAMapViewController {
  enum AnnotationViewReuseIdentifiers: String, CaseIterable {
    /// poi annotation without customized symbol image
    case poiAnnotationMarker = "OSCAMapUI.OSCAPoiAnnotationMarkerView"
    /// poi annotation with customized symbol image
    case poiAnnotation = "OSCAMapUI.OSCAPoiAnnotationView"
  } // end public enum AnnotationViewReuseIdentifiers
} // end extension final class OSCAMkOSCAMapViewController

// MARK: StoryboardInstantiable

extension OSCAMapViewController: StoryboardInstantiable {
  /// function call: var vc = OSCAMKOSCAMapViewController.create(viewModel)
  public static func create(with viewModel: OSCAMapViewModel) -> OSCAMapViewController {
    #if DEBUG
      print("\(String(describing: self)): \(#function)")
    #endif
    var bundle: Bundle
    #if SWIFT_PACKAGE
      bundle = OSCAMapUI.bundle
    #else
      bundle = Bundle(for: Self.self)
    #endif
    let viewController = Self.instantiateViewController(bundle)
    viewController.viewModel = viewModel
    return viewController
  } // end public static func create
} // end extension final class OSCAMkOSCAMapViewController

// MARK: Alertable

extension OSCAMapViewController: Alertable {} // end extension final class OSCAMapViewController

// MARK: ActivityIndicatable

extension OSCAMapViewController: ActivityIndicatable {} // end extension final class OSCAMapViewController

// MARK: MKMapViewDelegate
extension OSCAMapViewController: MKMapViewDelegate {
  private func setMapRegion() -> Void {
    // set map's region
    let coordinates = self.viewModel.initialCoordinates
    let center = CLLocationCoordinate2DMake(coordinates.latitude, coordinates.longitude)
    let span = self.viewModel.initialRegionSpan
    let region = MKCoordinateRegion(center: center,
                                    latitudinalMeters: span.latSpan,
                                    longitudinalMeters: span.lonSpan)
    mapView.setRegion(region,
                      animated: true)
  }// end private func setMapRegion
  
  private func setupMapView() {
    mapView.showsUserLocation = true
    mapView.delegate = self
    mapView.register(
      OSCAPoiAnnotationMarkerView.self,
      forAnnotationViewWithReuseIdentifier: OSCAMapViewController.AnnotationViewReuseIdentifiers.poiAnnotationMarker
        .rawValue
    )
    setMapRegion()
  } // end private func setupMapView

  public func mapView(_: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped _: UIControl) {
    guard let annotation = view.annotation as? OSCAPoiAnnotation else { return }
    guard let object = viewModel.pois.first(where: { $0.objectId == annotation.poiObjectId }) else { return }

    viewModel.showDetails(of: object)
  } // end map view callout accessory control talpped

  public func mapView(_: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    guard annotation is OSCAPoiAnnotation else { return nil }

    guard let oscaAnnotation = annotation as? OSCAPoiAnnotation else { return nil }

    let annotationView = MKAnnotationView(annotation: oscaAnnotation, reuseIdentifier: "Annotation")
    annotationView.annotation = oscaAnnotation
    annotationView.canShowCallout = true

    let rightButton = UIButton(type: .detailDisclosure)
    annotationView.rightCalloutAccessoryView = rightButton

    if let imageUrl = oscaAnnotation.imageUrl {
      if let imageData = viewModel.getImageDataFromCache(with: imageUrl) {
        annotationView.image = UIImage(data: imageData)
      } else {
        let publisher: AnyPublisher<Data, OSCAMapError>? = viewModel.getImageData(from: imageUrl)
        publisher?.receive(on: RunLoop.main)
          .sink { completion in
            switch completion {
            case .finished:
              print("\(Self.self): finished \(#function)")

            case let .failure(error):
              print(error)
              print("\(Self.self): .sink: failure \(#function)")
            }
          } receiveValue: { imageData in
            self.imageDataCache.setObject(
              NSData(data: imageData),
              forKey: NSString(string: oscaAnnotation.imageUrl!)
            )

            annotationView.image = UIImage(data: imageData)
          }
          .store(in: &bindings)
      }
    } else {}

    return annotationView
  } // end map view view for annotation
} // end extension final class OSCAMapViewController

extension OSCAMapViewController: CLLocationManagerDelegate {
  func setupLocationManager() -> Void {
    locationManager.requestWhenInUseAuthorization()
    if CLLocationManager.locationServicesEnabled() {
      locationManager.delegate = self
      locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
      locationManager.distanceFilter = 50
      locationManager.startUpdatingLocation()
    }// end if
  }// end func setupLocationManager
  
  public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) -> Void {
    guard manager.delegate === self,
          let location = locations.first,
          let mapView = self.mapView
          else { return }
    mapView.region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 500, longitudinalMeters: 500)
  }// end func location manager did update locations
}// end extension final class OSCAMapViewController

// MARK: - Deeplinking
extension OSCAMapViewController {
  func didReceiveDeeplinkDetail(with objectId: String,
                                _ center: String? = nil,
                                _ span: String? = nil) -> Void {
    viewModel.didReceiveDeeplinkDetail(with: objectId,
                                       center: center,
                                       span: span)
  }// end func didReceiveDeeplinkDetail with objectId, center, span
  
  func didReceiveDeeplink(with objectId: String?) {
    self.viewModel.didReceiveDeeplink(with: objectId)
  }
} // end extension final class OSCAMapViewController
