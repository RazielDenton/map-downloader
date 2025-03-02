//
//  ViewController.swift
//  MapDownloader
//
//  Created by Viacheslav on 02.03.2025.
//

import UIKit

final class MapListFlowController: UIViewController {

    private let childNavigationController: UINavigationController = .init()
    private let mapListViewController: MapListViewController = .init()

    override func viewDidLoad() {
        super.viewDidLoad()

        addChildNavigationController()
        childNavigationController.setViewControllers([mapListViewController], animated: false)
        setupNavigationBar()
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

        childNavigationController.navigationBar.standardAppearance = appearance
        childNavigationController.navigationBar.compactAppearance = appearance
        childNavigationController.navigationBar.scrollEdgeAppearance = appearance
    }
}
