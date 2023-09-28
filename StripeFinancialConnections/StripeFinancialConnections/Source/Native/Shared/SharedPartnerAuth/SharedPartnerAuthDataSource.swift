//
//  SharedSharedPartnerAuthDataSource.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 9/28/23.
//

import Foundation
@_spi(STP) import StripeCore

protocol SharedPartnerAuthDataSource: AnyObject {
    var pane: FinancialConnectionsSessionManifest.NextPane { get }
    var institution: FinancialConnectionsInstitution { get }
    var manifest: FinancialConnectionsSessionManifest { get }
    var returnURL: String? { get }
    var analyticsClient: FinancialConnectionsAnalyticsClient { get }
    var pendingAuthSession: FinancialConnectionsAuthSession? { get set }
    var disableAuthSessionRetrieval: Bool { get }

    func recordAuthSessionEvent(eventName: String, authSessionId: String)
    func clearReturnURL(authSession: FinancialConnectionsAuthSession, authURL: String) -> Future<FinancialConnectionsAuthSession>
    func retrieveAuthSession(_ authSession: FinancialConnectionsAuthSession) -> Future<FinancialConnectionsAuthSession>
}

final class SharedPartnerAuthDataSourceImplementation: SharedPartnerAuthDataSource {

    let pane: FinancialConnectionsSessionManifest.NextPane
    let institution: FinancialConnectionsInstitution
    let manifest: FinancialConnectionsSessionManifest
    let returnURL: String?
    private let apiClient: FinancialConnectionsAPIClient
    private let clientSecret: String
    let analyticsClient: FinancialConnectionsAnalyticsClient
    var disableAuthSessionRetrieval: Bool {
        return manifest.features?["bank_connections_disable_defensive_auth_session_retrieval_on_complete"] == true
    }

    // a "pending" auth session is a session which has started
    // BUT the session is still yet-to-be authorized
    //
    // in other words, a `pendingAuthSession` is up for being
    // cancelled unless the user successfully authorizes
    var pendingAuthSession: FinancialConnectionsAuthSession? // private(set)
    
    init(
        pane: FinancialConnectionsSessionManifest.NextPane,
        institution: FinancialConnectionsInstitution,
        manifest: FinancialConnectionsSessionManifest,
        returnURL: String?,
        apiClient: FinancialConnectionsAPIClient,
        clientSecret: String,
        analyticsClient: FinancialConnectionsAnalyticsClient
    ) {
        self.pane = pane
        self.institution = institution
        self.manifest = manifest
        self.returnURL = returnURL
        self.apiClient = apiClient
        self.clientSecret = clientSecret
        self.analyticsClient = analyticsClient
    }
    
    func clearReturnURL(
        authSession: FinancialConnectionsAuthSession,
        authURL: String
    ) -> Future<FinancialConnectionsAuthSession> {
        let promise = Promise<FinancialConnectionsAuthSession>()
        apiClient
            .synchronize(clientSecret: clientSecret, returnURL: nil)
            .observe { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success:
                    let copiedSession = FinancialConnectionsAuthSession(
                        id: authSession.id,
                        flow: authSession.flow,
                        institutionSkipAccountSelection: authSession.institutionSkipAccountSelection,
                        nextPane: authSession.nextPane,
                        showPartnerDisclosure: authSession.showPartnerDisclosure,
                        skipAccountSelection: authSession.skipAccountSelection,
                        url: authURL,
                        isOauth: authSession.isOauth,
                        display: authSession.display
                    )
                    self.pendingAuthSession = copiedSession
                    promise.fullfill(with: .success(copiedSession))
                case .failure(let error):
                    promise.reject(with: error)
                }
            }
        return promise
    }
    
    func recordAuthSessionEvent(
        eventName: String,
        authSessionId: String
    ) {
        guard ShouldRecordAuthSessionEvent() else {
            // on Stripe SDK Core analytics client we don't send events
            // for simulator or tests, so don't send these either...
            return
        }
        guard pane != .bankAuthRepair else {
            // auth session logging is not supported for bank auth repair
            return
        }

        apiClient.recordAuthSessionEvent(
            clientSecret: clientSecret,
            authSessionId: authSessionId,
            eventNamespace: "partner-auth-lifecycle",
            eventName: eventName
        )
        .observe { _ in
            // we don't do anything with the event response
        }
    }

    func retrieveAuthSession(
        _ authSession: FinancialConnectionsAuthSession
    ) -> Future<FinancialConnectionsAuthSession> {
        return apiClient.retrieveAuthSession(
            clientSecret: clientSecret,
            authSessionId: authSession.id
        ).chained { [weak self] (authSession: FinancialConnectionsAuthSession) in
            // update the `pendingAuthSession` with the latest from the server
            self?.pendingAuthSession = authSession
            return Promise(value: authSession)
        }
    }
}

private func ShouldRecordAuthSessionEvent() -> Bool {
    #if targetEnvironment(simulator)
    return false
    #else
    return NSClassFromString("XCTest") == nil
    #endif
}
