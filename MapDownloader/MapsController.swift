//
//  MapsController.swift
//  MapDownloader
//
//  Created by Viacheslav on 09.03.2025.
//

import Foundation

actor MapsController {

    private var regionsToDownload: [Region] = []
    private var currentDownloadTask: Task<Void, any Error>?
    private var isDownloading = false

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
            region.mapDownloadStatus = .downloading(0)
            try await Task.sleep(nanoseconds: 1_000_000_000)
            region.mapDownloadStatus = .downloading(0.1)
            try await Task.sleep(nanoseconds: 1_000_000_000)
            region.mapDownloadStatus = .downloading(0.25)
            try await Task.sleep(nanoseconds: 1_000_000_000)
            region.mapDownloadStatus = .downloading(0.5)
            try await Task.sleep(nanoseconds: 1_000_000_000)
            region.mapDownloadStatus = .downloading(0.75)
            try await Task.sleep(nanoseconds: 1_000_000_000)
            region.mapDownloadStatus = .downloading(1)
            print("Finished: \(region.name)")
            region.mapDownloadStatus = .downloaded
        } catch {
            print("Error occurred while loading the \(region.name) map: \(error)")
        }
    }
}
