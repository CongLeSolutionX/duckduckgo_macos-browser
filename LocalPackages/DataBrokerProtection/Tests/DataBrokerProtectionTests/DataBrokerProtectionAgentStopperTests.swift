//
//  DataBrokerProtectionAgentStopperTests.swift
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

import Foundation
import XCTest
import Common

@testable import DataBrokerProtection

final class DataBrokerProtectionAgentStopperTests: XCTestCase {
   private var mockPixelHandler: EventMapping<DataBrokerProtectionPixels>!
   private var mockAuthenticationManager: MockAuthenticationManager!
   private var mockEntitlementMonitor: DataBrokerProtectionEntitlementMonitor!
   private var mockDataManager: MockDataBrokerProtectionDataManager!
   private var mockStopAction: MockDataProtectionStopAction!

    private var fakeProfile: DataBrokerProtectionProfile {
        let name = DataBrokerProtectionProfile.Name(firstName: "John", lastName: "Doe")
        let address = DataBrokerProtectionProfile.Address(city: "City", state: "State")

        return DataBrokerProtectionProfile(names: [name], addresses: [address], phones: [String](), birthYear: 1900)
    }

    override func setUp() {
        mockPixelHandler = MockDataBrokerProtectionPixelsHandler()
        mockAuthenticationManager = MockAuthenticationManager()
        mockPixelHandler = MockPixelHandler()
        mockEntitlementMonitor = DataBrokerProtectionEntitlementMonitor()
        mockDataManager = MockDataBrokerProtectionDataManager(pixelHandler: mockPixelHandler,
                                                              fakeBrokerFlag: DataBrokerDebugFlagFakeBroker())
        mockStopAction = MockDataProtectionStopAction()
    }

    override func tearDown() {
        mockPixelHandler = nil
        mockAuthenticationManager = nil
        mockPixelHandler = nil
        mockEntitlementMonitor = nil
        mockDataManager = nil
        mockStopAction = nil
    }

    func testNoProfile_thenStopAgentIsCalled() async {
        mockAuthenticationManager.isUserAuthenticatedValue = true
        mockAuthenticationManager.hasValidEntitlementValue = true
        mockDataManager.profileToReturn = nil

        let stopper = DefaultDataBrokerProtectionAgentStopper(dataManager: mockDataManager,
                                                              entitlementMonitor: mockEntitlementMonitor,
                                                              authenticationManager: mockAuthenticationManager,
                                                              pixelHandler: mockPixelHandler,
                                                              stopAction: mockStopAction)
        await stopper.validateRunPrerequisitesAndStopAgentIfNecessary()

        XCTAssertTrue(mockStopAction.wasStopCalled)
    }

    func testInvalidEntitlement_thenStopAgentIsCalled() async {
        mockAuthenticationManager.isUserAuthenticatedValue = true
        mockAuthenticationManager.hasValidEntitlementValue = false
        mockDataManager.profileToReturn = fakeProfile

        let stopper = DefaultDataBrokerProtectionAgentStopper(dataManager: mockDataManager,
                                                              entitlementMonitor: mockEntitlementMonitor,
                                                              authenticationManager: mockAuthenticationManager,
                                                              pixelHandler: mockPixelHandler,
                                                              stopAction: mockStopAction)
        await stopper.validateRunPrerequisitesAndStopAgentIfNecessary()

        XCTAssertTrue(mockStopAction.wasStopCalled)
    }

    func testUserNotAuthenticated_thenStopAgentIsCalled() async {
        mockAuthenticationManager.isUserAuthenticatedValue = false
        mockAuthenticationManager.hasValidEntitlementValue = true
        mockDataManager.profileToReturn = fakeProfile

        let stopper = DefaultDataBrokerProtectionAgentStopper(dataManager: mockDataManager,
                                                              entitlementMonitor: mockEntitlementMonitor,
                                                              authenticationManager: mockAuthenticationManager,
                                                              pixelHandler: mockPixelHandler,
                                                              stopAction: mockStopAction)
        await stopper.validateRunPrerequisitesAndStopAgentIfNecessary()

        XCTAssertTrue(mockStopAction.wasStopCalled)
    }

    func testErrorEntitlement_thenStopAgentIsNotCalled() async {
        mockAuthenticationManager.isUserAuthenticatedValue = true
        mockAuthenticationManager.shouldThrowEntitlementError = true
        mockDataManager.profileToReturn = fakeProfile

        let stopper = DefaultDataBrokerProtectionAgentStopper(dataManager: mockDataManager,
                                                              entitlementMonitor: mockEntitlementMonitor,
                                                              authenticationManager: mockAuthenticationManager,
                                                              pixelHandler: mockPixelHandler,
                                                              stopAction: mockStopAction)
        await stopper.validateRunPrerequisitesAndStopAgentIfNecessary()

        XCTAssertFalse(mockStopAction.wasStopCalled)
    }

    func testValidEntitlement_thenStopAgentIsNotCalled() async {
        mockAuthenticationManager.isUserAuthenticatedValue = true
        mockAuthenticationManager.hasValidEntitlementValue = true
        mockDataManager.profileToReturn = fakeProfile

        let stopper = DefaultDataBrokerProtectionAgentStopper(dataManager: mockDataManager,
                                                              entitlementMonitor: mockEntitlementMonitor,
                                                              authenticationManager: mockAuthenticationManager,
                                                              pixelHandler: mockPixelHandler,
                                                              stopAction: mockStopAction)
        await stopper.validateRunPrerequisitesAndStopAgentIfNecessary()

        XCTAssertFalse(mockStopAction.wasStopCalled)
    }

    func testEntitlementMonitorWithValidResult_thenStopAgentIsNotCalled() {
        mockAuthenticationManager.isUserAuthenticatedValue = true
        mockAuthenticationManager.hasValidEntitlementValue = true
        mockDataManager.profileToReturn = fakeProfile

        let stopper = DefaultDataBrokerProtectionAgentStopper(dataManager: mockDataManager,
                                                              entitlementMonitor: mockEntitlementMonitor,
                                                              authenticationManager: mockAuthenticationManager,
                                                              pixelHandler: mockPixelHandler,
                                                              stopAction: mockStopAction)

        let expectation = XCTestExpectation(description: "Wait for monitor")
        stopper.monitorEntitlementAndStopAgentIfEntitlementIsInvalid(interval: 0.1)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in
            XCTAssertFalse(mockStopAction.wasStopCalled)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 3)
    }

    func testEntitlementMonitorWithInValidResult_thenStopAgentIsCalled() {
        mockAuthenticationManager.isUserAuthenticatedValue = true
        mockAuthenticationManager.hasValidEntitlementValue = false
        mockDataManager.profileToReturn = fakeProfile

        let stopper = DefaultDataBrokerProtectionAgentStopper(dataManager: mockDataManager,
                                                              entitlementMonitor: mockEntitlementMonitor,
                                                              authenticationManager: mockAuthenticationManager,
                                                              pixelHandler: mockPixelHandler,
                                                              stopAction: mockStopAction)

        let expectation = XCTestExpectation(description: "Wait for monitor")
        stopper.monitorEntitlementAndStopAgentIfEntitlementIsInvalid(interval: 0.1)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in
            XCTAssertTrue(mockStopAction.wasStopCalled)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 3)
    }

    func testEntitlementMonitorWithErrorResult_thenStopAgentIsNotCalled() {
        mockAuthenticationManager.isUserAuthenticatedValue = true
        mockAuthenticationManager.shouldThrowEntitlementError = true
        mockDataManager.profileToReturn = fakeProfile

        let stopper = DefaultDataBrokerProtectionAgentStopper(dataManager: mockDataManager,
                                                              entitlementMonitor: mockEntitlementMonitor,
                                                              authenticationManager: mockAuthenticationManager,
                                                              pixelHandler: mockPixelHandler,
                                                              stopAction: mockStopAction)

        let expectation = XCTestExpectation(description: "Wait for monitor")
        stopper.monitorEntitlementAndStopAgentIfEntitlementIsInvalid(interval: 0.1)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in
            XCTAssertFalse(mockStopAction.wasStopCalled)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 3)
    }
}