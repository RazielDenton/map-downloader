//
//  ViewController.swift
//  MapDownloader
//
//  Created by Viacheslav on 02.03.2025.
//

import UIKit

final class MapListFlowController: UIViewController {

    private let storageBannerView: StorageBannerView = .init()
    private lazy var mapListViewController: MapListViewController = createMapListViewController()

    private let mapsController: MapsController = .init()
    private let diskSpaceService: DiskSpaceService = .init()

    private var didBecomeActiveObserver: NSObjectProtocol?

    // MARK: - LifeCycle

    deinit {
        if let didBecomeActiveObserver {
            NotificationCenter.default.removeObserver(didBecomeActiveObserver)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = String(localized: "Download Maps")

        setupViews()
        setupStorageInfoUpdates()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let coordinator = transitionCoordinator {
            storageBannerView.layoutIfNeeded()
            coordinator.animate { _ in
                self.updateStorageInfo()
            }
        }
    }
}

// MARK: - Private

private extension MapListFlowController {

    func setupViews() {
        addChild(mapListViewController)

        let contentStackView = UIStackView(arrangedSubviews: [storageBannerView, mapListViewController.view])
        contentStackView.axis = .vertical

        view.addSubview(contentStackView)
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentStackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            contentStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
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

    func setupStorageInfoUpdates() {
        Task {
            await mapsController.setOnMapDownloadFinished { [weak self] in
                self?.updateStorageInfo()
            }
        }

        didBecomeActiveObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main
        ) { [weak self] _ in
            self?.updateStorageInfo()
        }
    }

    func updateStorageInfo() {
        DispatchQueue.main.async {
            self.storageBannerView.updateIndicators(
                availableDiskSpace: self.diskSpaceService.availableDiskSpaceString(),
                usageRatio: self.diskSpaceService.usageRatio()
            )
        }
    }
}
