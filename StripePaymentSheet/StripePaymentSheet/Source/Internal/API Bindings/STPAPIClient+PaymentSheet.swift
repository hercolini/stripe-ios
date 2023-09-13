//
//  STPAPIClient+PaymentSheet.swift
//  StripePaymentSheet
//
//  Created by David Estes on 9/16/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

extension STPAPIClient {
    typealias STPIntentCompletionBlock = ((Result<Intent, Error>) -> Void)

    func retrievePaymentIntentWithPreferences(
        withClientSecret secret: String,
        customerEphemeralKey: String? = nil
    ) async throws -> STPPaymentIntent {
        guard STPPaymentIntentParams.isClientSecretValid(secret) && !publishableKeyIsUserKey else {
            throw NSError.stp_clientSecretError()
        }

        var parameters: [String: Any] = [:]
        parameters["client_secret"] = secret
        parameters["type"] = "payment_intent"
        parameters["expand"] = ["payment_method_preference.payment_intent.payment_method"]
        parameters["locale"] = Locale.current.toLanguageTag()
        if let customerEphemeralKey = customerEphemeralKey {
            parameters["legacy_customer_ephemeral_key"] = customerEphemeralKey
        }

        return try await APIRequest<STPPaymentIntent>.getWith(
            self,
            endpoint: APIEndpointIntentWithPreferences,
            parameters: parameters
        )
    }

    func retrieveElementsSession(
        withIntentConfig intentConfig: PaymentSheet.IntentConfiguration,
        customerEphemeralKey: String? = nil
    ) async throws -> STPElementsSession {
        var parameters = intentConfig.elementsSessionParameters(publishableKey: publishableKey)
        if let customerEphemeralKey = customerEphemeralKey {
            parameters["legacy_customer_ephemeral_key"] = customerEphemeralKey
        }

        return try await APIRequest<STPElementsSession>.getWith(
            self,
            endpoint: APIEndpointIntentWithPreferences,
            parameters: parameters
        )
    }

    func retrieveElementsSessionForCustomerSheet(
        customerEphemeralKey: String? = nil
    ) async throws -> STPElementsSession {
        var parameters: [String: Any] = [:]
        parameters["type"] = "deferred_intent"
        parameters["locale"] = Locale.current.toLanguageTag()

        var deferredIntent = [String: Any]()
        deferredIntent["mode"] = "setup"
        parameters["deferred_intent"] = deferredIntent
        if let customerEphemeralKey = customerEphemeralKey {
            parameters["legacy_customer_ephemeral_key"] = customerEphemeralKey
        }

        return try await APIRequest<STPElementsSession>.getWith(
            self,
            endpoint: APIEndpointIntentWithPreferences,
            parameters: parameters
        )
    }

    func retrieveSetupIntentWithPreferences(
        withClientSecret secret: String,
        customerEphemeralKey: String? = nil
    ) async throws -> STPSetupIntent {
        guard STPSetupIntentConfirmParams.isClientSecretValid(secret) && !publishableKeyIsUserKey else {
            throw NSError.stp_clientSecretError()
        }

        var parameters: [String: Any] = [:]
        parameters["client_secret"] = secret
        parameters["type"] = "setup_intent"
        parameters["expand"] = ["payment_method_preference.setup_intent.payment_method"]
        parameters["locale"] = Locale.current.toLanguageTag()
        if let customerEphemeralKey = customerEphemeralKey {
            parameters["legacy_customer_ephemeral_key"] = customerEphemeralKey
        }

        return try await APIRequest<STPSetupIntent>.getWith(
            self,
            endpoint: APIEndpointIntentWithPreferences,
            parameters: parameters
        )
    }
}

extension PaymentSheet.IntentConfiguration {
    func elementsSessionParameters(publishableKey: String?) -> [String: Any] {
        var parameters: [String: Any] = [:]
        parameters["key"] = publishableKey
        parameters["type"] = "deferred_intent"
        parameters["locale"] = Locale.current.toLanguageTag()

        var deferredIntent = [String: Any]()
        deferredIntent["payment_method_types"] = paymentMethodTypes
        deferredIntent["on_behalf_of"] = onBehalfOf

        switch mode {
        case .payment(let amount, let currency, let setupFutureUsage, let captureMethod):
            deferredIntent["mode"] = "payment"
            deferredIntent["amount"] = amount
            deferredIntent["currency"] = currency
            deferredIntent["setup_future_usage"] = setupFutureUsage?.rawValue
            deferredIntent["capture_method"] = captureMethod.rawValue
        case .setup(let currency, let setupFutureUsage):
            deferredIntent["mode"] = "setup"
            deferredIntent["currency"] = currency
            deferredIntent["setup_future_usage"] = setupFutureUsage.rawValue
        }

        parameters["deferred_intent"] = deferredIntent
        return parameters
    }
}

private let APIEndpointIntentWithPreferences = "elements/sessions"
