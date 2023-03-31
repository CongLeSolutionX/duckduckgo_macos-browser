//
//  _WKDownload+WebKitDownload.swift
//
//  Copyright © 2021 DuckDuckGo. All rights reserved.
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
import Navigation
import WebKit

extension _WKDownload: WebKitDownload {
    private static let downloadDelegateKey = UnsafeRawPointer(bitPattern: "_WKDownloadDelegateKey".hashValue)!

    public var originalRequest: URLRequest? {
        request
    }

    public var webView: WKWebView? {
        originatingWebView
    }

    public var delegate: WKDownloadDelegate? {
        get {
            return (objc_getAssociatedObject(self, Self.downloadDelegateKey) as? WeakDownloadDelegateRef)?.delegate
        }
        set {
            objc_setAssociatedObject(self, Self.downloadDelegateKey, WeakDownloadDelegateRef(newValue), .OBJC_ASSOCIATION_RETAIN)
        }
    }

    final private class WeakDownloadDelegateRef: NSObject {
        weak var delegate: WKDownloadDelegate?
        init(_ delegate: WKDownloadDelegate?) {
            self.delegate = delegate
        }
    }

}