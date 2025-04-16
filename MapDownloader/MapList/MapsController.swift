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

        await restorePossibleDownloadProgress(using: regionsByDownloadPrefix)
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
            currentDownloadTask?.cancel()
            fileDownloader.cancelDownload()
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

        currentDownloadTask = Task { [weak self] in
            await self?.download(nextRegion)
            try Task.checkCancellation()
            await self?.handleDownloadCompletion()
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
            region.mapDownloadStatus = .downloading(0)
            try await fileDownloader.download(with: request, fileName: fileName) { [weak region] progress in
                print("Download progress: \(Int(progress * 100))%")
                if let region, !Task.isCancelled {
                    region.mapDownloadStatus = .downloading(progress)
                }
            }
            try Task.checkCancellation()
            print("Finished: \(region.name)")
            region.mapDownloadStatus = .downloaded
        } catch {
            print("Error occurred while downloading the \(region.name) map: \(error)")
        }
    }

    func handleDownloadCompletion() async {
        isDownloading = false
        onMapDownloadFinished?()
        processQueue()
    }

    func checkDownloadedMaps(using regionsByDownloadPrefix: [String: Region]) {
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

    func restorePossibleDownloadProgress(using regionsByDownloadPrefix: [String: Region]) async {
        guard
            let downloadTask = await fileDownloader.currentDownloadTask,
            let url = downloadTask.originalRequest?.url,
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let queryItems = components.queryItems,
            let fileName = queryItems.first(where: { $0.name == "file" })?.value
        else { return }

        let downloadPrefix = fileName.replacingOccurrences(of: String.fileNameDownloadSuffix, with: "")
        if let region = regionsByDownloadPrefix[downloadPrefix] {
            print("Found \(region.name) map that is currently downloading")
            isDownloading = true
            region.mapDownloadStatus = .downloading(0)
            currentDownloadTask = Task { [weak self, weak region] in
                do {
                    try await self?.fileDownloader.restoreDownloadCallbacks(for: downloadTask) { [weak region] progress in
                        print("New download progress: \(Int(progress * 100))%")
                        if let region, !Task.isCancelled {
                            region.mapDownloadStatus = .downloading(progress)
                        }
                    }
                    try Task.checkCancellation()
                    if let region {
                        print("Finished: \(region.name)")
                        region.mapDownloadStatus = .downloaded
                    }
                    await self?.handleDownloadCompletion()
                } catch {
                    print("Error occurred while downloading \(fileName) file: \(error)")
                }
            }
        }
    }
}
