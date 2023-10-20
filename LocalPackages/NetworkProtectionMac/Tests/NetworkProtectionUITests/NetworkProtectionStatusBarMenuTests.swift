//
//  NetworkProtectionStatusBarMenuTests.swift
//
//  Copyright © 2023 DuckDuckGo. All rights reserved.
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

import Foundation
import Combine
import SwiftUI
import NetworkProtection
import XCTest
@testable import NetworkProtectionUI
import NetworkProtectionTestUtils

final class StatusBarMenuTests: XCTestCase {

    private final class TestTunnelController: TunnelController {
        func start() async {
            // no-op
        }

        func stop() async {
            // no-op
        }
    }

    @MainActor
    func testShowStatusBarMenu() {
        let item = NSStatusItem()
        let menu = StatusBarMenu(
            statusItem: item,
            onboardingStatusPublisher: Just(OnboardingStatus.completed).eraseToAnyPublisher(),
            statusReporter: MockNetworkProtectionStatusReporter(),
            controller: TestTunnelController(),
            iconProvider: MenuIconProvider(),
            menuItems: [])

        menu.show()

        XCTAssertTrue(item.isVisible)
    }

    @MainActor
    func testHideStatusBarMenu() {
        let item = NSStatusItem()
        let menu = StatusBarMenu(
            statusItem: item,
            onboardingStatusPublisher: Just(OnboardingStatus.completed).eraseToAnyPublisher(),
            statusReporter: MockNetworkProtectionStatusReporter(),
            controller: TestTunnelController(),
            iconProvider: MenuIconProvider(),
            menuItems: [])

        menu.hide()

        XCTAssertFalse(item.isVisible)
    }
}