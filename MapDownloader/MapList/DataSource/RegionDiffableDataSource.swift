//
//  RegionDiffableDataSource.swift
//  MapDownloader
//
//  Created by Viacheslav on 02.03.2025.
//

import UIKit

struct Section: Hashable {
    let continent: String
}

final class RegionDiffableDataSource: UITableViewDiffableDataSource<Section, Region> {

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        snapshot().sectionIdentifiers[section].continent.uppercased()
    }
}
