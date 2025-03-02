//
//  MapListViewController.swift
//  MapDownloader
//
//  Created by Viacheslav on 02.03.2025.
//

import UIKit

final class MapListViewController: UIViewController {

    private var regions: [Region] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Download Maps"

        if let path = Bundle.main.url(forResource: "regions", withExtension: "xml"),
           let data = try? Data(contentsOf: path) {
            let parser = RegionParser()
            if let regions = parser.parseXML(data: data) {
                self.regions = regions
                print(regions)
            }
        }
    }
}
