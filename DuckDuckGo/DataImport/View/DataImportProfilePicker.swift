//
//  DataImportProfilePicker.swift
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

import SwiftUI

struct DataImportProfilePicker: View {

    private let profiles: [DataImport.BrowserProfile]
    @Binding private var selectedProfile: DataImport.BrowserProfile?
    private let shouldDisplayFolderName: Bool

    init(profileList: DataImport.BrowserProfileList?, selectedProfile: Binding<DataImport.BrowserProfile?>) {
        self.profiles = profileList?.validImportableProfiles ?? []
        self._selectedProfile = selectedProfile
        shouldDisplayFolderName = Set(self.profiles.map {
            $0.profileURL.deletingLastPathComponent()
        }).count > 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Select Profile:", comment: "Browser Profile picker title for Data Import")
                .bold()

            Picker(selection: Binding {
                selectedProfile.flatMap(profiles.firstIndex(of:)) ?? 0
            } set: {
                selectedProfile = profiles[safe: $0]
            }) {
                ForEach(profiles.indices, id: \.self) { idx in
                    // display profiles folder name if multiple profiles folders are present (Chrome, Chrome Canary…)
                    if shouldDisplayFolderName {
                        Text(profiles[idx].profileName + "  ")
                        + Text(profiles[idx].profileURL
                            .deletingLastPathComponent().lastPathComponent)
                            .font(.system(size: 10))
                            .fontWeight(.light)
                    } else {
                        Text(profiles[idx].profileName)
                    }
                }
            } label: {}
                .pickerStyle(.menu)
                .controlSize(.large)
        }
    }

}

#Preview {
    DataImportProfilePicker(profileList: .init(browser: .chrome, profiles: [
        .init(browser: .chrome,
              profileURL: URL(fileURLWithPath: "/Chrome/Default Profile")),
        .init(browser: .chrome,
              profileURL: URL(fileURLWithPath: "/Chrome Dev/Profile 1")),
        .init(browser: .chrome,
              profileURL: URL(fileURLWithPath: "/Chrome Canary/Profile 2")),
    ], validateProfileData: { _ in { .init(logins: .available, bookmarks: .available) } }), selectedProfile: Binding {
        .init(browser: .chrome,
              profileURL: URL(fileURLWithPath: "/test/Profile 1"))
    } set: {
        print("Profile selected:", $0?.profileURL.lastPathComponent ?? "<nil>")
    })
    .padding()
    .frame(width: 512)
    .font(.system(size: 13))
}