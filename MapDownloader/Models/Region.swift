//
//  Region.swift
//  MapDownloader
//
//  Created by Viacheslav on 02.03.2025.
//

import Foundation

final class Region: Hashable, Comparable {

    let name: String
    var subregions: [Region]
    let downloadPrefix: String
    var mapDownloadStatus: MapDownloadStatus {
        didSet {
            statusHandler?(mapDownloadStatus)
        }
    }
    var statusHandler: ((MapDownloadStatus) -> Void)?

    init(
        name: String,
        downloadPrefix: String = "",
        subregions: [Region] = [],
        mapDownloadStatus: MapDownloadStatus = .available
    ) {
        self.name = name
        self.downloadPrefix = downloadPrefix
        self.subregions = subregions
        self.mapDownloadStatus = mapDownloadStatus
    }
}

// MARK: - Types

extension Region {

    enum MapDownloadStatus {
        case available
        case pending
        case downloading(Double)
        case downloaded
    }
}

// MARK: - Protocols

extension Region {

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }

    // MARK: - Comparable

    static func == (lhs: Region, rhs: Region) -> Bool {
        lhs.name == rhs.name
    }

    static func < (lhs: Region, rhs: Region) -> Bool {
        lhs.name < rhs.name
    }
}
