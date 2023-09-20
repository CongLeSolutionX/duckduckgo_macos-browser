//
//  DataBrokerProtectionViewController.swift
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
import SwiftUI

final public class DataBrokerProtectionViewController: NSViewController {
    private let navigationViewModel: ContainerNavigationViewModel
    private let profileViewModel: ProfileViewModel
    private let dataManager: DataBrokerProtectionDataManaging
    private let resultsViewModel: ResultsViewModel
    private let containerViewModel: ContainerViewModel
    private let scheduler: DataBrokerProtectionScheduler
    private let notificationCenter: NotificationCenter

    public init(scheduler: DataBrokerProtectionScheduler,
                dataManager: DataBrokerProtectionDataManaging,
                notificationCenter: NotificationCenter = .default) {
        self.scheduler = scheduler
        self.dataManager = dataManager
        self.notificationCenter = notificationCenter

        navigationViewModel = ContainerNavigationViewModel(dataManager: dataManager)
        profileViewModel = ProfileViewModel(dataManager: dataManager)

        resultsViewModel = ResultsViewModel(dataManager: dataManager,
                                            notificationCenter: notificationCenter)

        containerViewModel = ContainerViewModel(scheduler: scheduler,
                                                dataManager: dataManager)

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func loadView() {
        let containerView = DataBrokerProtectionContainerView(
            containerViewModel: containerViewModel,
            navigationViewModel: navigationViewModel,
            profileViewModel: profileViewModel,
            resultsViewModel: resultsViewModel)

        let hostingController = NSHostingController(rootView: containerView)
        view = hostingController.view
    }

}