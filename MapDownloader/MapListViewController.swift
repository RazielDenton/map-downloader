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

    private let region: Region?
    private weak var mapsController: MapsController?
    private let tableView: UITableView = .init()
    private lazy var dataSource: UITableViewDiffableDataSource<Section, Region> = makeDataSource()

    private var onCellTap: ((Region) -> Void)?

    // MARK: - LifeCycle

    init(region: Region?, mapsController: MapsController?, onCellTap: ((Region) -> Void)?) {
        self.region = region
        self.mapsController = mapsController
        self.onCellTap = onCellTap

        super.init(nibName: nil, bundle: nil)

        title = region == nil ? "Download Maps" : region?.name.capitalized
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupTableView()

        if let region {
            update(with: Region(name: "Regions", subregions: region.subregions))
        } else {
            loadMaps()
        }
    }
}

// MARK: - Private

private extension MapListViewController {

    func setupTableView() {
        tableView.estimatedRowHeight = .tableViewRowHeight
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(MapRegionCell.self, forCellReuseIdentifier: MapRegionCell.reuseIdentifier)
        tableView.dataSource = dataSource
        tableView.delegate = self

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
            cellProvider: { [weak self] tableView, indexPath, region in
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: MapRegionCell.reuseIdentifier,
                    for: indexPath
                ) as? MapRegionCell
                cell?.configure(with: region, onButtonTap: { [weak self] in
                    Task {
                        await self?.mapsController?.toggleDownload(for: region)
                    }
                })

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

// MARK: - UITableViewDelegate

extension MapListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let region = dataSource.itemIdentifier(for: indexPath), !region.subregions.isEmpty else { return }

        onCellTap?(region)
    }
}
