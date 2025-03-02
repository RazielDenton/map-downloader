//
//  MapRegionCell.swift
//  MapDownloader
//
//  Created by Viacheslav on 02.03.2025.
//

import UIKit

private extension CGFloat {
    static let layoutMargin: CGFloat = 20
    static let textPadding: CGFloat = 16
}

final class MapRegionCell: UITableViewCell {

    static let reuseIdentifier = "MapRegionCell"

    private let mapNameLabel: UILabel = .init()
    private let leftIndicator: UIImageView = .init(image: .mapIndicator)
    private let rightIndicator: UIImageView = .init(image: .download)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with region: Region) {
        mapNameLabel.text = region.name.capitalized
    }
}

private extension MapRegionCell {

    func setupViews() {
        selectionStyle = .none

        mapNameLabel.font = .preferredFont(forTextStyle: .body)
        mapNameLabel.adjustsFontForContentSizeCategory = true

        setupLayout()
    }

    func setupLayout() {
        addSubview(mapNameLabel)
        addSubview(leftIndicator)
        addSubview(rightIndicator)

        mapNameLabel.translatesAutoresizingMaskIntoConstraints = false
        leftIndicator.translatesAutoresizingMaskIntoConstraints = false
        rightIndicator.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            leftIndicator.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .layoutMargin),
            leftIndicator.centerYAnchor.constraint(equalTo: centerYAnchor),

            mapNameLabel.leadingAnchor.constraint(equalTo: leftIndicator.trailingAnchor, constant: .textPadding),
            mapNameLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            mapNameLabel.trailingAnchor.constraint(greaterThanOrEqualTo: rightIndicator.leadingAnchor, constant: -.textPadding),

            rightIndicator.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -.layoutMargin),
            rightIndicator.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
}
