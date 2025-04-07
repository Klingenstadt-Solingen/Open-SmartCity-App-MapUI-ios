//
//  OSCAMapCategoryCollectionViewCell.swift
//  OSCAMapUI
//
//  Created by Mammut Nithammer on 25.06.22.
//  Reviewed by Stephan Breidenbach on 14.08.22
//  Copyright © 2020 Stadt Solingen. All rights reserved.
//

import Combine
import OSCAEssentials
import UIKit

final class OSCAMapCategoryCollectionViewCell: UICollectionViewCell {
  // MARK: Public

  public static let identifier = String(describing: OSCAMapCategoryCollectionViewCell.self)

  public var viewModel: OSCAMapCategoryCellViewModel! {
    didSet {
      setupView()
      setupBindings()
      viewModel.didSetViewModel()
    }
  }

  // MARK: Internal

  @IBOutlet var imageView: UIImageView!
  @IBOutlet var titleLabel: UILabel!
  
  override func awakeFromNib() {
    super.awakeFromNib()
    self.imageView.backgroundColor = OSCAMapUI.configuration
      .colorConfig.secondaryBackgroundColor.darker(componentDelta: 0.04)
    self.imageView.tintColor = OSCAMapUI.configuration
      .colorConfig.primaryColor
    self.imageView.contentMode = .scaleAspectFill
    
    self.titleLabel.font = OSCAMapUI.configuration.fontConfig.captionLight
    self.titleLabel.textColor = OSCAMapUI.configuration.colorConfig.textColor
    self.titleLabel.numberOfLines = 2
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    self.imageView.layer.cornerRadius = self.imageView.frame.height / 2
  }

  // MARK: Private

  private var bindings = Set<AnyCancellable>()

  private func setupView() {
    self.contentView.backgroundColor = .clear

    self.titleLabel.attributedText = NSAttributedString(string: self.viewModel.title)
    self.titleLabel.hyphenate(alignment: .center)

    self.imageView.image = self.viewModel.imageDataFromCache == nil
      ? OSCAMapUI.configuration.placeholderIcon
      : UIImage(data: self.viewModel.imageDataFromCache!)?
          .withRenderingMode(.alwaysTemplate)
  }

  private func setupBindings() {
    self.viewModel.$imageData
      .receive(on: RunLoop.main)
      .dropFirst()
      .sink(receiveValue: { [weak self] imageData in
        guard let self = self,
              let imageData = imageData
        else { return }

        self.imageView.image = UIImage(data: imageData)?
          .withRenderingMode(.alwaysTemplate)
      })
      .store(in: &self.bindings)
  }
}
