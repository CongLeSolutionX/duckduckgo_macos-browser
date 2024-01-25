//
//  VPNLocationsHostingViewController.swift
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

#if NETWORK_PROTECTION

import AppKit
import SwiftUI

final class VPNLocationsHostingViewController: NSHostingController<VPNLocationView> {
    private let viewModel: VPNLocationViewModel

    init() {
        self.viewModel = VPNLocationViewModel()

        // Need access to self to call dismiss
        let initialView = VPNLocationView(model: self.viewModel, isPresented: .constant(false))
        super.init(rootView: initialView)
        let isPresented = Binding {
            true
        } set: { [weak self] isPresented in
            if !isPresented {
                self?.dismiss()
            }
        }
        self.rootView = VPNLocationView(model: self.viewModel, isPresented: isPresented)
    }

    @MainActor required dynamic init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

#endif