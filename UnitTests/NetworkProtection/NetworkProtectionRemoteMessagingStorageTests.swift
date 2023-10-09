//
//  NetworkProtectionRemoteMessagingStorageTests.swift
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

import XCTest
@testable import DuckDuckGo_Privacy_Browser

final class NetworkProtectionRemoteMessagingStorageTests: XCTestCase {

    private let temporaryFileURL: URL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json", isDirectory: false)
    private var defaults: UserDefaults!
    private let testGroupName = "remote-messaging-storage"

    override func setUp() {
        try? FileManager.default.removeItem(at: temporaryFileURL)
        defaults = UserDefaults(suiteName: testGroupName)!
        defaults.removePersistentDomain(forName: testGroupName)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: temporaryFileURL)
    }

    func testWhenStoringMessages_ThenMessagesCanBeReadFromDisk() throws {
        let storage = DefaultNetworkProtectionRemoteMessagingStorage(userDefaults: defaults, messagesURL: temporaryFileURL)
        let message = mockMessage(id: "123")
        try storage.store(messages: [message])
        let storedMessages = storage.storedMessages()

        XCTAssertEqual(storedMessages, [message])
    }

    func testWhenStoringMessages_ThenOldMessagesAreOverwritten() throws {
        let storage = DefaultNetworkProtectionRemoteMessagingStorage(userDefaults: defaults, messagesURL: temporaryFileURL)

        let message1 = mockMessage(id: "123")
        let message2 = mockMessage(id: "456")

        try storage.store(messages: [message1])
        try storage.store(messages: [message2])
        let storedMessages = storage.storedMessages()

        XCTAssertEqual(storedMessages, [message2])
    }

    private func mockMessage(id: String) -> NetworkProtectionRemoteMessage {
        let remoteMessageJSON = """
        {
            "id": "\(id)",
            "daysSinceNetworkProtectionEnabled": 0,
            "cardTitle": "Title",
            "cardDescription": "Description",
            "cardAction": "Action",
            "surveyURL": "https://duckduckgo.com/"
        }
        """

        let decoder = JSONDecoder()
        return try! decoder.decode(NetworkProtectionRemoteMessage.self, from: remoteMessageJSON.data(using: .utf8)!)
    }

}