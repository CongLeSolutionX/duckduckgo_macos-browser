//
//  PrivacyDashboardTabExtension.swift
//
//  Copyright © 2022 DuckDuckGo. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import BrowserServicesKit
import Combine
import Common
import ContentBlocking
import Foundation
import Navigation
import PrivacyDashboard

typealias CookieConsentPromptRequest = UserDialogRequest<Void, Bool>

final class PrivacyDashboardTabExtension {

    private let contentBlocking: any ContentBlockingProtocol

    @Published private(set) var privacyInfo: PrivacyInfo?
    @Published private(set) var cookieConsentPromptRequest: CookieConsentPromptRequest? {
        didSet {
            guard let request = cookieConsentPromptRequest else { return }
            request.addCompletionHandler { [weak self, weak request] _ in
                if let self, let request, self.cookieConsentPromptRequest === request {
                    self.cookieConsentPromptRequest = nil
                }
            }
        }
    }

    private var previousPrivacyInfosByURL: [String: PrivacyInfo] = [:]

    private var cancellables = Set<AnyCancellable>()

    init(contentBlocking: some ContentBlockingProtocol,
         autoconsentUserScriptPublisher: some Publisher<UserScriptWithAutoconsent?, Never>,
         didUpgradeToHttpsPublisher: some Publisher<URL, Never>,
         trackersPublisher: some Publisher<DetectedTracker, Never>) {
        self.contentBlocking = contentBlocking

        autoconsentUserScriptPublisher.sink { [weak self] autoconsentUserScript in
            if #available(macOS 11, *) {
                autoconsentUserScript?.delegate = self
            }
        }.store(in: &cancellables)

        didUpgradeToHttpsPublisher.sink { [weak self] upgradedUrl in
            self?.setMainFrameConnectionUpgradedTo(upgradedUrl)
        }.store(in: &cancellables)

        trackersPublisher.sink { [weak self] tracker in
            guard let self, let url = URL(string: tracker.request.pageUrl) else { return }

            switch tracker.type {
            case .tracker:
                self.privacyInfo?.trackerInfo.addDetectedTracker(tracker.request, onPageWithURL: url)
            case .thirdPartyRequest:
                self.privacyInfo?.trackerInfo.add(detectedThirdPartyRequest: tracker.request)
            case .trackerWithSurrogate(host: let host):
                self.privacyInfo?.trackerInfo.addInstalledSurrogateHost(host, for: tracker.request, onPageWithURL: url)
                self.privacyInfo?.trackerInfo.addDetectedTracker(tracker.request, onPageWithURL: url)
            }
        }.store(in: &cancellables)
    }

}

extension PrivacyDashboardTabExtension {

    private func resetDashboardInfo(for url: URL, didGoBackForward: Bool) {
        guard url.isHypertextURL else {
            privacyInfo = nil
            return
        }

        if didGoBackForward, let previousPrivacyInfo = previousPrivacyInfosByURL[url.absoluteString] {
            privacyInfo = previousPrivacyInfo
        } else {
            privacyInfo = makePrivacyInfo(url: url)
        }
    }

    private func makePrivacyInfo(url: URL) -> PrivacyInfo? {
        guard let host = url.host else { return nil }

        let entity = contentBlocking.trackerDataManager.trackerData.findEntity(forHost: host)

        privacyInfo = PrivacyInfo(url: url,
                                  parentEntity: entity,
                                  protectionStatus: makeProtectionStatus(for: host))

        previousPrivacyInfosByURL[url.absoluteString] = privacyInfo

        return privacyInfo
    }

    private func resetConnectionUpgradedTo(navigationAction: NavigationAction) {
        let isOnUpgradedPage = navigationAction.url == privacyInfo?.connectionUpgradedTo
        if navigationAction.isForMainFrame && !isOnUpgradedPage {
            privacyInfo?.connectionUpgradedTo = nil
        }
    }

    public func setMainFrameConnectionUpgradedTo(_ upgradedUrl: URL?) {
        guard let upgradedUrl else { return }
        privacyInfo?.connectionUpgradedTo = upgradedUrl
    }

    private func makeProtectionStatus(for host: String) -> ProtectionStatus {
        let config = contentBlocking.privacyConfigurationManager.privacyConfig

        let isTempUnprotected = config.isTempUnprotected(domain: host)
        let isAllowlisted = config.isUserUnprotected(domain: host)

        var enabledFeatures: [String] = []

        if !config.isInExceptionList(domain: host, forFeature: .contentBlocking) {
            enabledFeatures.append(PrivacyFeature.contentBlocking.rawValue)
        }

        return ProtectionStatus(unprotectedTemporary: isTempUnprotected,
                                enabledFeatures: enabledFeatures,
                                allowlisted: isAllowlisted,
                                denylisted: false)
    }

}

extension PrivacyDashboardTabExtension: NavigationResponder {

    @MainActor
    func decidePolicy(for navigationAction: NavigationAction, preferences: inout NavigationPreferences) async -> NavigationActionPolicy? {
        resetConnectionUpgradedTo(navigationAction: navigationAction)

        return .next
    }

    @MainActor
    func willStart(_ navigation: Navigation) {
        if navigation.navigationAction.navigationType.isRedirect {
            resetDashboardInfo(for: navigation.url, didGoBackForward: navigation.navigationAction.navigationType.isBackForward)
        }
    }

    @MainActor
    func didStart(_ navigation: Navigation) {
        resetDashboardInfo(for: navigation.url, didGoBackForward: navigation.navigationAction.navigationType.isBackForward)
    }

}

@available(macOS 11, *)
extension PrivacyDashboardTabExtension: AutoconsentUserScriptDelegate {

    func autoconsentUserScript(consentStatus: CookieConsentInfo) {
        self.privacyInfo?.cookieConsentManaged = consentStatus
    }

    func autoconsentUserScriptPromptUserForConsent(_ callback: @escaping (Bool) -> Void) {
        cookieConsentPromptRequest = .init { result in
            callback((try? result.get()) ?? false)
        }
    }

}

protocol PrivacyDashboardProtocol: AnyObject, NavigationResponder {
    var privacyInfo: PrivacyInfo? { get }
    var privacyInfoPublisher: AnyPublisher<PrivacyInfo?, Never> { get }
    var cookieConsentPromptRequestPublisher: AnyPublisher<CookieConsentPromptRequest?, Never> { get }

    func setMainFrameConnectionUpgradedTo(_ upgradedUrl: URL?)
}
extension PrivacyDashboardTabExtension: PrivacyDashboardProtocol, TabExtension {
    typealias PublicProtocol = PrivacyDashboardProtocol
    func getPublicProtocol() -> PublicProtocol { self }

    var privacyInfoPublisher: AnyPublisher<PrivacyDashboard.PrivacyInfo?, Never> {
        self.$privacyInfo.eraseToAnyPublisher()
    }

    var cookieConsentPromptRequestPublisher: AnyPublisher<CookieConsentPromptRequest?, Never> {
        self.$cookieConsentPromptRequest.eraseToAnyPublisher()
    }

}

extension Tab {

    var privacyInfo: PrivacyInfo? {
        self.privacyDashboard?.privacyInfo
    }

    var privacyInfoPublisher: AnyPublisher<PrivacyInfo?, Never> {
        self.privacyDashboard?.privacyInfoPublisher ?? Just(nil).eraseToAnyPublisher()
    }

    var cookieConsentPromptRequestPublisher: AnyPublisher<CookieConsentPromptRequest?, Never> {
        self.privacyDashboard?.cookieConsentPromptRequestPublisher ?? Just(nil).eraseToAnyPublisher()
    }

    func setMainFrameConnectionUpgradedTo(_ upgradedUrl: URL?) {
        self.privacyDashboard?.setMainFrameConnectionUpgradedTo(upgradedUrl)
    }

}

extension TabExtensions {
    var privacyDashboard: PrivacyDashboardProtocol? {
        resolve(PrivacyDashboardTabExtension.self)
    }
}