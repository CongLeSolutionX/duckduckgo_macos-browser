//
//  TargetSourcesChecker.swift
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

import Foundation

struct NoTargetsFoundError: Error {}

struct ExtraFilesInconsistencyError: Error {
    var target: String
    var unexpected: [InputFile]
    var superfluous: [InputFile]
    var unrelated: [InputFile]
    var file: StaticString
    var line: Int
    var column: Int

    init(
        target: String,
        actual: Set<InputFile>,
        expected: Set<InputFile>,
        unrelated: Set<InputFile>,
        file: StaticString = #file,
        line: Int = #line,
        column: Int = #column
    ) {
        self.target = target
        self.unexpected = actual.subtracting(expected).sorted()
        self.superfluous = expected.subtracting(actual).subtracting(unrelated).sorted()
        self.unrelated = unrelated.sorted()
        self.file = file
        self.line = line
        self.column = column
    }

    var localizedDescription: String {
        var description = [String]()
        if !unexpected.isEmpty {
            let files = unexpected.map(\.fileName).joined(separator: ", ")
            description.append("""
            \(target) includes files not present in other app targets. If this is expected, add these files to extraInputFiles in InputFilesChecker.swift:
            \t\(files)
            \t^~~~
            """)
        }
        if !superfluous.isEmpty {
            let files = superfluous.map(\.fileName).joined(separator: ", ")
            description.append("""
            \(target) includes files that are included by all app targets. Remove these files from extraInputFiles in InputFilesChecker.swift:
            \t\(files)
            \t^~~~
            """)
        }
        if !unrelated.isEmpty {
            let files = unrelated.map(\.fileName).joined(separator: ", ")
            description.append("""
            \(target) does not include files that are specified in extraInputFiles. Remove these files from extraInputFiles in InputFilesChecker.swift:
            \t\(files)
            \t^~~~
            """)
        }
        return description.map({ $0.formattedForLogBeautifier(file, line, column) }).joined(separator: "\n")
    }
}

extension String {
    func formattedForLogBeautifier(
        _ file: StaticString = #file,
        _ line: Int = #line,
        _ column: Int = #column
    ) -> String {
        return "\(file):\(line):\(column): error: \(self)"
    }
}