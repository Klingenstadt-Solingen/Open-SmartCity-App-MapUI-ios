//
//  OSCAPOISearchResultTableViewCell.swift
//  OSCAMapUI
//
//  Created by Mammut Nithammer on 23.08.22.
//  Copyright © 2020 Stadt Solingen. All rights reserved.
//

import Combine
import OSCAEssentials
import UIKit

final class OSCAPOISearchResultTableViewCell: UITableViewCell {
  // MARK: Public

  public static let identifier = String(describing: OSCAPOISearchResultTableViewCell.self)

  public var viewModel: OSCAPOISearchResultViewModel! {
    didSet {
      setupView()
      setupBindings()
      viewModel.didSetViewModel()
    }
  }

  // MARK: Internal

  @IBOutlet var iconView: UIImageView!
  @IBOutlet var titleLabel: UILabel!
  @IBOutlet var detailsLabel: UILabel!

  // MARK: Private

  private var bindings = Set<AnyCancellable>()

  private func setupView() {
    self.backgroundColor = .clear
    self.contentView.backgroundColor = .clear
    titleLabel.text = viewModel.title
    titleLabel.font = OSCAMapUI.configuration
      .fontConfig.captionHeavy
    titleLabel.textColor = OSCAMapUI.configuration
      .colorConfig.textColor
    titleLabel.numberOfLines = 1

    detailsLabel.text = !viewModel.distance.isEmpty ? "\(viewModel.category) • \(viewModel.distance)" : viewModel.category
    detailsLabel.font = OSCAMapUI.configuration.fontConfig.smallLight
    detailsLabel.textColor = OSCAMapUI.configuration.colorConfig.whiteColor.darker(componentDelta: 0.3)
    detailsLabel.numberOfLines = 1

    iconView.image = viewModel.imageDataFromCache == nil
      ? OSCAMapUI.configuration.placeholderIcon
      : UIImage(data: viewModel.imageDataFromCache!)
    iconView.contentMode = .scaleAspectFit
  }

  private func setupBindings() {
    viewModel.$imageData
      .receive(on: RunLoop.main)
      .dropFirst()
      .sink(receiveValue: { [weak self] imageData in
        guard let self = self,
              let imageData = imageData
        else { return }

        self.iconView.image = UIImage(data: imageData)
      })
      .store(in: &bindings)
  }
}
