//
//  OSCAPOIDetailImageCellViewModel.swift
//  OSCAMapUI
//
//  Created by Mammut Nithammer on 23.08.22.
//  Copyright © 2020 Stadt Solingen. All rights reserved.
//

import Combine
import Foundation
import OSCAMap

class OSCAPOIDetailImageCellViewModel {
  // MARK: Lifecycle

  public init(
    imageCache: NSCache<NSString, NSData>,
    image: OSCAPoi.Image,
    dataModule: OSCAMap,
    at row: Int
  ) {
    imageDataCache = imageCache
    self.image = image
    self.dataModule = dataModule
    cellRow = row
  }

  // MARK: Internal

  var image: OSCAPoi.Image?
  let imageDataCache: NSCache<NSString, NSData>

  @Published private(set) var imageData: Data?

  var imageDataFromCache: Data? {
    let imageData = imageDataCache.object(forKey: NSString(string: getImageUrl()))
    return imageData as Data?
  }

  func didSetViewModel() {
#if DEBUG
    print("\(String(describing: self)): \(#function)")
#endif
    if let imageDataFromCache = self.imageDataFromCache {
      self.imageData = imageDataFromCache
      
    } else {
      let urlString = getImageUrl()
      self.fetchImage(from: urlString)
    }
  }

  // MARK: Private

  private let dataModule: OSCAMap
  private let cellRow: Int
  private var bindings = Set<AnyCancellable>()

  private func fetchImage(from urlString: String) {
    print("IMAGE: requesting image from: \(urlString)")
    var httpsString = urlString

    if urlString.contains("http://") {
      httpsString = urlString.replacingOccurrences(of: "http://", with: "https://")
      print("IMAGE: url changed to: \(httpsString)")
    }

    guard let url = URL(string: httpsString) else { return }
    print("IMAGE: conversion to URL successfull")

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
      self.imageDataCache.setObject(
        NSData(data: imageData),
        forKey: NSString(string: urlString)
      )
      self.imageData = imageData
    }
    .store(in: &bindings)
  }

  private func getImageUrl() -> String {
    guard var path = image?.imagePath,
          let imageName = image?.imageName,
          let mimeType = image?.imageMimetype
    else { return "" }
    
    if path.last == "/" {
      path.removeLast()
    }

    return "\(path)/\(imageName)\(mimeType)"
  }
}
