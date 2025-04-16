//
//  MapRegionCell.swift
//  MapDownloader
//
//  Created by Viacheslav on 02.03.2025.
//

import UIKit

private extension CGFloat {
    static let layoutMargin: CGFloat = 20
    static let imagePadding: CGFloat = 9
    static let textPadding: CGFloat = 16
    static let stackViewSpacing: CGFloat = 5
    static let downloadButtonSize: CGFloat = 44
}

final class MapRegionCell: UITableViewCell {

    static let reuseIdentifier = "MapRegionCell"

    private let mapNameLabel: UILabel = .init()
    private let progressBar: UIProgressView = .init(progressViewStyle: .default)
    private let mapIndicator: UIImageView = .init(image: .mapIndicator)
    private let button: UIButton = .init(type: .system)

    private var region: Region?
    private var onButtonTap: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        region?.statusHandler = nil
        progressBar.setProgress(0, animated: false)
        region = nil
    }
}

// MARK: - Configuration

extension MapRegionCell {

    func configure(with region: Region, onButtonTap: (() -> Void)?) {
        self.region = region
        self.onButtonTap = onButtonTap
        mapNameLabel.text = region.name.capitalized

        if region.subregions.isEmpty {
            selectionStyle = .none
            accessoryType = .none
        } else {
            selectionStyle = .default
            accessoryType = .disclosureIndicator
        }

        updateStatus(with: region.mapDownloadStatus)

        region.statusHandler = { [weak self] status in
            DispatchQueue.main.async {
                self?.updateStatus(with: status)
            }
        }
    }
}

// MARK: - Private

private extension MapRegionCell {

    func updateStatus(with status: Region.MapDownloadStatus) {
        switch status {
        case .available:
            progressBar.isHidden = true
            mapIndicator.image = .mapIndicator
            button.isHidden = region?.subregions.isEmpty == true ? false : true
            button.setImage(.download, for: .normal)
        case .pending:
            progressBar.isHidden = true
            mapIndicator.image = .mapIndicator
            button.isHidden = false
            button.setImage(UIImage(systemName: "hourglass"), for: .normal)
        case .downloading(let progress):
            progressBar.isHidden = false
            progressBar.progress = Float(progress)
            mapIndicator.image = .mapIndicator
            button.isHidden = false
            button.setImage(.stopProgress, for: .normal)
        case .downloaded:
            progressBar.isHidden = true
            mapIndicator.image = .mapIndicator.withTintColor(.mapDownloaded, renderingMode: .alwaysOriginal)
            button.isHidden = true
            button.setImage(.none, for: .normal)
        }
    }

    func setupViews() {
        backgroundColor = .cellBackground

        mapNameLabel.font = .preferredFont(forTextStyle: .body)
        mapNameLabel.adjustsFontForContentSizeCategory = true

        progressBar.isHidden = true
        progressBar.progressTintColor = .accent

        button.setImage(.download, for: .normal)
        button.addAction(UIAction { [weak self] _ in
            self?.onButtonTap?()
        }, for: .touchUpInside)

        setupLayout()
    }

    func setupLayout() {
        let verticalStack: UIStackView = .init(arrangedSubviews: [mapNameLabel, progressBar])
        verticalStack.axis = .vertical
        verticalStack.alignment = .leading
        verticalStack.spacing = .stackViewSpacing

        contentView.addSubview(mapIndicator)
        contentView.addSubview(verticalStack)
        contentView.addSubview(button)

        mapIndicator.translatesAutoresizingMaskIntoConstraints = false
        verticalStack.translatesAutoresizingMaskIntoConstraints = false
        button.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            mapIndicator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: .layoutMargin),
            mapIndicator.topAnchor.constraint(equalTo: contentView.topAnchor, constant: .imagePadding),
            mapIndicator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -.imagePadding),
            mapIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            verticalStack.leadingAnchor.constraint(equalTo: mapIndicator.trailingAnchor, constant: .textPadding),
            verticalStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            verticalStack.trailingAnchor.constraint(equalTo: button.leadingAnchor, constant: -.textPadding),

            progressBar.leadingAnchor.constraint(equalTo: mapIndicator.trailingAnchor, constant: .textPadding),
            progressBar.trailingAnchor.constraint(equalTo: button.leadingAnchor, constant: -.textPadding),

            button.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -.layoutMargin),
            button.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            button.widthAnchor.constraint(equalToConstant: .downloadButtonSize),
            button.heightAnchor.constraint(equalToConstant: .downloadButtonSize)
        ])
    }
}
