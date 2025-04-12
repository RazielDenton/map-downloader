//
//  MapsController.swift
//  MapDownloader
//
//  Created by Viacheslav on 09.03.2025.
//

import Foundation

private extension String {
    static let fileNameDownloadSuffix: String = "_europe_2.obf.zip"
}

actor MapsController {

    private let fileDownloader: FileDownloader
    private var regionsToDownload: [Region] = []
    private var currentDownloadTask: Task<Void, any Error>?
    private var isDownloading = false
    private var onMapDownloadFinished: (() -> Void)?

    private let fileManager = FileManager.default
    private var documentsURL: URL { fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0] }

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
            let (regions, regionsByDownloadPrefix) = parser.parseXML(data: data),
            let continent = regions.first
        else { return nil }

        checkDownloadedMaps(using: regionsByDownloadPrefix)
        let filteredRegions: [Region] = continent.subregions.sorted(by: <)

        return Region(name: continent.name, subregions: filteredRegions)
    }

    func setOnMapDownloadFinished(_ completionHandler: (() -> Void)?) {
        onMapDownloadFinished = completionHandler
    }

    func deleteMap(for region: Region) {
        do {
            let fileName = region.downloadPrefix + .fileNameDownloadSuffix
            let destinationURL = documentsURL.appendingPathComponent(fileName)
            try fileManager.removeItem(at: destinationURL)
            region.mapDownloadStatus = .available
            onMapDownloadFinished?()
        } catch {
            print("Error occurred while removing the \(region.name) map: \(error)")
        }
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
            onMapDownloadFinished?()
            processQueue()
        }
    }

    func download(_ region: Region) async {
        do {
            print("Downloading: \(region.name)")
            let fileName = region.downloadPrefix + .fileNameDownloadSuffix
            let request = URLRequest(
                path: "download",
                queryItemsParameters: ["standard": "yes", "file": fileName]
            )
            try await fileDownloader.download(with: request, fileName: fileName) { [weak region] progress in
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

    func checkDownloadedMaps(using regionsByDownloadPrefix: [String: Region]) {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]

        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)

            let fileNames = fileURLs.map { $0.lastPathComponent }
            fileNames.forEach {
                let downloadPrefix = $0.replacingOccurrences(of: String.fileNameDownloadSuffix, with: "")
                if let region = regionsByDownloadPrefix[downloadPrefix] {
                    region.mapDownloadStatus = .downloaded
                }
            }
        } catch {
            print("Error occurred while performing a shallow search of the documents directory: \(error)")
        }
    }
}
