//
//  OSCAPOIDetailHighlightedTableViewCell.swift
//  OSCAMapUI
//
//  Created by Mammut Nithammer on 24.08.22.
//  Copyright © 2020 Stadt Solingen. All rights reserved.
//

import UIKit

public final class OSCAPOIDetailHighlightedTableViewCell: UITableViewCell {
  // MARK: Public

  public static let identifier = String(describing: OSCAPOIDetailHighlightedTableViewCell.self)

  override public func prepareForReuse() {
    titleLabel.text = ""
    vStack.removeAllArrangedSubviews()
  }

  // MARK: Internal

  @IBOutlet var titleLabel: UILabel!
  @IBOutlet var vStack: UIStackView!

  var viewModel: OSCAPOIDetailHighlightedViewModel! {
    didSet {
      titleLabel.text = viewModel.detail.title

      for value in viewModel.detail.values {
        let label = UILabel()
        label.attributedText = NSAttributedString(
          string: value,
          attributes: [NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue]
        )
        label.font = OSCAMapUI.configuration.fontConfig.captionLight
        label.textColor = OSCAMapUI.configuration.colorConfig.primaryColor
        label.numberOfLines = 1

        vStack.addArrangedSubview(label)
      }
    }
  } // end var viewModel
} // end public final class PoiDetailsTableViewCell
