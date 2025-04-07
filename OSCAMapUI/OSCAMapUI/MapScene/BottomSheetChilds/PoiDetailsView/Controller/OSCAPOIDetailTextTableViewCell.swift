//
//  OSCAPOIDetailTextTableViewCell.swift
//  OSCAMapUI
//
//  Created by Mammut Nithammer on 25.06.22.
//  Reviewed by Stephan Breidenbach on 15.08.22
//  Copyright © 2020 Stadt Solingen. All rights reserved.
//

import UIKit

public final class OSCAPOIDetailTextTableViewCell: UITableViewCell {
  // MARK: Public

  public static let identifier = String(describing: OSCAPOIDetailTextTableViewCell.self)

  override public func prepareForReuse() {
    titleLabel.text = ""
    vStack.removeAllArrangedSubviews()
  }

  // MARK: Internal

  @IBOutlet var titleLabel: UILabel!
  @IBOutlet var vStack: UIStackView!

  var viewModel: OSCAPOIDetailTextCellViewModel! {
    didSet {
      titleLabel.text = viewModel.detail.title

      for value in viewModel.detail.values {
        let label = UILabel()
        label.text = value
        label.font = OSCAMapUI.configuration.fontConfig.captionLight
        label.numberOfLines = 0
        label.textColor = .label

        vStack.addArrangedSubview(label)
      }
    }
  } // end var viewModel
} // end public final class PoiDetailsTableViewCell
