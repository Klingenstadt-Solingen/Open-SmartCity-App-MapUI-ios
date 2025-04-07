//
//  UIViewController+BottomSheet.swift
//  OSCAMapUI
//
//  Created by Stephan Breidenbach on 08.09.22.
//  Copyright © 2020 Stadt Solingen. All rights reserved.
//

import UIKit

extension UIViewController {
  public func addBottomSheet(
    _ bottomSheet: BottomSheetController,
    initialStickyPointOffset: CGFloat,
    animated: Bool,
    completion: ((Bool) -> Void)? = nil,
    onBottomSheetMoved: ((CGFloat) -> Void)? = nil
  ) {
    assert(!(self is UITableViewController), "It's not possible to attach a BottomSheet to a UITableViewController.")
    addChild(bottomSheet)
    bottomSheet.setup(superview: view, initialStickyPointOffset: initialStickyPointOffset, onBottomSheetMoved: onBottomSheetMoved)
    if animated {
      bottomSheet.bottomSheetAnimate(
        action: .add,
        withDuration: 0.3,
        animations: { [weak self] in
          self?.view.layoutIfNeeded()
        },
        completion: { didComplete in
          bottomSheet.didMove(toParent: self)
          completion?(didComplete)
        } // end closure
      ) // end bottomShetAnimate
    } else {
      view.layoutIfNeeded()
      bottomSheet.didMove(toParent: self)
      completion?(true)
    } // end if
  } // end open func addBottomSheet

  public func removeBottomSheet(
    _ bottomSheet: BottomSheetController,
    animated: Bool,
    completion: ((Bool) -> Void)? = nil
  ) {
    bottomSheet.hide()
    if animated {
      bottomSheet.bottomSheetAnimate(
        action: .remove,
        withDuration: 0.3,
        animations: { [weak self] in
          self?.view.layoutIfNeeded()
        },
        completion: { didComplete in
          bottomSheet.willMove(toParent: nil)
          NSLayoutConstraint.deactivate(bottomSheet.view.constraints)
          bottomSheet.removeFromParent()
          completion?(didComplete)
        }
      ) // end bottomSheetAnimate
    } else {
      view.layoutIfNeeded()
      bottomSheet.willMove(toParent: nil)
      bottomSheet.view.removeFromSuperview()
      bottomSheet.removeFromParent()
      completion?(true)
    } // end if
  } // end open func removeBottomSheet
}// end extension class UIViewController
