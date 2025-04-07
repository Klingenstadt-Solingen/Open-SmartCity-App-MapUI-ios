//
//  OSCAMapFilterCollectionViewCell.swift
//  OSCAMapUI
//
//  Created by Igor Dias on 13.10.22.
//  Copyright © 2020 Stadt Solingen. All rights reserved.
//

import Combine
import OSCAEssentials
import UIKit

final class OSCAMapFilterCollectionViewCell: UICollectionViewCell {
  private var bindings = Set<AnyCancellable>()
  
  public static let identifier = String(describing: OSCAMapFilterCollectionViewCell.self)
  
  public var viewModel: OSCAMapFilterCellViewModel! {
    didSet {
      setupView()
      setupBindings()
      viewModel.didSetViewModel()
    }
  }
  
  @IBOutlet weak var optionsButton: UIButton!
  @IBOutlet private var titleLabel: UILabel!
  
  private func setupView() {
    contentView.backgroundColor = .systemBackground
    contentView.layer.masksToBounds = true
    
    titleLabel.text = viewModel.title
    titleLabel.textColor = .label
    titleLabel.numberOfLines = 1
    
    setupOptionsMenu()
  }
  
  
  private func setupBindings() {
    viewModel.$currentlySelectedOption
      .receive(on: RunLoop.main)
      .dropFirst()
      .sink(receiveValue: { [weak self] optionTitle in
        guard let self = self else { return }
        self.optionsButton?.setTitle(optionTitle, for: .normal)
      })
      .store(in: &bindings)
  }
  
  private func setupOptionsMenu(){
    optionsButton.layer.cornerRadius = 5
    
    if #available(iOS 14.0, *) {
      let options = viewModel.filter.values?.enumerated().map { (valueIndex, value) -> UIAction in
        UIAction(
          title: value ?? "",
          handler: { [self] (action: UIAction) in
            didSelectOption(action: action, valueIndex: valueIndex)
          }
        )
      }
    
      guard let options = options else { return }
      optionsButton.menu = UIMenu(children: options)
      optionsButton.showsMenuAsPrimaryAction = true
      optionsButton.setTitle(viewModel.currentlySelectedOption, for: .normal)
    } else {
      #warning("TODO: fallback on earlier versions")
    }
  }
  
  private func didSelectOption(action: UIAction, valueIndex: Int) {
      self.optionsButton.setTitle(action.title, for: .normal)
    viewModel.onOptionSelected(valueIndex: valueIndex)
  }
}
