//
//  ViewController.swift
//  MapDownloader
//
//  Created by Viacheslav on 02.03.2025.
//

import UIKit

final class MapListFlowController: UIViewController {

    private let mapsController: MapsController = .init()
    private lazy var mapListViewController: MapListViewController = createMapListViewController()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Download Maps"
        addMapListView()
    }
}

private extension MapListFlowController {

    func addMapListView() {
        addChild(mapListViewController)
        view.addSubview(mapListViewController.view)
        mapListViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mapListViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapListViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            mapListViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapListViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        mapListViewController.didMove(toParent: self)
    }

    func createMapListViewController() -> MapListViewController {
        MapListViewController(region: nil, mapsController: mapsController) { [weak self] region in
            self?.showSubregions(of: region)
        }
    }

    func showSubregions(of region: Region) {
        let mapListViewController = MapListViewController(
            region: region,
            mapsController: mapsController
        ) { [weak self] region in
            self?.showSubregions(of: region)
        }
        mapListViewController.title = region.name.capitalized
        navigationController?.pushViewController(mapListViewController, animated: true)
    }
}
