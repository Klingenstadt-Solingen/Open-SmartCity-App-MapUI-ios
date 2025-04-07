//
//  OSCAMapCategoryDetailCellView.swift
//  OSCAMapUI
//
//  Created by Ömer Kurutay on 13.01.23.
//

import OSCAEssentials
import OSCAMap
import UIKit

public final class OSCAMapCategoryDetailCellView: UICollectionViewCell {
  public static let identifier = String(describing: OSCAMapCategoryDetailCellView.self)
  
  @IBOutlet private var titleContainer: UIView!
  @IBOutlet private var titleLabel: UILabel!
  
  private var viewModel: OSCAMapCategoryDetailCellViewModel!
  
  public override func awakeFromNib() {
    super.awakeFromNib()
    self.layer.borderWidth = 1
    self.layer.borderColor = OSCAMapUI.configuration
      .colorConfig.primaryColor.cgColor
    self.clipsToBounds = false
    
    self.titleContainer.backgroundColor = .clear
    
    self.titleLabel.font = OSCAMapUI.configuration
      .fontConfig.captionLight
    self.titleLabel.textColor = OSCAMapUI.configuration
      .colorConfig.primaryColor
    self.titleLabel.numberOfLines = 0
  }
  
  public override func layoutSubviews() {
    super.layoutSubviews()
    self.addLimitedCornerRadius(OSCAMapUI.configuration.cornerRadius)
  }
  
  func fill(with viewModel: OSCAMapCategoryDetailCellViewModel) {
    self.viewModel = viewModel
    
    self.titleLabel.text = viewModel.filterName
    
    viewModel.fill()
  }
  
  public override var isSelected: Bool {
    didSet {
      if self.isSelected {
        let color = OSCAMapUI.configuration.colorConfig.primaryColor
        self.backgroundColor = color
        self.titleLabel.textColor = color.isDarkColor
          ? OSCAMapUI.configuration.colorConfig.whiteDark
          : OSCAMapUI.configuration.colorConfig.blackColor
        
      } else {
        self.backgroundColor = .clear
        self.titleLabel.textColor = OSCAMapUI.configuration
          .colorConfig.primaryColor
      }
    }
  }
}
