//
//  RegionXMLParser.swift
//  MapDownloader
//
//  Created by Viacheslav on 02.03.2025.
//

import Foundation

final class RegionParser: NSObject {

    var regions: [Region] = []
    var currentRegion: Region?
    var regionStack: [Region] = []

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
        attributes attributeDict: [String : String] = [:]
    ) {
        if elementName == "region", let name = attributeDict["name"] {
            let newRegion = Region(name: name)
            regionStack.append(newRegion)
        }
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        if elementName == "region" {
            guard let completedRegion = regionStack.popLast() else { return }

            if var parentRegion = regionStack.last {
                parentRegion.subregions.append(completedRegion)
                regionStack[regionStack.count - 1] = parentRegion
            } else {
                regions.append(completedRegion)
            }
        }
    }
}
