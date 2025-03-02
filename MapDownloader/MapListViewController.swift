//
//  MapListViewController.swift
//  MapDownloader
//
//  Created by Viacheslav on 02.03.2025.
//

import UIKit

private extension CGFloat {
    static let tableViewRowHeight: CGFloat = 48
}

final class MapListViewController: UIViewController {

    private let tableView: UITableView = .init()
    private lazy var dataSource = makeDataSource()

    // MARK: - LifeCycle

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Download Maps"

        setupTableView()
        loadMaps()
    }
}

// MARK: - Private

private extension MapListViewController {

    func setupTableView() {
        tableView.estimatedRowHeight = .tableViewRowHeight
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(MapRegionCell.self, forCellReuseIdentifier: MapRegionCell.reuseIdentifier)
        tableView.dataSource = dataSource

        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    func makeDataSource() -> UITableViewDiffableDataSource<Section, Region> {
        RegionDiffableDataSource(
            tableView: tableView,
            cellProvider: { tableView, indexPath, region in
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: MapRegionCell.reuseIdentifier,
                    for: indexPath
                ) as? MapRegionCell
                cell?.configure(with: region)

                return cell
            }
        )
    }

    func loadMaps() {
        guard
            let path = Bundle.main.url(forResource: "regions", withExtension: "xml"),
            let data = try? Data(contentsOf: path)
        else { return }

        let parser = RegionParser()
        if let regions = parser.parseXML(data: data), let continent = regions.first {
            let filteredRegions: [Region] = continent.subregions.sorted(by: <)
            update(with: Region(name: continent.name, subregions: filteredRegions))
        }
    }

    func update(with continent: Region, animate: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Region>()
        let europeContinentSection = Section(continent: continent.name)
        snapshot.appendSections([europeContinentSection])
        snapshot.appendItems(continent.subregions, toSection: europeContinentSection)
        dataSource.apply(snapshot, animatingDifferences: animate)
    }
}
