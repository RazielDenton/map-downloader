//
//  Region.swift
//  MapDownloader
//
//  Created by Viacheslav on 02.03.2025.
//

struct Region: Hashable, Comparable {

    let name: String
    var subregions: [Region] = []
}

extension Region {

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }

    // MARK: - Comparable

    static func < (lhs: Region, rhs: Region) -> Bool {
        lhs.name < rhs.name
    }
}
