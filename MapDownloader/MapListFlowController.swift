//
//  ViewController.swift
//  MapDownloader
//
//  Created by Viacheslav on 02.03.2025.
//

import UIKit

final class MapListFlowController: UIViewController {

    private let childNavigationController: UINavigationController = .init()
    private let mapsController: MapsController = .init()
    private lazy var mapListViewController: MapListViewController = createMapListViewController()

    override func viewDidLoad() {
        super.viewDidLoad()

        addChildNavigationController()
        childNavigationController.setViewControllers([mapListViewController], animated: false)
        setupNavigationBar()
    }
}

private extension MapListFlowController {

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
        childNavigationController.pushViewController(mapListViewController, animated: true)
    }

    func addChildNavigationController() {
        addChild(childNavigationController)
        childNavigationController.view.frame = view.frame
        view.addSubview(childNavigationController.view)
        childNavigationController.didMove(toParent: self)
    }

    func setupNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .navigationBar
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]

        childNavigationController.navigationBar.tintColor = .white
        childNavigationController.navigationBar.standardAppearance = appearance
        childNavigationController.navigationBar.compactAppearance = appearance
        childNavigationController.navigationBar.scrollEdgeAppearance = appearance
    }
}
