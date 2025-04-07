//
//  OSCAMapCategoryDetailViewController.swift
//  OSCAMapUI
//
//  Created by Ömer Kurutay on 09.01.23.
//

import OSCAEssentials
import OSCAMap
import UIKit
import Combine

public class OSCAMapCategoryDetailViewController: UIViewController {
  
  @IBOutlet private var mainStack: UIStackView!
  @IBOutlet private var messageLabelStack: UIStackView!
  @IBOutlet private var messageLabel: UILabel!
  @IBOutlet private var collectionContainer: UIView!
  @IBOutlet private var collectionView: UICollectionView!
  
  private var fullListButton: UIButton = {
    let image = UIImage(systemName: "arrow.right.circle.fill")
    let button = UIButton(type: .system)
    button.semanticContentAttribute = .forceRightToLeft
    button.setImage(image, for: .normal)
    return button
  }()
  
  private lazy var fullListBarButton: UIBarButtonItem = {
    let view = UIView()
    view.backgroundColor = .clear
    view.addSubview(self.fullListButton)
    
    self.fullListButton.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      self.fullListButton.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      self.fullListButton.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      self.fullListButton.topAnchor.constraint(equalTo: view.topAnchor),
      self.fullListButton.bottomAnchor.constraint(equalTo: view.bottomAnchor)])
    
    let barButton = UIBarButtonItem(customView: view)
    return barButton
  }()
  
  var viewModel: OSCAMapCategoryDetailViewModel!
  
  private var bindings = Set<AnyCancellable>()
  
  weak var delegate: OSCAMapCategoryDelegate?
  weak var delegateContainer: OSCAMapContainerViewControllerDelegate?
  
  private typealias FilterFieldDataSource = UICollectionViewDiffableDataSource<OSCAMapCategoryDetailViewModel.Section, OSCAPoi.Detail.FilterField>
  private typealias FilterFieldSnapshot = NSDiffableDataSourceSnapshot<OSCAMapCategoryDetailViewModel.Section, OSCAPoi.Detail.FilterField>
  
  private var filterFieldDataSource: FilterFieldDataSource!
  
  public override func viewDidLoad() {
    super.viewDidLoad()
    self.setupViews()
    self.setupBindings()
    self.viewModel.viewDidLoad()
  }
  
  public override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.navigationController?.navigationBar.isHidden = false
    let colorConfig = self.viewModel.colorConfig
    self.navigationController?.setup(
      tintColor: colorConfig.primaryColor,
      titleTextColor: colorConfig.textColor,
      barColor: colorConfig.backgroundColor)
    
    self.delegate?.categorySheet(with: self.viewModel.filteredPois)
  }
  
  private func setupViews() {
    self.extendedLayoutIncludesOpaqueBars = true
    
    self.fullListButton.setTitle(
      "Komplette Liste (\(self.viewModel.filteredPois.count))",
      for: .normal)
    self.fullListButton.titleLabel?.font = self.viewModel
      .fontConfig.bodyLight
    self.fullListButton.addTarget(
      self,
      action: #selector(self.fullListButtonTouch),
      for: .touchUpInside)
    
    self.navigationItem.rightBarButtonItem = self.fullListBarButton
    self.navigationItem.title = self.viewModel.screenTitle
    
    self.view.backgroundColor = self.viewModel
      .colorConfig.backgroundColor
    
    self.mainStack.backgroundColor = self.viewModel
      .uiModuleConfig.colorConfig.secondaryBackgroundColor
    self.mainStack.layer.cornerRadius = self.viewModel
      .uiModuleConfig.cornerRadius
    let shadow = self.viewModel.uiModuleConfig.shadow
    self.mainStack.addShadow(with: shadow)
    
    self.messageLabelStack.isHidden = true
    
    self.messageLabel.text = self.viewModel.emptyFilterMessage
    self.messageLabel.font = self.viewModel.dependencies
      .uiModuleConf.fontConfig.titleLight
    self.messageLabel.textColor = self.viewModel
      .colorConfig.whiteColor.darker(componentDelta: 0.3)
    
    self.setupCollectionView()
  }
    
  private func setupBindings() {
    self.viewModel.$filterFields
      .receive(on: RunLoop.main)
      .dropFirst()
      .sink(receiveValue: { [weak self] filterFields in
        guard let `self` = self else { return }
        
        self.messageLabelStack.isHidden = !filterFields.isEmpty
        
        self.configureFilterFieldDataSource()
        self.updateFilterFieldSections(filterFields)
        
      })
      .store(in: &self.bindings)
    
    self.viewModel.$filteredPois
      .receive(on: RunLoop.main)
      .dropFirst()
      .sink(receiveValue: { [weak self] pois in
        guard let `self` = self else { return }
        self.fullListButton.setTitle(
          "Komplette Liste (\(pois.count))",
          for: .normal)
        self.fullListButton.sizeToFit()
        self.delegate?.categorySheet(with: pois)
      })
      .store(in: &self.bindings)
    
    let errorValueHandler: (OSCAMapCategoryDetailViewModel.Error) -> Void = { [weak self] error in
      guard let `self` = self else { return }
      
      switch error {
      case .poiFetch: break
      case .poiCategoryFetch: break
      case .filterFieldFetch:
        self.messageLabelStack.isHidden = !self.viewModel
          .filterFields.isEmpty
      }
    }
    
    let stateValueHandler: (OSCAMapCategoryDetailViewModel.State) -> Void = { [weak self] state in
      guard let _ = self else { return }
      
      switch state {
      case .loading: break
      case .finishedLoading: break
      case let .error(error): errorValueHandler(error)
      }
    }
    
    self.viewModel.$state
      .receive(on: RunLoop.main)
      .dropFirst()
      .sink(receiveValue: stateValueHandler)
      .store(in: &self.bindings)
  }
  
  @objc private func fullListButtonTouch() {
    self.viewModel.fullListButtonTouch()
  }
}

// MARK: StoryboardInstantiable
extension OSCAMapCategoryDetailViewController: StoryboardInstantiable {
  /// function call: var vc = OSCAMapCategoryDetailViewController.create(viewModel)
  public static func create(with viewModel: OSCAMapCategoryDetailViewModel) -> OSCAMapCategoryDetailViewController {
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

// MARK: - CollectionView
extension OSCAMapCategoryDetailViewController {
  private func setupCollectionView() {
    self.collectionContainer.backgroundColor = .clear
    
    self.collectionView.delegate = self
    self.collectionView.backgroundColor = .clear
    self.collectionView.allowsSelection = true
    self.collectionView.allowsMultipleSelection = true
    self.collectionView.alwaysBounceVertical = false
    self.collectionView.collectionViewLayout = self.createLayout()
    self.collectionView.contentInset = UIEdgeInsets(
      top: 0,
      left: 0,
      bottom: 16,
      right: 0)
  }
  
  private func configureFilterFieldDataSource() {
    self.filterFieldDataSource = FilterFieldDataSource(
      collectionView: self.collectionView,
      cellProvider: { (collectionView, indexPath, item) -> UICollectionViewCell in
        guard let cell = collectionView.dequeueReusableCell(
          withReuseIdentifier: OSCAMapCategoryDetailCellView.identifier,
          for: indexPath
        ) as? OSCAMapCategoryDetailCellView
        else { return UICollectionViewCell() }
        
        let cellViewModel = OSCAMapCategoryDetailCellViewModel(
          dataModel: self.viewModel.dataModule,
          filterField: item)
        cell.fill(with: cellViewModel)
        
        return cell
      }
    )
    
    self.filterFieldDataSource.supplementaryViewProvider = { collectionView, kind, indexPath in
      if kind == UICollectionView.elementKindSectionHeader {
        guard let header = collectionView.dequeueReusableSupplementaryView(
          ofKind: UICollectionView.elementKindSectionHeader,
          withReuseIdentifier: OSCAMapCategoryDetailHeaderReusableView.identifier,
          for: indexPath) as? OSCAMapCategoryDetailHeaderReusableView
        else { return UICollectionReusableView() }
        
        guard let filterField = self.viewModel.category.filterFields?[indexPath.section]
        else { return UICollectionReusableView() }
        
        let headerViewModel = OSCAMapCategoryDetailHeaderReusableViewModel(
          dataModel: self.viewModel.dataModule,
          filterField: filterField)
        header.fill(with: headerViewModel)
        
        return header
        
      } else {
        return nil
      }
    }
  }
  
  private func updateFilterFieldSections(_ filterFields: [OSCAPoiCategory.FilterField]) {
    var categorySnapshot = FilterFieldSnapshot()
    
    filterFields.forEach { field in
      guard let title = field.title else { return }
      var filters: [OSCAPoi.Detail.FilterField] = []
      let values = field.values?.compactMap { $0 }
      
      values?.forEach {
        let filter = OSCAPoi.Detail.FilterField.with(
          field: title,
          value: $0)
        filters.append(filter)
      }
      
      let section = OSCAMapCategoryDetailViewModel.Section.filterField(title)
      categorySnapshot.appendSections([section])
      categorySnapshot.appendItems(
        filters,
        toSection: section)
    }
    
    self.filterFieldDataSource.apply(categorySnapshot, animatingDifferences: true)
  }

  private func createLayout() -> UICollectionViewLayout {
    let size = NSCollectionLayoutSize(
      widthDimension: .estimated(50),
      heightDimension: .estimated(50))
    let item = NSCollectionLayoutItem(layoutSize: size)
    
    let groupSize = NSCollectionLayoutSize(
      widthDimension: .fractionalWidth(1),
      heightDimension: .estimated(200))
    let group = NSCollectionLayoutGroup.horizontal(
      layoutSize: groupSize,
      subitem: item,
      count: 3)
    group.interItemSpacing = .fixed(4)
    
    let headerSize = NSCollectionLayoutSize(
      widthDimension: .fractionalWidth(1),
      heightDimension: .absolute(50))
    let header = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: headerSize,
                    elementKind: UICollectionView.elementKindSectionHeader,
                    alignment: .top)
    header.pinToVisibleBounds = true
    
    let section = NSCollectionLayoutSection(group: group)
    section.contentInsets = NSDirectionalEdgeInsets(
      top: 8,
      leading: 16,
      bottom: 8,
      trailing: 16)
    section.interGroupSpacing = 4
    section.boundarySupplementaryItems = [header]
    
    return UICollectionViewCompositionalLayout(section: section)
  }
}

// MARK: UICollectionViewDelegate
extension OSCAMapCategoryDetailViewController: UICollectionViewDelegate {
  public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    if let stickyPoint = self.delegateContainer?.stickyPoints[1] {
      self.delegateContainer?.bottomSheet(moveTo: stickyPoint,
                                          animated: true,
                                          completion: nil)
    }
    guard let indexPaths = collectionView.indexPathsForSelectedItems
    else { return }
    self.viewModel.didSelectFilters(at: indexPaths)
  }
  
  public func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
    if let stickyPoint = self.delegateContainer?.stickyPoints[1] {
      self.delegateContainer?.bottomSheet(moveTo: stickyPoint,
                                          animated: true,
                                          completion: nil)
    }
    guard let indexPaths = collectionView.indexPathsForSelectedItems
    else { return }
    self.viewModel.didSelectFilters(at: indexPaths)
  }
}
