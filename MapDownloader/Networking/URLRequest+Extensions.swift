//
//  URLRequest+Extensions.swift
//  MapDownloader
//
//  Created by Viacheslav on 30.03.2025.
//

import Foundation

extension URLRequest {

    static private let baseURL = URL(string: "https://download.osmand.net/")!

    init(url: URL = baseURL, path: String, queryItemsParameters: [String: String] = [:]) {
        var components = URLComponents(url: url.appendingPathComponent(path), resolvingAgainstBaseURL: false)

        if !queryItemsParameters.isEmpty {
            components?.queryItems = queryItemsParameters.map {
                URLQueryItem(name: $0.key, value: $0.value)
            }
        }

        guard let url = components?.url else { fatalError("The url string from the components is malformed") }

        self.init(url: url)
    }
}
