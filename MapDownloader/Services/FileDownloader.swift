//
//  FileDownloader.swift
//  MapDownloader
//
//  Created by Viacheslav on 30.03.2025.
//

import Foundation

final class FileDownloader: NSObject {

    static let shared = FileDownloader()

    private lazy var session: URLSession = makeBackgroundURLSession()
    private var continuation: CheckedContinuation<Void, Error>?
    private var progressHandler: ((Double) -> Void)?
    private var downloadTask: URLSessionDownloadTask?

    private override init() {
        super.init()
    }

    // MARK: - Public

    var backgroundURLSessionCompletion: (() -> Void)?

    func downloadMap(from url: URL, progressHandler: ((Double) -> Void)?) async throws {
        self.progressHandler = progressHandler

        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            downloadTask = session.downloadTask(with: url)
            downloadTask?.resume()
        }
    }

    func cancelDownload() {
        downloadTask?.cancel()
        continuation?.resume(throwing: NSError(
            domain: "FileDownloader",
            code: -999,
            userInfo: [NSLocalizedDescriptionKey: "Download canceled"]
        ))
        cleanup()
    }
}

// MARK: - Private

private extension FileDownloader {

    func makeBackgroundURLSession() -> URLSession {
        let configuration = URLSessionConfiguration.background(withIdentifier: "com.MapDownloader.background.download")
        configuration.isDiscretionary = true

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
        DispatchQueue.main.async {
            self.progressHandler?(progress)
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        defer { cleanup() }

        do {
            let fileManager = FileManager.default
            let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let destinationURL = documentsURL.appendingPathComponent(
                downloadTask.originalRequest?.url?.lastPathComponent ?? "downloadedFile"
            )

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
        defer { cleanup() }

        if let error = error as? NSError, error.code == NSURLErrorCancelled {
            return
        }

        continuation?.resume(throwing: error ?? NSError(
            domain: "FileDownloader",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "Unknown error"]
        ))
    }

    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DispatchQueue.main.async {
            self.backgroundURLSessionCompletion?()
            self.backgroundURLSessionCompletion = nil
        }
    }
}
