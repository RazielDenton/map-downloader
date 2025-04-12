//
//  FileDownloader.swift
//  MapDownloader
//
//  Created by Viacheslav on 30.03.2025.
//

import Foundation

private extension String {
    static let currentDownloadFileNameKey = "currentDownloadFileName"
}

final class FileDownloader: NSObject {

    static let shared = FileDownloader()

    private lazy var session: URLSession = makeBackgroundURLSession()
    private var continuation: CheckedContinuation<Void, Error>?
    private var progressHandler: ((Double) -> Void)?
    private var downloadTask: URLSessionDownloadTask?

    private override init() {
        super.init()
    }

    // MARK: - Types

    enum FileDownloaderError: Error {
        case unknown
        case downloadCanceled
    }

    // MARK: - Public

    var backgroundURLSessionCompletion: (() -> Void)?

    var currentDownloadTask: URLSessionDownloadTask? {
        get async {
            await session.allTasks.compactMap { $0 as? URLSessionDownloadTask }.first
        }
    }

    func download(with urlRequest: URLRequest, fileName: String, progressHandler: ((Double) -> Void)?) async throws {
        self.progressHandler = progressHandler

        UserDefaults.standard.set(fileName, forKey: .currentDownloadFileNameKey)

        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            downloadTask = session.downloadTask(with: urlRequest)
            downloadTask?.resume()
        }
    }

    func cancelDownload() {
        downloadTask?.cancel()
        continuation?.resume(throwing: FileDownloaderError.downloadCanceled)
        cleanup()
    }

    func restoreDownloadCallbacks(
        for downloadTask: URLSessionDownloadTask,
        progressHandler: ((Double) -> Void)?
    ) async throws {
        continuation?.resume(throwing: FileDownloaderError.unknown) // in case MapsController was deallocated
        try await withCheckedThrowingContinuation { continuation in
            self.downloadTask = downloadTask
            self.continuation = continuation
            self.progressHandler = progressHandler
        }
    }
}

// MARK: - Private

private extension FileDownloader {

    func makeBackgroundURLSession() -> URLSession {
        let configuration = URLSessionConfiguration.background(withIdentifier: "com.MapDownloader.background.download")
        configuration.isDiscretionary = false

        return URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }

    func cleanup() {
        downloadTask = nil
        continuation = nil
        progressHandler = nil
    }
}

// MARK: - URLSessionDownloadDelegate

extension FileDownloader: URLSessionDownloadDelegate {

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        progressHandler?(progress)
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        defer { cleanup() }

        do {
            let fileManager = FileManager.default
            let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileName = UserDefaults.standard.string(forKey: .currentDownloadFileNameKey) ?? "downloadedFile"
            let destinationURL = documentsURL.appendingPathComponent(fileName)

            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }

            try fileManager.moveItem(at: location, to: destinationURL)

            continuation?.resume()
        } catch {
            continuation?.resume(throwing: error)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: (any Error)?) {
        if let error = error as? NSError, error.code == NSURLErrorCancelled {
            return
        } else if let error {
            continuation?.resume(throwing: error)
            cleanup()
        }
    }

    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DispatchQueue.main.async {
            self.backgroundURLSessionCompletion?()
            self.backgroundURLSessionCompletion = nil
        }
    }
}
