//
//  FirefoxBerkeleyDatabaseReader.swift
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

enum FirefoxBerkeleyDatabaseReaderError: Error {
    case failedToOpenDatabase
}

enum FirefoxBerkeleyDatabaseReader {

    static func readDatabase(at databasePath: String) throws -> [String: Data]? {
        let path = databasePath.cString(using: .utf8)

        let db = path?.withUnsafeBufferPointer({ pathPointer in
            return dbopen(pathPointer.baseAddress, O_RDONLY, O_RDONLY, DB_HASH, nil)
        })

        guard let db else {
            throw FirefoxBerkeleyDatabaseReaderError.failedToOpenDatabase
        }

        var results: [String: Data] = [:]

        var currentKeyDBT = DBT()
        var currentDataDBT = DBT()

        while db.pointee.seq(db, &currentKeyDBT, &currentDataDBT, UInt32(R_NEXT)) == 0 {
            let currentKeyData = currentKeyDBT.data.withMemoryRebound(to: UInt8.self, capacity: currentKeyDBT.size) { pointer in
                Data(bytes: pointer, count: currentKeyDBT.size)
            }
            let currentData = currentDataDBT.data.withMemoryRebound(to: UInt8.self, capacity: currentDataDBT.size) { pointer in
                Data(bytes: pointer, count: currentDataDBT.size)
            }

            let currentKeyHexadecimalString = currentKeyData.hexadecimalString
            let currentKeyString = String(bytes: currentKeyData, encoding: .utf8)

            if currentKeyHexadecimalString == Self.firefoxASN1Key {
                results["data"] = currentData
            } else if let currentKeyString {
                results[currentKeyString] = currentData
            }
        }

        return results
    }

    private static let firefoxASN1Key: String = "f8000000000000000000000000000001"
}

private extension Data {
    var hexadecimalString: String {
        Array(self).reduce(into: String()) { $0.append(String(format: "%02lx", $1)) }
    }
}