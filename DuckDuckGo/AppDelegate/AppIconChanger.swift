//
//  AppIconChanger.swift
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

import Cocoa
import Combine

final class AppIconChanger {

    init(internalUserDecider: InternalUserDeciding) {
        subscribeToIsInternal(internalUserDecider)
    }

    enum Icons: String {
        case internalChannelIcon = "InternalChannelIcon"
    }

    func updateIcon(isInternalChannel: Bool) {
#if DEBUG || REVIEW
        return
#else
        let icon: NSImage?
        if isInternalChannel {
            icon = NSImage(named: Icons.internalChannelIcon.rawValue)
        } else {
            icon = nil
        }

        NSApplication.shared.applicationIconImage = icon
#endif
    }

    private var isInternalCancellable: AnyCancellable?

    private func subscribeToIsInternal(_ internalUserDecider: InternalUserDeciding) {
        isInternalCancellable = internalUserDecider.isInternalUserPublisher
            .sink { [weak self] isInternal in
                self?.updateIcon(isInternalChannel: isInternal)
            }
    }

}