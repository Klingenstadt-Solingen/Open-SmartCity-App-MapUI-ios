//
//  UIScrollView+BottomSheet.swift
//  OSCAMapUI
//
//  Created by Stephan Breidenbach on 08.09.22.
//  Copyright © 2020 Stadt Solingen. All rights reserved.
//

import UIKit

extension UIScrollView {
  public func attach(to bottomSheet: BottomSheetController) {
    bottomSheet.internalScrollView?.detach(from: bottomSheet)
    bottomSheet.internalScrollView = self
    bottomSheet.addInternalScrollViewPanGesture()
  } // end open func attach to bottomSheet

  public func detach(from bottomSheet: BottomSheetController) {
    bottomSheet.removeInternalScrollViewPanGestureRecognizer()
    bottomSheet.internalScrollView = nil
  } // end open func detach from bottomSheet
}// end extension class UIScrollView
