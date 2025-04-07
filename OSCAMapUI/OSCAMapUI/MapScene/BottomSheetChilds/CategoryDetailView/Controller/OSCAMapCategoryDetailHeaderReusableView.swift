//
//  OSCAMapCategoryDetailHeaderReusableView.swift
//  OSCAMapUI
//
//  Created by Ömer Kurutay on 17.01.23.
//

import OSCAEssentials
import OSCAMap
import UIKit

public final class OSCAMapCategoryDetailHeaderReusableView: UICollectionReusableView {
  public static let identifier = String(describing: OSCAMapCategoryDetailHeaderReusableView.self)
  
  @IBOutlet private var titleLabel: UILabel!
  
  private var viewModel: OSCAMapCategoryDetailHeaderReusableViewModel!
  
  public override func awakeFromNib() {
    super.awakeFromNib()
    self.backgroundColor = OSCAMapUI.configuration.colorConfig
      .secondaryBackgroundColor
    
    self.titleLabel.font = OSCAMapUI.configuration
      .fontConfig.bodyHeavy
    self.titleLabel.textColor = OSCAMapUI.configuration
      .colorConfig.textColor
  }
  
  func fill(with viewModel: OSCAMapCategoryDetailHeaderReusableViewModel) {
    self.viewModel = viewModel
    
    self.titleLabel.text = viewModel.title
    
    viewModel.fill()
  }
}
