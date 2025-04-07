//
//  OSCAMapCategoryDetailListViewController.swift
//  OSCAMapUI
//
//  Created by Ömer Kurutay on 10.01.23.
//

import OSCAEssentials
import OSCAMap
import UIKit
import Combine

public final class OSCAMapCategoryDetailListViewController: UIViewController {
  
  @IBOutlet private var searchBoxContainerView: UIView!
  @IBOutlet private var tableViewContainer: UIView!
  @IBOutlet private var tableView: UITableView!
  @IBOutlet private var contentView: UIView!
  @IBOutlet private var titleLabel: UILabel!
  
  var viewModel: OSCAMapCategoryDetailListViewModel!
  
  weak var delegate: OSCAMapCategoryDelegate?
  weak var delegateContainer: OSCAMapContainerViewControllerDelegate?
  
  private typealias SearchDataSource = UITableViewDiffableDataSource<OSCAMapCategoryDetailListViewModel.Section, OSCAPoi>
  private typealias SearchSnapshot = NSDiffableDataSourceSnapshot<OSCAMapCategoryDetailListViewModel.Section, OSCAPoi>
  
  private var searchDataSource: SearchDataSource!
  private var bindings = Set<AnyCancellable>()
  
  public override func viewDidLoad() {
    super.viewDidLoad()
    self.setupViews()
    self.setupBindings()
    self.viewModel.viewDidLoad()
  }
  
  public override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    let colorConfig = self.viewModel.colorConfig
    self.navigationController?.navigationBar.isHidden = false
    self.navigationController?.setup(
      tintColor: colorConfig.primaryColor,
      titleTextColor: colorConfig.textColor,
      barColor: colorConfig.backgroundColor)
    
    if self.viewModel.filteredPois.isEmpty {
      self.delegate?.categorySheet(with: self.viewModel.categoryPois)
      
    } else {
      self.delegate?.categorySheet(with: self.viewModel.filteredPois)
    }
    
    self.viewModel.viewWillAppear()
  }
  
  private func setupViews() {
    self.extendedLayoutIncludesOpaqueBars = true
    
    self.navigationItem.title = self.viewModel.screenTitle
    
    self.view.backgroundColor = self.viewModel
      .colorConfig.backgroundColor
    self.searchBoxContainerView.backgroundColor = .clear
    self.contentView.backgroundColor = .clear
    
    self.titleLabel.text = "Ergebnisse"
    self.titleLabel.font = self.viewModel.fontConfig
      .bodyHeavy
    self.titleLabel.textColor = self.viewModel
      .colorConfig.whiteColor.darker(componentDelta: 0.5)
    
    self.setupTableView()
  }
  
  private func setupBindings() {
    self.viewModel.$filteredPois
      .receive(on: RunLoop.main)
      .dropFirst()
      .sink(receiveValue: { [weak self] pois in
        guard let `self` = self else { return }
        self.configureSearchDataSource()
        self.updateSearchSections(pois)
        self.delegate?.categorySheet(with: pois)
      })
      .store(in: &self.bindings)
  }
  
  private func configureSearchDataSource() {
    self.searchDataSource = SearchDataSource(
      tableView: self.tableView,
      cellProvider: { (tableView, indexPath, item) -> UITableViewCell in
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
  }
  
  private func updateSearchSections(_ pois: [OSCAPoi]) {
    var searchSnapshot = SearchSnapshot()
    searchSnapshot.appendSections([.poi])
    searchSnapshot.appendItems(pois)
    self.searchDataSource.apply(searchSnapshot,
                                animatingDifferences: true)
  }
}

// MARK: - TableView
extension OSCAMapCategoryDetailListViewController {
  private func setupTableView() {
    let cornerRadius = self.viewModel.uiModuleConfig
      .cornerRadius
    self.tableViewContainer.layer.cornerRadius = cornerRadius
    self.tableViewContainer.backgroundColor = self.viewModel
      .colorConfig.secondaryBackgroundColor
    self.tableViewContainer
      .addShadow(with: OSCAMapUI.configuration.shadow)
    
    self.tableView.alwaysBounceVertical = false
    self.tableView.backgroundColor = .clear
    self.tableView.layer.cornerRadius = cornerRadius
    self.tableView.verticalScrollIndicatorInsets = UIEdgeInsets(
      top: cornerRadius,
      left: 0,
      bottom: cornerRadius,
      right: 0)
  }
}

// MARK: StoryboardInstantiable
extension OSCAMapCategoryDetailListViewController: StoryboardInstantiable {
  /// function call: var vc = OSCAMapCategoryDetailListViewController.create(viewModel)
  public static func create(with viewModel: OSCAMapCategoryDetailListViewModel) -> OSCAMapCategoryDetailListViewController {
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
  }
}

// MARK: UISearchBarDelegate
extension OSCAMapCategoryDetailListViewController: UISearchBarDelegate {
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
    self.viewModel.searchBar(didChange: searchText)
  }
}

// MARK: UITableViewDelegate
extension OSCAMapCategoryDetailListViewController: UITableViewDelegate {
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
    delegate?.categorySheet(didSelect: self.viewModel.filteredPois[indexPath.row])
  }
}
