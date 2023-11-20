//
//  ExternalPaymentMethod.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 11/12/23.
//

import Foundation
@_spi(STP) import StripePayments

/// ViewModel-like information for displaying external payment methods (EPMs)
struct ExternalPaymentMethod: Decodable, Equatable, Hashable {
    /// The type of the external payment method. e.g. `"external_foopay"`
    /// These match the strings specified by the merchant in `ExternalPaymentMethodConfiguration`.
    let type: String
    /// A localized label for the payment method e.g. "FooPay"
    let localizedLabel: String
    /// URL of a 48x pixel tall PNG representing the payment method suitable for display against a light background color.
    let lightImageURL: URL
    /// URL of a 48x pixel tall PNG representing the payment method suitable for display against a dark background color. If `nil`, use `lightImageURL` instead.
    let darkImageURL: URL?

    /// Helper method to decode the `v1/elements/sessions` response.
    /// - Parameter response: The value of the `external_payment_methods_data` key in the `v1/elements/sessions` response.
    public static func decoded(fromAPIResponse response: [[AnyHashable: Any]]?) -> [ExternalPaymentMethod]? {
        guard let response else {
            return nil
        }
        let jsonDecoder = JSONDecoder()
        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
        do {
            return try response.map { dict in
                let data = try JSONSerialization.data(withJSONObject: dict)
                return try jsonDecoder.decode(ExternalPaymentMethod.self, from: data)
            }
        } catch {
            return nil
        }
    }
}
