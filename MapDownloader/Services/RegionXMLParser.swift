//
//  RegionXMLParser.swift
//  MapDownloader
//
//  Created by Viacheslav on 02.03.2025.
//

import Foundation

final class RegionParser: NSObject {

    private var regions: [Region] = []
    private var regionStack: [Region] = []

    func parseXML(data: Data) -> [Region]? {
        let parser = XMLParser(data: data)
        parser.delegate = self

        return parser.parse() ? regions : nil
    }
}

// MARK: - XMLParserDelegate

extension RegionParser: XMLParserDelegate {

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        guard elementName == "region", let regionName = attributeDict["name"] else { return }

        var downloadPrefix: String
        switch regionStack.count {
        case 1:
            downloadPrefix = regionName
        default:
            downloadPrefix = (regionStack.last?.downloadPrefix ?? "") + "_" + regionName
        }
        let firstLetter = downloadPrefix.prefix(1).capitalized
        let remainingLetters = downloadPrefix.dropFirst()
        downloadPrefix = firstLetter + remainingLetters

        regionStack.append(.init(name: regionName, downloadPrefix: downloadPrefix, subregions: []))
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        guard elementName == "region", let completedRegion = regionStack.popLast() else { return }

        if let parentRegion = regionStack.last {
            parentRegion.subregions.append(completedRegion)
            regionStack[regionStack.count - 1] = parentRegion
        } else {
            regions.append(completedRegion)
        }
    }
}
