//
//  OSCAMapCategoryViewController.swift
//  OSCAMapUI
//
//  Created by Mammut Nithammer on 24.06.22.
//  Reviewed by Stephan Breidenbach on 14.08.22
//  Copyright © 2020 Stadt Solingen. All rights reserved.
//

import Combine
import OSCAEssentials
import OSCAMap
import UIKit

// MARK: - OSCAMapCategoryViewController

public class OSCAMapCategoryViewController: UIViewController {
  // MARK: Public
  
  override public func viewDidLoad() {
    super.viewDidLoad()
    self.setupViews()
    self.bind(to: viewModel)
    self.viewModel.viewDidLoad()
  } // end override pubic func viewDidLoad

  override public func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    print("VIEW: \(searchBoxContainerView.frame.height)")
    viewModel.viewDidLayoutSubviews()
  } // end override public func viewDidLayoutSubviews

  public override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    let colorConfig = self.viewModel.colorConfig
    self.navigationController?.navigationBar.isHidden = true
    self.navigationController?.setup(
      tintColor: colorConfig.primaryColor,
      titleTextColor: colorConfig.textColor,
      barColor: colorConfig.backgroundColor)
    
    self.delegate?.categorySheet(with: self.viewModel.filteredPois)
  }
  
  private func setupViews() {
    self.extendedLayoutIncludesOpaqueBars = true
    self.navigationItem.title = "Alle Kategorien"
    self.view.backgroundColor = self.viewModel
      .colorConfig.backgroundColor
    self.searchBoxContainerView.backgroundColor = .clear
    self.contentView.backgroundColor = .clear
    self.titleLabel.font = self.viewModel.dependencies.fontConf.bodyHeavy
    self.titleLabel.textColor = self.viewModel
      .colorConfig.whiteColor.darker(componentDelta: 0.5)
    
    let cornerRadius = self.viewModel
      .dependencies.uiModuleConf.cornerRadius
    self.contentStack.layer.cornerRadius = cornerRadius
    self.contentStack.backgroundColor = self.viewModel
      .colorConfig.secondaryBackgroundColor
    self.contentStack
      .addShadow(with: OSCAMapUI.configuration.shadow)
    
    self.setupTableView()
    self.setupCollectionView()
    self.configureSearchDataSource()
    self.configureCategoryDataSource()
  }
  
  public func showDefaultCategories() {
    viewModel.showDefaultCategories()
  } // end public func showDefaultCategories

  // MARK: Internal

  // MARK: - Custom

  var viewModel: OSCAMapCategoryViewModel!

  weak var delegate: OSCAMapCategoryDelegate?
  weak var delegateContainer: OSCAMapContainerViewControllerDelegate?

  // MARK: Private

  private typealias CategoryDataSource = UICollectionViewDiffableDataSource<
    OSCAMapCategoryViewModel.Section,
    OSCAPoiCategory
  >
  private typealias CategorySnapshot = NSDiffableDataSourceSnapshot<OSCAMapCategoryViewModel.Section, OSCAPoiCategory>
  
  private typealias SearchDataSource = UITableViewDiffableDataSource<OSCAMapCategoryViewModel.Section, OSCAPoi>
  private typealias SearchSnapshot = NSDiffableDataSourceSnapshot<OSCAMapCategoryViewModel.Section, OSCAPoi>

  // MARK: - IBOutlets

  @IBOutlet private var searchBoxContainerView: UIView!
  @IBOutlet private var contentStack: UIStackView!
  @IBOutlet private var collectionView: UICollectionView!
  
  @IBOutlet private var tableView: UITableView!
  @IBOutlet private var contentView: UIView!
  @IBOutlet private var titleLabel: UILabel!
  
  private var keyboardHeight: CGFloat = 0.0
  private var categoryDataSource: CategoryDataSource!
  private var searchDataSource: SearchDataSource!
  private var bindings = Set<AnyCancellable>()

  private func bind(to viewModel: OSCAMapCategoryViewModel) {
    viewModel.$categories
      .receive(on: RunLoop.main)
      .dropFirst()
      .sink(receiveValue: { [weak self] categories in
        guard let self = self else { return }
        self.configureCategoryDataSource()
        self.updateCategorySections(categories)
      })
      .store(in: &bindings)
    
    viewModel.$filteredPois
      .receive(on: RunLoop.main)
      .dropFirst()
      .sink(receiveValue: { [weak self] pois in
        guard let `self` = self else { return }
        if self.viewModel.isSearching {
          self.configureSearchDataSource()
          self.updateSearchSections(pois)
        }
        self.delegate?.categorySheet(with: pois)
      })
      .store(in: &bindings)
    
    viewModel.$isSearching
      .receive(on: RunLoop.main)
      .dropFirst()
      .sink(receiveValue: { [weak self] value in
        guard let self = self else { return }
        self.collectionView.isHidden = value
        self.tableView.isHidden = !value
        self.titleLabel.text = value ? "Ergebnisse" : "Kategorien"
      })
      .store(in: &bindings)
  } // end private func bind to view model
} // end public class CategoryViewController

// MARK: - TableView
extension OSCAMapCategoryViewController {
  private func setupTableView() {
    self.tableView.isHidden = true
    self.tableView.alwaysBounceVertical = false
    self.tableView.backgroundColor = .clear
    let cornerRadius = self.viewModel
      .dependencies.uiModuleConf.cornerRadius
    self.tableView.layer.cornerRadius = cornerRadius
    self.tableView.verticalScrollIndicatorInsets = UIEdgeInsets(
      top: cornerRadius,
      left: 0,
      bottom: cornerRadius,
      right: 0)
  }
}

// MARK: - CollectionView

extension OSCAMapCategoryViewController {
  private func updateCategorySections(_ categories: [OSCAPoiCategory]) {
    var categorySnapshot = CategorySnapshot()
    categorySnapshot.appendSections([.category])
    categorySnapshot.appendItems(categories)
    categoryDataSource.apply(categorySnapshot, animatingDifferences: true)
  } // end private func updateSections

  private func updateSearchSections(_ pois: [OSCAPoi]) {
    var searchSnapshot = SearchSnapshot()
    searchSnapshot.appendSections([.poi])
    searchSnapshot.appendItems(pois)
    searchDataSource.apply(searchSnapshot, animatingDifferences: true)
  } // end private func updateSections

  private func setupCollectionView() {
    self.collectionView.isHidden = false
    self.collectionView.delegate = self
    self.collectionView.dataSource = self.categoryDataSource
    self.collectionView.backgroundColor = .clear
    let cornerRadius = self.viewModel
      .dependencies.uiModuleConf.cornerRadius
    self.collectionView.layer.cornerRadius = cornerRadius
    self.collectionView.alwaysBounceVertical = false
    self.collectionView.verticalScrollIndicatorInsets = UIEdgeInsets(
      top: cornerRadius,
      left: 0,
      bottom: cornerRadius,
      right: 0)
    self.collectionView.collectionViewLayout = self.createLayout()
  } // end private func setupCollectionView

  private func createLayout() -> UICollectionViewLayout {
    let count: Int
    if UIDevice.current.userInterfaceIdiom == .phone {
      count = 4
    } else {
      let bounds = UIScreen.main.bounds
      let isPortrait = bounds.width < bounds.height
      count = isPortrait ? 7 : 4
    }
    
    let size = NSCollectionLayoutSize(
      widthDimension: .estimated(40),
      heightDimension: .estimated(60))
    let item = NSCollectionLayoutItem(layoutSize: size)
    
    let groupSize = NSCollectionLayoutSize(
      widthDimension: .fractionalWidth(1),
      heightDimension: .estimated(60))
    let group = NSCollectionLayoutGroup.horizontal(
      layoutSize: groupSize,
      subitem: item,
      count: count)
    group.interItemSpacing = .fixed(8)

    let section = NSCollectionLayoutSection(group: group)
    section.contentInsets = NSDirectionalEdgeInsets(
      top: 16,
      leading: 16,
      bottom: 16,
      trailing: 16)
    section.interGroupSpacing = 16

    return UICollectionViewCompositionalLayout(section: section)
  } // end private func createLayout

  private func configureCategoryDataSource() {
    categoryDataSource = CategoryDataSource(
      collectionView: collectionView,
      cellProvider: { collectionView, indexPath, item -> UICollectionViewCell in
        guard let cell = collectionView.dequeueReusableCell(
          withReuseIdentifier: OSCAMapCategoryCollectionViewCell.identifier,
          for: indexPath
        ) as? OSCAMapCategoryCollectionViewCell
        else { return UICollectionViewCell() }

        cell.viewModel = OSCAMapCategoryCellViewModel(
          category: item,
          dataModule: self.viewModel.dataModule,
          at: indexPath.row
        )

        return cell
      }
    )
  } // end private func configureDataSource

  private func configureSearchDataSource() {
    searchDataSource = SearchDataSource(
      tableView: tableView,
      cellProvider: { tableView, indexPath, item -> UITableViewCell in
        guard let cell = tableView.dequeueReusableCell(
          withIdentifier: OSCAPOISearchResultTableViewCell.identifier,
          for: indexPath
        ) as? OSCAPOISearchResultTableViewCell
        else { return UITableViewCell() }
        cell.viewModel = OSCAPOISearchResultViewModel(
          poi: item,
          dataModule: self.viewModel.dataModule,
          at: indexPath.row
        )

        return cell
      }
    )
  } // end private func configureDataSource
} // end extension public class CategoryViewController

// MARK: UIViewControllerTransitioningDelegate
extension OSCAMapCategoryViewController: UIViewControllerTransitioningDelegate {
  public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    coordinator.animate { _ in
      self.collectionView.collectionViewLayout = self.createLayout()
      self.collectionView.collectionViewLayout.invalidateLayout()
      self.collectionView.reloadData()
    }
  }
}

// MARK: UISearchBarDelegate

extension OSCAMapCategoryViewController: UISearchBarDelegate {
  public func searchBarTextDidBeginEditing(_: UISearchBar) {
    if let stickyPoint = self.delegateContainer?.stickyPoints.last {
      self.delegateContainer?.bottomSheet(moveTo: stickyPoint,
                                          animated: true,
                                          completion: nil)
    }
  }

  public func searchBarSearchButtonClicked(_: UISearchBar) {
    view.endEditing(true)
  }

  public func searchBar(_: UISearchBar, textDidChange searchText: String) {
    if searchText.count > 3 {
      viewModel.search(string: searchText)
    } else if searchText.isEmpty {
      viewModel.endSearching()
    }
  }
} // end extension public class CategoryViewController

// MARK: StoryboardInstantiable

extension OSCAMapCategoryViewController: StoryboardInstantiable {
  /// function call: var vc = OSCAMKMapViewController.create(viewModel)
  public static func create(with viewModel: OSCAMapCategoryViewModel) -> OSCAMapCategoryViewController {
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
} // end extension public class CategoryViewController

// MARK: UICollectionViewDelegate

extension OSCAMapCategoryViewController: UICollectionViewDelegate {
  public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {if let stickyPoint = self.delegateContainer?.stickyPoints[1] {
    self.delegateContainer?.bottomSheet(moveTo: stickyPoint,
                                        animated: true,
                                        completion: nil)
  }
  self.viewModel.didSelectItem(at: indexPath.row)
  }
}

// MARK: UITableViewDelegate

extension OSCAMapCategoryViewController: UITableViewDelegate {
  public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    0
  }
  
  public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    nil
  }
  
  public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
    0
  }
  
  public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
    nil
  }
  
  public func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
    if let stickyPoint = self.delegateContainer?.stickyPoints[1] {
      self.delegateContainer?.bottomSheet(moveTo: stickyPoint,
                                          animated: true,
                                          completion: nil)
    }
    delegate?.categorySheet(didSelect: viewModel.filteredPois[indexPath.row])
  }
}

// MARK: - Deeplinking
extension OSCAMapCategoryViewController {
  func didReceiveDeeplink(with objectId: String?) -> Void {
    self.viewModel.didReceiveDeeplink(with: objectId)
  }
}
