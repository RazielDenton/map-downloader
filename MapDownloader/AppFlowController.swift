//
//  AppFlowController.swift
//  MapDownloader
//
//  Created by Viacheslav on 30.03.2025.
//

import UIKit

final class AppFlowController: UINavigationController {

    private let startViewController: UIViewController = .init()

    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavigationBar()
        setupStartViewController()
        setViewControllers([startViewController], animated: false)
    }
}

private extension AppFlowController {

    func setupStartViewController() {
        startViewController.view.backgroundColor = .systemBackground

        let showMapListButton: UIButton = .init(type: .system)
        showMapListButton.setTitle("Show the map list", for: .normal)
        showMapListButton.addAction(UIAction(handler: { [weak self] _ in
            self?.showMapListScreen()
        }), for: .touchUpInside)

        startViewController.view.addSubview(showMapListButton)
        showMapListButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            showMapListButton.centerXAnchor.constraint(equalTo: startViewController.view.centerXAnchor),
            showMapListButton.centerYAnchor.constraint(equalTo: startViewController.view.centerYAnchor)
        ])
    }

    func showMapListScreen() {
        let mapListFlowController = MapListFlowController()
        pushViewController(mapListFlowController, animated: true)
    }

    func setupNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .navigationBar
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]

        navigationBar.tintColor = .white
        navigationBar.standardAppearance = appearance
        navigationBar.compactAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
    }
}
