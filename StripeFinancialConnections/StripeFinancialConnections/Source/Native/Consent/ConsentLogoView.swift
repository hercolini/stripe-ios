//
//  ConsentLogoView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 12/22/22.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

final class ConsentLogoView: UIView {

    init(merchantLogo: [String]) {
        super.init(frame: .zero)
        let horizontalStackView = UIStackView()
        horizontalStackView.axis = .horizontal
        // spacing between logos + ellipsis view
        horizontalStackView.spacing = 3
        horizontalStackView.alignment = .center
        // display one logo
        if merchantLogo.isEmpty {
            let imageView = UIImageView(image: Image.stripe_logo.makeImage(template: true))
            imageView.tintColor = .textBrand
            imageView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                imageView.widthAnchor.constraint(equalToConstant: 60),
                imageView.heightAnchor.constraint(equalToConstant: 25),
            ])
            horizontalStackView.addArrangedSubview(imageView)
        }
        // display multiple logos
        else {
            for i in 0..<merchantLogo.count {
                let urlString = merchantLogo[i]
                horizontalStackView.addArrangedSubview(
                    CreateRoundedLogoView(urlString: urlString)
                )

                let isLastLogo = (i == merchantLogo.count - 1)
                if !isLastLogo {
                    horizontalStackView.addArrangedSubview(CreateEllipsisView())
                }
            }
        }
        addAndPinSubview(horizontalStackView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private func CreateRoundedLogoView(urlString: String) -> UIView {
    let radius: CGFloat = 72.0
    let imageView = UIImageView()
    imageView.contentMode = .scaleAspectFill
    imageView.clipsToBounds = true
    imageView.layer.cornerRadius = 16.0
    imageView.setImage(with: urlString)
    imageView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        imageView.widthAnchor.constraint(equalToConstant: radius),
        imageView.heightAnchor.constraint(equalToConstant: radius),
    ])
    return imageView
}

private func CreateEllipsisView() -> UIView {
    let dotSpacing: CGFloat = 4.0
    let threeDotView = ThreeDotView()
    threeDotView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        threeDotView.widthAnchor.constraint(equalToConstant: (ThreeDotView.dotRadius * 3) + (dotSpacing * 2)),
        threeDotView.heightAnchor.constraint(equalToConstant: ThreeDotView.dotRadius),
    ])
    return threeDotView
//    let paddingStackView = UIStackView(
//        arrangedSubviews: [
//            threeDotView
//        ]
//    )
//    paddingStackView.isLayoutMarginsRelativeArrangement = true
//    // add extra padding around the ellipsis view (· · ·)
//    paddingStackView.layoutMargins = UIEdgeInsets(
//        top: 0,
//        left: 3,
//        bottom: 0,
//        right: 3
//    )
//    return paddingStackView
}

private class ThreeDotView: UIView {

    static let dotRadius: CGFloat = 6.0

    private let leftDot = DotView()
    private let middleDot = DotView()
    private let rightDot = DotView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        addSubview(leftDot)
        addSubview(middleDot)
        addSubview(rightDot)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let y = (bounds.height / 2) - (Self.dotRadius / 2)
        leftDot.frame = CGRect(
            x: 0,
            y: y,
            width: Self.dotRadius,
            height: Self.dotRadius
        )
        middleDot.frame = CGRect(
            x: (bounds.width / 2) - (Self.dotRadius / 2),
            y: y,
            width: Self.dotRadius,
            height: Self.dotRadius
        )
        rightDot.frame = CGRect(
            x: bounds.width - Self.dotRadius,
            y: y,
            width: Self.dotRadius,
            height: Self.dotRadius
        )
    }
}

// a view that will automatically resize
private class DotView: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .borderNeutral
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.width / 2
    }
}

#if DEBUG

import SwiftUI

private struct ConsentLogoViewUIViewRepresentable: UIViewRepresentable {

    func makeUIView(context: Context) -> ConsentLogoView {
        ConsentLogoView(
            merchantLogo: [
                "https://b.stripecdn.com/connections-statics-srv/assets/BrandIcon--stripe-4x.png",
                "https://b.stripecdn.com/connections-statics-srv/assets/BrandIcon--stripe-4x.png",
            ]
        )
    }

    func updateUIView(_ uiView: ConsentLogoView, context: Context) {}
}

struct ConsentLogoView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .leading) {
            ConsentLogoViewUIViewRepresentable()
                .frame(width: 176, height: 72)
                .padding()
            Spacer()
        }
    }
}

#endif
