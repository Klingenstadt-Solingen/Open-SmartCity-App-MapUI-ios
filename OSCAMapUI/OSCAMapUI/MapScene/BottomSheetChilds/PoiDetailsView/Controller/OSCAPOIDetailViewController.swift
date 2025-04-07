//
//  OSCAPOIDetailViewController.swift
//  OSCAMapUI
//
//  Created by Mammut Nithammer on 25.06.22.
//  Reviewed by Stephan Breidenbach on 15.08.22
//  Copyright © 2020 Stadt Solingen. All rights reserved.
//

import Combine
import OSCAEssentials
import OSCAMap
import UIKit

extension OSCAMapUI {
  open class ViewController: UIViewController {}
} // end extension public struct OSCAMapUI

// MARK: - OSCAPOIDetailViewController

public final class OSCAPOIDetailViewController: BottomSheetController, Alertable {
  // MARK: Public

  public var portraitSize: CGSize = .zero

  override public var bottomSheetPreferredSize: CGSize {
    portraitSize
  } // end override public var bottomSheetPreferredSize
  
  public override var bottomSheetPreferredLandscapeFrame: CGRect {
    CGRect(
      origin: CGPoint(x: 10, y: 10),
      size: CGSize(width: max(UIScreen.main.bounds.width, UIScreen.main.bounds.height) * 0.35,
                   height: self.view.bounds.maxY))
  }

  override public var bottomSheetMiddleStickyPoints: [CGFloat] {
    switch initialState {
    case .contracted:
      return [74]
    case .expanded:
      return [view.frame.maxY]
    } // end switch case
  } // end override public var bottomSheetMiddleStickyPoints

  override public var bottomSheetBounceOffset: CGFloat {
    20
  } // end override public var bottomSheetBounceOffset

  override public func viewDidLoad() {
    super.viewDidLoad()

    portraitSize = CGSize(
      width: min(UIScreen.main.bounds.width, UIScreen.main.bounds.height),
      height: tableView.frame.maxY + topView.frame.maxY
    )
    
    bind(to: viewModel)
    setupViews()
    setupCollectionView()
    configureDataSource()
    configureImageDataSource()
  } // end override public func viewDidLoad

  override public func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    showDetails()
    
    if self.traitCollection.userInterfaceStyle == .dark {
      closeButton.tintColor = .white
    } else {
      closeButton.tintColor = .gray
    }
  } // end override public func viewWillApear

  public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    coordinator.animate { _ in
      self.updatePreferredFrameIfNeeded(animated: true)
      let corners: CACornerMask = size.width < size.height
        ? [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        : [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
      self.view.layer.maskedCorners = corners
    }
  }
  
  public func showDetails() {
    viewModel.showDetails()
  } // end public func showDetails of poi with category

  // MARK: Internal

  // BottomSheet config
  enum InitialState {
    case contracted
    case expanded
  } // end enum InitialState

  // MARK: - IBOutlets

  @IBOutlet var titleLabel: UILabel!
  @IBOutlet var categoryLabel: UILabel!
  @IBOutlet var distanceLabel: UILabel!
  @IBOutlet var routeButton: UIButton!
  @IBOutlet var menuButton: UIButton!
  @IBOutlet var phoneButton: UIButton!
  @IBOutlet var shareButton: UIButton!
  @IBOutlet var topView: UIView!
  @IBOutlet var tableView: UITableView!
  @IBOutlet var closeButton: UIButton!
  @IBOutlet var collectionView: UICollectionView!
  @IBOutlet var collectionViewHeight: NSLayoutConstraint!
  var viewModel: OSCAPOIDetailViewModel!

  let imageDataCache = NSCache<NSString, NSData>()

  var initialState: InitialState = .contracted

  var initialPointOffset: CGFloat {
    switch initialState {
    case .contracted:
      return topView.frame.height
    case .expanded:
      return bottomSheetPreferredSize.height
    } // end switch case
  } // end initialPointOffset

  @objc func keyboardWillShow(_ notification: Notification) {
    if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
      let keyboardRectangle = keyboardFrame.cgRectValue
      keyboardHeight = keyboardRectangle.minY
    }
  } // end @objc func keyboardWillShow

  func setupViews() {
    self.view.layer.masksToBounds = true
    self.view.layer.cornerRadius = self.viewModel.dependencies.uiModuleConf.cornerRadius
    let corners: CACornerMask = self.isPortrait
      ? [.layerMinXMinYCorner, .layerMaxXMinYCorner]
      : [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
    self.view.layer.maskedCorners = corners
    
    routeButton.layer.cornerRadius = OSCAMapUI.configuration.cornerRadius
    routeButton.backgroundColor = OSCAMapUI.configuration.colorConfig.primaryColor
    routeButton.titleLabel?.textColor = OSCAMapUI.configuration.colorConfig.whiteColor
    
    setupActionButton(menuButton)
    setupActionButton(phoneButton)
    setupActionButton(shareButton)
    
    closeButton.layer.cornerRadius = .infinity
    
    self.searchSeparatorView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dragViewTapped)))
  } // end func setupViews
  

  private func setupActionButton(_ button: UIButton){
    button.layer.cornerRadius = OSCAMapUI.configuration.cornerRadius
    button.tintColor = OSCAMapUI.configuration.colorConfig.primaryColor
  }

  @objc func dragViewTapped() {
    self.switchExpansionState()
  }
  
  override public func getNextExpansionState() -> BottomSheetController.ExpansionState {
    // Not allowing contraction as this closes the details bottom sheet
    switch self.expansionState {
      case .middle: return .expanded
      case .expanded: return .middle
      default: return .middle
    }
  }

  @IBAction func closeButtonTouched(_: UIButton) {
    viewModel.actions.closeDetailSheet()
  } // end @IBAciton func closeButtonTouched

  @IBAction func quickActionButtonTouched(_ sender: UIButton) {
    switch sender.tag {
    case 0: // website
      if let websitesGroup = viewModel.details.first(where: { $0.type == .url }) {
        showWebsiteSelection(urlStrings: websitesGroup.values)
      }
    case 1: // menu
      viewModel.actions.openMenu(URL(string: "https://solingen.de")!)
    case 2: // phone
      if let telGroup = viewModel.details.first(where: { $0.type == .tel }) {
        showPhoneNumberSelection(numbers: telGroup.values)
      }
    case 3: // share
//      viewModel.actions.share(viewModel.poi)
      let shareItems = [
        "\(self.viewModel.poiShareText)\n\n" +
        "\(self.viewModel.poi.name ?? "")\n" +
        "\(self.viewModel.poi.address ?? "")\n" +
        "\(self.viewModel.poi.zip ?? "") " +
        "\(self.viewModel.poi.city ?? "")"]
      self.showActivity(activityItems: shareItems,
                        excludedActivityTypes: [.airDrop])
    default:
      return
    }
  } // end @IBAciton func quickActionButtonTouched

  @IBAction func directionsButtonTouched(_: UIButton) {
    viewModel.actions.openDirections(viewModel.poi)
  }

  // MARK: Private

  private typealias DataSource = UITableViewDiffableDataSource<OSCAPOIDetailViewModel.Section, OSCAPoiDetailGroup>
  private typealias Snapshot = NSDiffableDataSourceSnapshot<OSCAPOIDetailViewModel.Section, OSCAPoiDetailGroup>
  private typealias ImageDataSource = UICollectionViewDiffableDataSource<OSCAPOIDetailViewModel.Section, OSCAPoi.Image>
  private typealias ImageSnapshot = NSDiffableDataSourceSnapshot<OSCAPOIDetailViewModel.Section, OSCAPoi.Image>

  private var keyboardHeight: CGFloat = 0.0

  private var bindings = Set<AnyCancellable>()
  private var dataSource: DataSource!
  private var imageDataSource: ImageDataSource!
  
  var originalOffset: CGPoint = .zero

  @IBOutlet private var searchSeparatorView: UIView! {
    didSet {
      searchSeparatorView.layer.cornerRadius = searchSeparatorView.frame.height / 2
    }
  } // end private var searchSeparatorView
  
  
  private let imageCollectionDelegate = OSCAPOIImageCollectionDelegate()
  
  private func setupCollectionView() {
    imageCollectionDelegate.didSelectImage = { image in
      self.viewModel.actions.showFullscreenImage(image)
    }
    collectionView.delegate = imageCollectionDelegate
    originalOffset = collectionView.contentOffset
    collectionView.collectionViewLayout = createLayout()
    collectionView.isDirectionalLockEnabled = true
  } // end private func setupCollectionView

  private func createLayout() -> UICollectionViewLayout {
    // We have two column styles
    // Style 1: 'Full'
    // A full height image
    // Style 2: 'Pair'
    // Two images above each other

    // Style 1: 'Full'
    let fullSizeImage =
      NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(
        widthDimension: .absolute(100),
        heightDimension: .absolute(100)
      ))
    fullSizeImage.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 2)

    // Style 2: 'Pair
    let pairImage =
      NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(
        widthDimension: .absolute(50),
        heightDimension: .absolute(50)
      ))
    pairImage.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 2)
    let pairGroup = NSCollectionLayoutGroup.vertical(
      layoutSize: NSCollectionLayoutSize(widthDimension: .absolute(50), heightDimension: .absolute(100)),
      subitem: pairImage,
      count: 2
    )

    // Wrap both styles to one group
    let nestedGroup = NSCollectionLayoutGroup.horizontal(
      layoutSize: NSCollectionLayoutSize(
        widthDimension: .fractionalWidth(1.0),
        heightDimension: .fractionalWidth(1.0)
      ),
      subitems: [fullSizeImage, pairGroup]
    )

    // Put all into a section
    let section = NSCollectionLayoutSection(group: nestedGroup)
    section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)

    let config = UICollectionViewCompositionalLayoutConfiguration()
    config.scrollDirection = .horizontal
    let layout = UICollectionViewCompositionalLayout(section: section, configuration: config)

    return layout
  } // end private func createLayout

  private func updateSections(_ items: [OSCAPoiDetailGroup]) {
    var snapshot = Snapshot()
    snapshot.appendSections([.details])
    snapshot.appendItems(items)
    dataSource.apply(snapshot, animatingDifferences: true)
  } // end private func updateSections

  private func setupButtons() {
    if !viewModel.hasPhone {
      phoneButton.removeFromSuperview()
    }

    if viewModel.hasMenu {
      let title = NSAttributedString(
        string: "Speisekarte",
        attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 10)]
      )
      menuButton.setAttributedTitle(title, for: .normal)
      menuButton.setImage(UIImage(systemName: "book"), for: .normal)
      menuButton.tag = 1
      return
    }

    if viewModel.hasWebsite {
      let title = NSAttributedString(
        string: "Webseite",
        attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 10)]
      )
      menuButton.setAttributedTitle(title, for: .normal)
      menuButton.setImage(UIImage(systemName: "safari"), for: .normal)
      menuButton.tag = 0
      return
    }

    menuButton.removeFromSuperview()
  }
  
  private func updateSections(_ images: [OSCAPoi.Image]) {
    var snapshot = ImageSnapshot()
    snapshot.appendSections([.image])
    snapshot.appendItems(images)
    imageDataSource.apply(snapshot, animatingDifferences: true)
  } // end private func updateSections

  private func bind(to viewModel: OSCAPOIDetailViewModel) {
    viewModel.$title
      .receive(on: RunLoop.main)
      .dropFirst()
      .sink(receiveValue: { [weak self] value in
        guard let self = self else { return }
        self.titleLabel.text = value
      })
      .store(in: &bindings)

    viewModel.$category
      .receive(on: RunLoop.main)
      .dropFirst()
      .sink(receiveValue: { [weak self] value in
        guard let self = self else { return }
        self.categoryLabel.text = value
      })
      .store(in: &bindings)

    viewModel.$distance
      .receive(on: RunLoop.main)
      .dropFirst()
      .sink(receiveValue: { [weak self] value in
        guard let self = self else { return }
        self.distanceLabel.text = value.isEmpty ? "" : "- \(value)"
      })
      .store(in: &bindings)

    viewModel.$details
      .receive(on: RunLoop.main)
      .dropFirst()
      .sink(receiveValue: { [weak self] value in
        guard let self = self else { return }
        self.updateSections(value.compactMap { $0 })
      })
      .store(in: &bindings)

    viewModel.$images
      .receive(on: RunLoop.main)
      .dropFirst()
      .sink(receiveValue: { [weak self] value in
        guard let self = self else { return }
        self.updateSections(value)
      })
      .store(in: &bindings)

    viewModel.$hasImages
      .receive(on: RunLoop.main)
      .dropFirst()
      .sink(receiveValue: { [weak self] hasImages in
        guard let self = self else { return }
        let collectionHeight = hasImages ? CGFloat(100) : CGFloat(0)
        self.collectionViewHeight.constant = collectionHeight
        self.collectionView.contentSize =  CGSize(width: self.collectionView.contentSize.width, height: collectionHeight)
      })
      .store(in: &bindings)

    viewModel.$hasWebsite
      .receive(on: RunLoop.main)
      .dropFirst()
      .sink(receiveValue: { [weak self] _ in
        guard let self = self else { return }
        self.setupButtons()
      })
      .store(in: &bindings)

    viewModel.$hasMenu
      .receive(on: RunLoop.main)
      .dropFirst()
      .sink(receiveValue: { [weak self] _ in
        guard let self = self else { return }
        self.setupButtons()
      })
      .store(in: &bindings)

    viewModel.$hasPhone
      .receive(on: RunLoop.main)
      .dropFirst()
      .sink(receiveValue: { [weak self] _ in
        guard let self = self else { return }
        self.setupButtons()
      })
      .store(in: &bindings)
  } // end private func bind

  private func sanitizePhoneNumer(_ raw: String) -> String {
    raw.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
  }

  private func showPhoneNumberSelection(numbers: [String]) {
    if numbers.count == 1, let number = numbers.first {
      self.viewModel.actions.initPhoneCall(self.sanitizePhoneNumer(number))
      
    } else {
      let alert = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
      
      for number in numbers {
        let action = UIAlertAction(title: number, style: .default) { action in
          self.viewModel.actions.initPhoneCall(self.sanitizePhoneNumer(action.title ?? ""))
        }
        alert.addAction(action)
      }

      alert.addAction(UIAlertAction(
        title: NSLocalizedString(
          "CANCEL_ACTION",
          bundle: OSCAMapUI.bundle,
          comment: "CANCEL_ACTION"),
        style: .cancel
      ))

      present(alert, animated: true)
    }
  }

  private func showWebsiteSelection(urlStrings: [String]) {
    if urlStrings.count == 1,
       let http = urlStrings.first,
       let url = URL(string: http) {
      self.viewModel.actions.openWebsite(url)
      
    } else {
      let alert = UIAlertController(title: nil, message: nil, preferredStyle: .alert)

      for urlString in urlStrings {
        let action = UIAlertAction(title: urlString, style: .default) { action in
          if let url = URL(string: action.title ?? "") {
            self.viewModel.actions.openWebsite(url)
          }
        }
        alert.addAction(action)
      }

      alert.addAction(UIAlertAction(
        title: NSLocalizedString(
          "CANCEL_ACTION",
          bundle: OSCAMapUI.bundle,
          comment: "CANCEL_ACTION"),
        style: .cancel
      ))

      present(alert, animated: true)
    }
  }

  private func showEmailSelection(addresses: [String]) {
    if addresses.count == 1, let address = addresses.first {
      self.viewModel.actions.sentEmail(address)
      
    } else {
      let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

      for address in addresses {
        let action = UIAlertAction(title: address, style: .default) { action in
          self.viewModel.actions.sentEmail(action.title ?? "")
        }
        alert.addAction(action)
      }

      alert.addAction(UIAlertAction(
        title: NSLocalizedString(
          "CANCEL_ACTION",
          bundle: OSCAMapUI.bundle,
          comment: "CANCEL_ACTION"),
        style: .cancel
      ))

      present(alert, animated: true)
    }
  }
} // end public final class PoiDetailsViewController

extension OSCAPOIDetailViewController {
  private func configureDataSource() {
    dataSource = DataSource(
      tableView: tableView,
      cellProvider: { tableView, indexPath, detail -> UITableViewCell in
        switch detail.type {
        case .text:
          guard let cell = tableView.dequeueReusableCell(
            withIdentifier: OSCAPOIDetailTextTableViewCell.identifier,
            for: indexPath
          ) as? OSCAPOIDetailTextTableViewCell
          else { return UITableViewCell() }
          cell.viewModel = OSCAPOIDetailTextCellViewModel(detail: detail)
          return cell
        case .html:
          guard let cell = tableView.dequeueReusableCell(
            withIdentifier: OSCAPOIDetailTextTableViewCell.identifier,
            for: indexPath
          ) as? OSCAPOIDetailTextTableViewCell
          else { return UITableViewCell() }
          cell.viewModel = OSCAPOIDetailTextCellViewModel(detail: detail)
          return cell
        case .tel:
          guard let cell = tableView.dequeueReusableCell(
            withIdentifier: OSCAPOIDetailHighlightedTableViewCell.identifier,
            for: indexPath
          ) as? OSCAPOIDetailHighlightedTableViewCell
          else { return UITableViewCell() }
          cell.viewModel = OSCAPOIDetailHighlightedViewModel(detail: detail)
          return cell
        case .url:
          guard let cell = tableView.dequeueReusableCell(
            withIdentifier: OSCAPOIDetailHighlightedTableViewCell.identifier,
            for: indexPath
          ) as? OSCAPOIDetailHighlightedTableViewCell
          else { return UITableViewCell() }
          cell.viewModel = OSCAPOIDetailHighlightedViewModel(detail: detail)
          return cell
        case .mail:
          guard let cell = tableView.dequeueReusableCell(
            withIdentifier: OSCAPOIDetailHighlightedTableViewCell.identifier,
            for: indexPath
          ) as? OSCAPOIDetailHighlightedTableViewCell
          else { return UITableViewCell() }
          cell.viewModel = OSCAPOIDetailHighlightedViewModel(detail: detail)
          return cell
        }
      }
    )
  } // end private func configureDataSource

  private func configureImageDataSource() {
    imageDataSource = ImageDataSource(
      collectionView: collectionView,
      cellProvider: { collectionView, indexPath, image in
        guard let cell = collectionView.dequeueReusableCell(
          withReuseIdentifier: OSCAPOIDetailImageCollectionViewCell.identifier,
          for: indexPath
        ) as? OSCAPOIDetailImageCollectionViewCell
        else {
          return UICollectionViewCell()
        }

        cell.viewModel = OSCAPOIDetailImageCellViewModel(
          imageCache: self.imageDataCache,
          image: image,
          dataModule: self.viewModel.dataModule,
          at: indexPath.row
        )

        return cell
      }
    )
  } // end private func configureDataSource
} // end extension public final class PoiDetailsViewController

/*
extension OSCAPOIDetailViewController: UICollectionViewDelegate {
  public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    if let cell = collectionView.cellForItem(at: indexPath) as? OSCAPOIDetailImageCollectionViewCell {
      if let image = cell.imageView.image {
        viewModel.actions.showFullscreenImage(image)
      }
    }
  }
    
}
*/
// MARK: UITableViewDelegate

extension OSCAPOIDetailViewController: UITableViewDelegate {
  public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let item = viewModel.details[indexPath.row]

    switch item.type {
    case .html, .text:
      break
    case .tel:
      showPhoneNumberSelection(numbers: item.values)
    case .url:
      showWebsiteSelection(urlStrings: item.values)
    case .mail:
      showEmailSelection(addresses: item.values)
    }
  }

  public func tableView(_: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
    let item = viewModel.details[indexPath.row]

    switch item.type {
    case .html, .text:
      return nil
    case .mail, .tel, .url:
      return indexPath
    }
  }
}

// MARK: StoryboardInstantiable

extension OSCAPOIDetailViewController: StoryboardInstantiable {
  /// function call: var vc = PoiDetailsViewController.create(viewModel)
  public static func create(with viewModel: OSCAPOIDetailViewModel) -> OSCAPOIDetailViewController {
    #if DEBUG
      print("\(String(describing: self)): \(#function)")
    #endif
    var bundle: Bundle
    #if SWIFT_PACKAGE
      bundle = OSCAMapUI.bundle
    #else
      bundle = Bundle(for: Self.self)
    #endif
    let viewController = Self.instantiateViewController(bundle)
    viewController.viewModel = viewModel
    return viewController
  } // end public static func create
} // end extension final class PoiDetailsViewController

extension OSCAPOIDetailViewController {
  
  public class OSCAPOIImageCollectionDelegate: NSObject, UICollectionViewDelegate {
    var didSelectImage: ((UIImage) -> Void)? = nil
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
      if scrollView.contentOffset.y > 0 || scrollView.contentOffset.y < 0 {
        scrollView.contentOffset.y = 0
      }
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
      if let cell = collectionView.cellForItem(at: indexPath) as? OSCAPOIDetailImageCollectionViewCell {
        if let image = cell.imageView.image {
          self.didSelectImage?(image)
        }
      }
    }
  }
}
