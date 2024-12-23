//
//  NewTabPageNextStepsCardsProvider.swift
//
//  Copyright © 2024 DuckDuckGo. All rights reserved.
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

import Common
import Combine
import NewTabPage
import PixelKit
import UserScript

final class NewTabPageNextStepsCardsProvider: NewTabPageNextStepsCardsProviding {
    let continueSetUpModel: HomePage.Models.ContinueSetUpModel
    let appearancePreferences: AppearancePreferences

    init(continueSetUpModel: HomePage.Models.ContinueSetUpModel, appearancePreferences: AppearancePreferences = .shared) {
        self.continueSetUpModel = continueSetUpModel
        self.appearancePreferences = appearancePreferences
    }

    var isViewExpanded: Bool {
        get {
            continueSetUpModel.shouldShowAllFeatures
        }
        set {
            continueSetUpModel.shouldShowAllFeatures = newValue
        }
    }

    var isViewExpandedPublisher: AnyPublisher<Bool, Never> {
        continueSetUpModel.shouldShowAllFeaturesPublisher.eraseToAnyPublisher()
    }

    var cards: [NewTabPageNextStepsCardsClient.CardID] {
        guard !appearancePreferences.isContinueSetUpCardsViewOutdated else {
            return []
        }
        return continueSetUpModel.featuresMatrix.flatMap { $0.map(NewTabPageNextStepsCardsClient.CardID.init) }
    }

    var cardsPublisher: AnyPublisher<[NewTabPageNextStepsCardsClient.CardID], Never> {
        let features = continueSetUpModel.$featuresMatrix.dropFirst().removeDuplicates()
        let cardsDidBecomeOutdated = appearancePreferences.$isContinueSetUpCardsViewOutdated.removeDuplicates()

        return Publishers.CombineLatest(features, cardsDidBecomeOutdated)
            .map { features, isOutdated -> [NewTabPageNextStepsCardsClient.CardID] in
                guard !isOutdated else {
                    return []
                }
                return features.flatMap { $0.map(NewTabPageNextStepsCardsClient.CardID.init) }
            }
            .eraseToAnyPublisher()
    }

    @MainActor
    func handleAction(for card: NewTabPageNextStepsCardsClient.CardID) {
        continueSetUpModel.performAction(for: .init(card))
    }

    @MainActor
    func dismiss(_ card: NewTabPageNextStepsCardsClient.CardID) {
        continueSetUpModel.removeItem(for: .init(card))
    }

    @MainActor
    func willDisplayCards(_ cards: [NewTabPageNextStepsCardsClient.CardID]) {
        appearancePreferences.continueSetUpCardsViewDidAppear()
        fireAddToDockPixelIfNeeded(cards)
    }

    private func fireAddToDockPixelIfNeeded(_ cards: [NewTabPageNextStepsCardsClient.CardID]) {
        guard cards.contains(.addAppToDockMac) else {
            return
        }
        PixelKit.fire(GeneralPixel.addToDockNewTabPageCardPresented,
                      frequency: .uniqueByName,
                      includeAppVersionParameter: false)
    }
}

extension HomePage.Models.FeatureType {
    init(_ card: NewTabPageNextStepsCardsClient.CardID) {
        switch card {
        case .bringStuff:
            self = .importBookmarksAndPasswords
        case .defaultApp:
            self = .defaultBrowser
        case .emailProtection:
            self = .emailProtection
        case .duckplayer:
            self = .duckplayer
        case .addAppToDockMac:
            self = .dock
        }
    }
}

extension NewTabPageNextStepsCardsClient.CardID {
    init(_ feature: HomePage.Models.FeatureType) {
        switch feature {
        case .duckplayer:
            self = .duckplayer
        case .emailProtection:
            self = .emailProtection
        case .defaultBrowser:
            self = .defaultApp
        case .dock:
            self = .addAppToDockMac
        case .importBookmarksAndPasswords:
            self = .bringStuff
        }
    }
}
