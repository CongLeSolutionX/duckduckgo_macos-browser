//
//  DataBrokerProtectionMigrationsFeatureFlaggerTests.swift
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

import XCTest
@testable import DataBrokerProtection

private final class MockDateRangeChecker: DateRangeChecker {

    private let startDateComponents: DateComponents
    private let endDateComponents: DateComponents

    init(startDateComponents: DateComponents, endDateComponents: DateComponents) {
        self.startDateComponents = startDateComponents
        self.endDateComponents = endDateComponents
    }

    func isWithinRange(date: Date) -> Bool {
        let calendar = Calendar.current

        guard let startDate = calendar.date(from: startDateComponents),
              let endDate = calendar.date(from: endDateComponents) else {
            return false
        }

        return (startDate...endDate).contains(date)
    }
}

extension MockDateRangeChecker {
    static var inthePast: MockDateRangeChecker {

        var startDateComponents = DateComponents()
        startDateComponents.year = 2020
        startDateComponents.month = 7
        startDateComponents.day = 25

        var endDateComponents = DateComponents()
        endDateComponents.year = 2020
        endDateComponents.month = 8
        endDateComponents.day = 2

        return MockDateRangeChecker(startDateComponents: startDateComponents, endDateComponents: endDateComponents)
    }
}

final class DataBrokerProtectionMigrationsFeatureFlaggerTests: XCTestCase {

    private var userDefaults: UserDefaults!
    private let key = DefaultDataBrokerProtectionMigrationsFeatureFlagger.Constants.v3MigrationFeatureFlagValue

    override func setUp() {
        super.setUp()
        userDefaults = UserDefaults(suiteName: "mockDefaults")
        userDefaults.removePersistentDomain(forName: "mockDefaults")
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: "mockDefaults")
        userDefaults = nil
        super.tearDown()
    }

    func testRandomNumberGeneration() {
        // Given
        let sut = DefaultDataBrokerProtectionMigrationsFeatureFlagger(userDefaults: userDefaults,
                                                                      dateRangeChecker: MockDateRangeChecker.inthePast)
        XCTAssertNil(userDefaults.object(forKey: key))

        // When
        _ = sut.isUserIn(percent: 10)

        // Then
        XCTAssertNotNil(userDefaults.object(forKey: key))
    }

    func testRandomNumberGenerationAndReuse() {
        // Given
        let sut = DefaultDataBrokerProtectionMigrationsFeatureFlagger(userDefaults: userDefaults,
                                                                      dateRangeChecker: MockDateRangeChecker.inthePast)
        XCTAssertNil(userDefaults.object(forKey: key))

        // When
        let resultOne = sut.isUserIn(percent: 10)

        // Then
        XCTAssertNotNil(userDefaults.object(forKey: key))

        // When
        let resultTwo = sut.isUserIn(percent: 10)

        // Then
        XCTAssertEqual(resultOne, resultTwo)
    }

    func testInPercentLogicForInputValue0AndPercent0() {
        // Given
        userDefaults.set(0, forKey: key)
        let sut = DefaultDataBrokerProtectionMigrationsFeatureFlagger(userDefaults: userDefaults,
                                                                      dateRangeChecker: MockDateRangeChecker.inthePast)

        // When
        let result = sut.isUserIn(percent: 0)

        // Then
        XCTAssertEqual(userDefaults.object(forKey: key) as? Int, 0)
        XCTAssertTrue(result)
    }

    func testInPercentLogicForInputValue0AndPercent1() {
        // Given
        userDefaults.set(0, forKey: key)
        let sut = DefaultDataBrokerProtectionMigrationsFeatureFlagger(userDefaults: userDefaults,
                                                                      dateRangeChecker: MockDateRangeChecker.inthePast)

        // When
        let result = sut.isUserIn(percent: 1)

        // Then
        XCTAssertEqual(userDefaults.object(forKey: key) as? Int, 0)
        XCTAssertTrue(result)
    }

    func testInPercentLogicForInputValue10AndPercent10() {
        // Given
        userDefaults.set(10, forKey: key)
        let sut = DefaultDataBrokerProtectionMigrationsFeatureFlagger(userDefaults: userDefaults,
                                                                      dateRangeChecker: MockDateRangeChecker.inthePast)

        // When
        let result = sut.isUserIn(percent: 10)

        // Then
        XCTAssertEqual(userDefaults.object(forKey: key) as? Int, 10)
        XCTAssertTrue(result)
    }

    func testInPercentLogicForInputValue15AndPercent10() {
        // Given
        userDefaults.set(15, forKey: key)
        let sut = DefaultDataBrokerProtectionMigrationsFeatureFlagger(userDefaults: userDefaults,
                                                                      dateRangeChecker: MockDateRangeChecker.inthePast)

        // When
        let result = sut.isUserIn(percent: 10)

        // Then
        XCTAssertEqual(userDefaults.object(forKey: key) as? Int, 15)
        XCTAssertFalse(result)
    }

    func testInPercentLogicForInputValue99AndPercent100() {
        // Given
        userDefaults.set(99, forKey: key)
        let sut = DefaultDataBrokerProtectionMigrationsFeatureFlagger(userDefaults: userDefaults,
                                                                      dateRangeChecker: MockDateRangeChecker.inthePast)

        // When
        let result = sut.isUserIn(percent: 100)

        // Then
        XCTAssertEqual(userDefaults.object(forKey: key) as? Int, 99)
        XCTAssertTrue(result)
    }

    func testInPercentLogicForInputValue100AndPercent99() {
        // Given
        userDefaults.set(100, forKey: key)
        let sut = DefaultDataBrokerProtectionMigrationsFeatureFlagger(userDefaults: userDefaults,
                                                                      dateRangeChecker: MockDateRangeChecker.inthePast)

        // When
        let result = sut.isUserIn(percent: 99)

        // Then
        XCTAssertEqual(userDefaults.object(forKey: key) as? Int, 100)
        XCTAssertFalse(result)
    }

    func testInPercentLogicForInputValue100AndPercent100() {
        // Given
        userDefaults.set(100, forKey: key)
        let sut = DefaultDataBrokerProtectionMigrationsFeatureFlagger(userDefaults: userDefaults,
                                                                      dateRangeChecker: MockDateRangeChecker.inthePast)

        // When
        let result = sut.isUserIn(percent: 100)

        // Then
        XCTAssertEqual(userDefaults.object(forKey: key) as? Int, 100)
        XCTAssertTrue(result)
    }

    func testAverageCalculatedRandomNumberAssignmentIsBetween9And11Percent() {
        // Given
        var percentages: [Double] = []

        // When
        repeat {
            var results: [Bool] = []

            repeat {
                userDefaults.set(nil, forKey: key)
                let sut = DefaultDataBrokerProtectionMigrationsFeatureFlagger(userDefaults: userDefaults,
                                                                              dateRangeChecker: MockDateRangeChecker.inthePast)
                let result = sut.isUserIn(percent: 10)
                results.append(result)
            } while results.count < 100

            let totalCount = Double(results.count)
            let trueValueCount = Double(results.filter { $0 == true }.count)

            let percentage = trueValueCount/totalCount * 100

            percentages.append(percentage)

        } while percentages.count < 100

        // Then
        let sum = percentages.reduce(0, +)
        let average = sum / Double(percentages.count)
        XCTAssert(average > 9.0 && average < 11.0)
    }

    func testDateWithinDefaultTemporaryWindowReturnsTrue() {
        // Given
        userDefaults.set(100, forKey: key)
        let sut = DefaultDataBrokerProtectionMigrationsFeatureFlagger(userDefaults: userDefaults)

        // When
        let result = sut.isUserIn(percent: 99)

        // Then
        XCTAssertEqual(userDefaults.object(forKey: key) as? Int, 100)
        XCTAssertTrue(result)
    }

    func testDateWithinPastWindowReturnsFalse() {
        // Given
        userDefaults.set(100, forKey: key)
        let sut = DefaultDataBrokerProtectionMigrationsFeatureFlagger(userDefaults: userDefaults,
                                                                      dateRangeChecker: MockDateRangeChecker.inthePast)

        // When
        let result = sut.isUserIn(percent: 99)

        // Then
        XCTAssertEqual(userDefaults.object(forKey: key) as? Int, 100)
        XCTAssertFalse(result)
    }
}