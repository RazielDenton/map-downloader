//
//  DiskSpaceService.swift
//  MapDownloader
//
//  Created by Viacheslav on 06.04.2025.
//

import Foundation

struct DiskSpaceService {

    private let fileManager = FileManager.default
    private let homePath = NSHomeDirectory()

    private let byteCountFormatter: ByteCountFormatter = {
        let byteCountFormatter = ByteCountFormatter()
        byteCountFormatter.allowedUnits = [.useGB, .useMB, .useKB]

        return byteCountFormatter
    }()
}

// MARK: - Public

extension DiskSpaceService {

    func totalDiskSpace() -> Int64? {
        try? fileManager.attributesOfFileSystem(forPath: homePath)[.systemSize] as? Int64
    }

    func freeDiskSpace() -> Int64? {
        try? fileManager.attributesOfFileSystem(forPath: homePath)[.systemFreeSize] as? Int64
    }

    func availableDiskSpaceString() -> String? {
        freeDiskSpace().map { byteCountFormatter.string(fromByteCount: $0) }
    }

    func usageRatio() -> Double? {
        guard
            let total = totalDiskSpace(),
            let free = freeDiskSpace()
        else {
            return nil
        }

        return Double(total - free) / Double(total)
    }
}
