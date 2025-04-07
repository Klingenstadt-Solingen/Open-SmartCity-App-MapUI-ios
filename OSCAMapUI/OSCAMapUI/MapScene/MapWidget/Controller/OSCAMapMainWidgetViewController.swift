//
//  OSCAMapMainWidgetViewController.swift
//  OSCAMapUI
//
//  Created by Igor Dias on 08.05.23.
//

import OSCAEssentials
import CoreLocation
import MapKit
import OSCAMap
import UIKit
import Combine

public final class OSCAMapMainWidgetViewController: UIViewController, Alertable, ActivityIndicatable, WidgetExtender {
  
  public var activityIndicatorView: ActivityIndicatorView = ActivityIndicatorView(style: .large)
  
  private var viewModel: OSCAMapMainWidgetViewModel!
  private var bindings = Set<AnyCancellable>()
  private let locationManager = CLLocationManager()
  var currentLocation: CLLocation?
  
  @IBOutlet weak var mapView: MKMapView!
  @IBOutlet weak var mapViewContainer: UIView!
  
  @IBOutlet var mapContainerHeightConstraint: NSLayoutConstraint!
  
  public override func viewDidLoad() {
    super.viewDidLoad()
    self.setupViews()
    self.setupBindings()
    self.requestLocationPermissionsIfNeeded()
    self.viewModel.viewDidLoad()
  }
  
  public override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    let colorConfig = self.viewModel.colorConfig
    self.navigationController?.setup(
      largeTitles: false,
      tintColor: colorConfig.navigationTintColor,
      titleTextColor: colorConfig.navigationTitleTextColor,
      barColor: colorConfig.navigationBarColor)
  }
  
  private func setupViews() {
    self.view.backgroundColor = .clear
    self.navigationItem.title = self.viewModel.widgetTitle
    
    self.mapViewContainer.backgroundColor = .clear
    self.mapViewContainer.addShadow(with: OSCAMapUI.configuration.shadow)
    
    self.mapContainerHeightConstraint.constant = 112
    
    self.setupActivityIndicator()
    self.setupMapView()
    self.setMapLocation()
  }
  
  // MARK: - View Model Binding
  private func setupBindings() {
    self.viewModel.$pois
      .dropFirst()
      .sink(receiveValue: { [weak self] pois in
        guard let `self` = self else { return }
        DispatchQueue.main.async {
          self.updateMap(with: pois)
          self.didLoadContent?(pois.count)
        }
      })
      .store(in: &bindings)
  }
  
  private func setupMapView() {
    self.mapView.delegate = self
    self.mapView.showsUserLocation = true
    self.mapView.isScrollEnabled = false
    self.mapView.isZoomEnabled = false
    self.mapView.mapType = .mutedStandard
    self.mapView.translatesAutoresizingMaskIntoConstraints = false
    self.mapView.layer.cornerRadius = OSCAMapUI.configuration.cornerRadius
    self.mapView.clipsToBounds = true
    
    let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(mapTouched))
    tapRecognizer.numberOfTapsRequired = 1
    tapRecognizer.numberOfTouchesRequired = 1
    self.mapView.addGestureRecognizer(tapRecognizer)
  }
    
  
  // MARK: WidgetExtender
  /// Closure parameter sends the number of pois
  public var didLoadContent   : ((Int) -> Void)?
  /// Closure parameter sends a deeplink of type __URL__
  public var performNavigation: ((Any) -> Void)?
  
  public func refreshContent() {
    self.viewModel.refreshContent()
  }
  
  @objc func mapTouched() {
#if DEBUG
    print("\(String(describing: self)): \(#function)")
#endif
    viewModel.showMapTouch()
  }
  
  private func setMapLocation() {
    var location = CLLocationCoordinate2D(
      latitude: Environment.defaultGeoPoint.latitude,
      longitude: Environment.defaultGeoPoint.longitude)
    
    var latMeters: CLLocationDistance = 2000
    var lonMeters: CLLocationDistance = 2000
    
    if let userLocation = self.currentLocation {
      location = userLocation.coordinate
      latMeters = 1000
      lonMeters = 1000
    }
    
    self.mapView.region = MKCoordinateRegion(
      center: location,
      latitudinalMeters: latMeters,
      longitudinalMeters: lonMeters)
  }
  
  private func requestLocationPermissionsIfNeeded() {
    locationManager.requestWhenInUseAuthorization()
    if CLLocationManager.locationServicesEnabled() {
      locationManager.delegate = self
      locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
      locationManager.distanceFilter = 50
      locationManager.startUpdatingLocation()
    }
  }
}


// MARK: - instantiate view conroller
extension OSCAMapMainWidgetViewController: StoryboardInstantiable {
  public static func create(with viewModel: OSCAMapMainWidgetViewModel) -> OSCAMapMainWidgetViewController {
#if DEBUG
    print("\(String(describing: self)): \(#function)")
#endif
    let vc: Self = Self.instantiateViewController(OSCAMapUI.bundle)
    vc.viewModel = viewModel
    return vc
  }
}


extension OSCAMapMainWidgetViewController: MKMapViewDelegate {
  public func mapView(_: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
#if DEBUG
    print("\(String(describing: self)): \(#function)")
#endif
    print(#function)
    guard annotation is OSCAPoiAnnotation else { return nil }
    
    guard let oscaAnnotation = annotation as? OSCAPoiAnnotation else { return nil }
    
    let annotationView = MKAnnotationView(annotation: oscaAnnotation, reuseIdentifier: "Annotation")
    annotationView.annotation = oscaAnnotation
    annotationView.canShowCallout = false
    
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
            self.viewModel.imageDataCache.setObject(
              NSData(data: imageData),
              forKey: NSString(string: oscaAnnotation.imageUrl!)
            )
            
            annotationView.image = UIImage(data: imageData)
          }
          .store(in: &bindings)
      }
    } else {}
    
    return annotationView
  }
}


extension OSCAMapMainWidgetViewController: CLLocationManagerDelegate {
  public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
#if DEBUG
    print("\(String(describing: self)): \(#function)")
#endif
    currentLocation = locations.first
    if let location = locations.first {
      mapView.region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 500, longitudinalMeters: 500)
      viewModel.fetchPOIs()
    }
  }
}

extension OSCAMapMainWidgetViewController {
  private func updateMap(with pois: [OSCAPoi]) {
#if DEBUG
    print("\(String(describing: self)): \(#function)")
#endif
    // clean the map
    let allAnnotations = mapView?.annotations
    mapView?.removeAnnotations(allAnnotations ?? [])
    
    // add the new pois to the map
    var annotations: [OSCAPoiAnnotation] = []
    for poi in pois {
      guard let lat = poi.geopoint?.latitude, let lon = poi.geopoint?.longitude,
            let objectId = poi.objectId else { return }
      let coordinates = CLLocationCoordinate2D(latitude: lat, longitude: lon)
      
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
    }
    mapView?.addAnnotations(annotations)
  }
}
