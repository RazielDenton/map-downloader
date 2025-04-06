//
//  StorageBannerView.swift
//  MapDownloader
//
//  Created by Viacheslav on 06.04.2025.
//

import UIKit

private extension CGFloat {
    static let barHeight: CGFloat = 16
    static let spacing: CGFloat = 9
    static let verticalPadding: CGFloat = 12
    static let horizontalPadding: CGFloat = 16
}

final class StorageBannerView: UIView {

    private let titleLabel: UILabel = .init()
    private let availableSpaceLabel: UILabel = .init()
    private let capsuleUsageBarView = UIView()
    private let capsuleUsageBarBackgroundView = UIView()

    private var capsuleUsageBarWidthConstraint: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)

        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Public

extension StorageBannerView {

    func updateIndicators(availableDiskSpace: String?, usageRatio: Double?) {
        if let availableDiskSpace {
            availableSpaceLabel.text = String(localized: "Free") + " " + availableDiskSpace
        } else {
            availableSpaceLabel.text = String(localized: "Undefined")
        }
        animateCapsuleUsageBarView(with: usageRatio ?? 0)
    }
}

// MARK: - Private

private extension StorageBannerView {

    func setup() {
        backgroundColor = .white

        titleLabel.text = String(localized: "Device memory")
        titleLabel.font = .preferredFont(forTextStyle: .footnote)
        titleLabel.adjustsFontForContentSizeCategory = true

        availableSpaceLabel.font = .preferredFont(forTextStyle: .footnote)
        availableSpaceLabel.adjustsFontForContentSizeCategory = true

        capsuleUsageBarBackgroundView.backgroundColor = .background
        capsuleUsageBarBackgroundView.layer.cornerRadius = .barHeight / 2

        capsuleUsageBarView.backgroundColor = .navigationBar
        capsuleUsageBarView.layer.cornerRadius = .barHeight / 2

        setupLayout()
    }

    func setupLayout() {
        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let stackView = UIStackView(arrangedSubviews: [titleLabel, spacer, availableSpaceLabel])

        addSubview(stackView)
        addSubview(capsuleUsageBarBackgroundView)
        capsuleUsageBarBackgroundView.addSubview(capsuleUsageBarView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        capsuleUsageBarBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        capsuleUsageBarView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .horizontalPadding),
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: .verticalPadding),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -.horizontalPadding),

            capsuleUsageBarBackgroundView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .horizontalPadding),
            capsuleUsageBarBackgroundView.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: .spacing),
            capsuleUsageBarBackgroundView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -.horizontalPadding),
            capsuleUsageBarBackgroundView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -.verticalPadding),
            capsuleUsageBarBackgroundView.heightAnchor.constraint(equalToConstant: .barHeight),

            capsuleUsageBarView.leadingAnchor.constraint(equalTo: capsuleUsageBarBackgroundView.leadingAnchor),
            capsuleUsageBarView.topAnchor.constraint(equalTo: capsuleUsageBarBackgroundView.topAnchor),
            capsuleUsageBarView.bottomAnchor.constraint(equalTo: capsuleUsageBarBackgroundView.bottomAnchor)
        ])

        capsuleUsageBarWidthConstraint = capsuleUsageBarView.widthAnchor.constraint(equalToConstant: 0)
        capsuleUsageBarWidthConstraint?.isActive = true
    }

    func animateCapsuleUsageBarView(with usageRatio: Double) {
        let maxWidth: CGFloat = capsuleUsageBarBackgroundView.frame.width
        capsuleUsageBarWidthConstraint?.constant = maxWidth * usageRatio
        let animator = UIViewPropertyAnimator(
            duration: 0.8,
            timingParameters: UICubicTimingParameters(
                controlPoint1: CGPoint(x: 0.8, y: 0),
                controlPoint2: CGPoint(x: 0.1, y: 1)
            )
        )
        animator.addAnimations {
            self.capsuleUsageBarBackgroundView.layoutIfNeeded()
        }
        animator.startAnimation()
    }
}
