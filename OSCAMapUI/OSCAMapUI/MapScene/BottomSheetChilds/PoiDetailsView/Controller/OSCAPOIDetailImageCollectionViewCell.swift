//
//  OSCAPOIDetailImageCollectionViewCell.swift
//  OSCAMapUI
//
//  Created by Mammut Nithammer on 23.08.22.
//  Copyright © 2020 Stadt Solingen. All rights reserved.
//

import Combine
import UIKit

class OSCAPOIDetailImageCollectionViewCell: UICollectionViewCell {
  // MARK: Public

  public static let identifier = String(describing: OSCAPOIDetailImageCollectionViewCell.self)

  public var viewModel: OSCAPOIDetailImageCellViewModel! {
    didSet {
      setupView()
      setupBindings()
      viewModel.didSetViewModel()
    }
  }

  // MARK: Private

  @IBOutlet var imageView: UIImageView!

  private var bindings = Set<AnyCancellable>()

  private func setupView() {
    imageView.contentMode = .scaleAspectFill
  }

  private func setupBindings() {
    viewModel.$imageData
      .receive(on: RunLoop.main)
      .dropFirst()
      .sink(receiveValue: { [weak self] imageData in
        print("IMAGE: got imageData update")
        guard let self = self,
              let imageData = imageData
        else { return }

        self.imageView.image = UIImage(data: imageData)
      })
      .store(in: &bindings)
  }
}
