//
//  CookieNotificationAnimationModel.swift
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

final class CookieNotificationAnimationModel: ObservableObject {
    enum AnimationState {
        case unstarted
        case firstPhase
        case secondPhase
    }

    @Published var state: AnimationState = .unstarted

    let duration: CGFloat
    let secondPhaseDelay: CGFloat
    let halfDuration: CGFloat

    init(duration: CGFloat = AnimationDefaultConsts.totalDuration) {
        self.duration = duration
        self.halfDuration = duration / 2.0
        self.secondPhaseDelay = self.halfDuration
    }
}

private enum AnimationDefaultConsts {
    static let totalDuration: CGFloat = 0.9
}