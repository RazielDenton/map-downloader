//
//  MapsController.swift
//  MapDownloader
//
//  Created by Viacheslav on 09.03.2025.
//

import Foundation

actor MapsController {

    private let fileDownloader: FileDownloader
    private var regionsToDownload: [Region] = []
    private var currentDownloadTask: Task<Void, any Error>?
    private var isDownloading = false

    init(fileDownloader: FileDownloader = .shared) {
        self.fileDownloader = fileDownloader
    }
}

// MARK: - Public

extension MapsController {

    func toggleDownload(for region: Region) {
        switch region.mapDownloadStatus {
        case .available:
            addToQueue(region)
        case .pending, .downloading:
            cancel(region)
        case .downloaded:
            break
        }
    }

    func loadMaps() async -> Region? {
        let parser = RegionParser()

        guard
            let path = Bundle.main.url(forResource: "regions", withExtension: "xml"),
            let data = try? Data(contentsOf: path),
            let regions = parser.parseXML(data: data),
            let continent = regions.first
        else { return nil }

        let filteredRegions: [Region] = continent.subregions.sorted(by: <)

        return Region(name: continent.name, subregions: filteredRegions)
    }
}

// MARK: - Private

private extension MapsController {

    func addToQueue(_ region: Region) {
        regionsToDownload.append(region)
        region.mapDownloadStatus = .pending
        processQueue()
    }

    func cancel(_ region: Region) {
        if case .downloading = region.mapDownloadStatus {
            fileDownloader.cancelDownload()
            currentDownloadTask?.cancel()
            isDownloading = false
            processQueue()
        } else if let index = regionsToDownload.firstIndex(where: { $0.name == region.name }) {
            regionsToDownload.remove(at: index)
        }
        region.mapDownloadStatus = .available
    }

    func processQueue() {
        guard !isDownloading, !regionsToDownload.isEmpty else { return }

        isDownloading = true
        let nextRegion = regionsToDownload.removeFirst()

        currentDownloadTask = Task {
            await download(nextRegion)
            try Task.checkCancellation()
            isDownloading = false
            processQueue()
        }
    }

    func download(_ region: Region) async {
        do {
            print("Downloading: \(region.name)")

            let fileURL = URL(string: "https://download.geofabrik.de/europe/ireland-and-northern-ireland-latest.osm.pbf")!

            try await fileDownloader.downloadMap(from: fileURL) { [weak region] progress in
                print("Download progress: \(Int(progress * 100))%")
                if let region {
                    region.mapDownloadStatus = .downloading(progress)
                }
            }
            try Task.checkCancellation()
            print("Finished: \(region.name)")
            region.mapDownloadStatus = .downloaded
        } catch {
            print("Error occurred while loading the \(region.name) map: \(error)")
        }
    }
}
