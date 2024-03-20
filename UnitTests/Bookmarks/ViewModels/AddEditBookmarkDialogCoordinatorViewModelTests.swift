//
//  AddEditBookmarkDialogCoordinatorViewModelTests.swift
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
import Combine
@testable import DuckDuckGo_Privacy_Browser

@MainActor
final class AddEditBookmarkDialogCoordinatorViewModelTests: XCTestCase {
    private var sut: AddEditBookmarkDialogCoordinatorViewModel<AddEditBookmarkDialogViewModelMock, AddEditBookmarkFolderDialogViewModelMock>!
    private var bookmarkViewModelMock: AddEditBookmarkDialogViewModelMock!
    private var bookmarkFolderViewModelMock: AddEditBookmarkFolderDialogViewModelMock!
    private var cancellables: Set<AnyCancellable>!

    override func setUpWithError() throws {
        try super.setUpWithError()

        cancellables = []
        bookmarkViewModelMock = .init()
        bookmarkFolderViewModelMock = .init()
        sut = .init(bookmarkModel: bookmarkViewModelMock, folderModel: bookmarkFolderViewModelMock)
    }

    override func tearDownWithError() throws {
        cancellables = nil
        bookmarkViewModelMock = nil
        bookmarkFolderViewModelMock = nil
        sut = nil
        try super.tearDownWithError()
    }

    func testShouldReturnViewStateBookmarkWhenInit() {
        XCTAssertEqual(sut.viewState, .bookmark)
    }

    func testShouldReturnViewStateBookmarkWhenDismissActionIsCalled() {
        // GIVEN
        sut.addFolderAction()
        XCTAssertEqual(sut.viewState, .folder)

        // WHEN
        sut.dismissAction()

        // THEN
        XCTAssertEqual(sut.viewState, .bookmark)

    }

    func testShouldSetSelectedFolderOnFolderViewModelAndReturnFolderViewStateWhenAddFolderActionIsCalled() {
        // GIVEN
        let folder = BookmarkFolder(id: "1", title: "Folder")
        bookmarkViewModelMock.selectedFolder = folder
        XCTAssertNil(bookmarkFolderViewModelMock.selectedFolder)

        // WHEN
        sut.addFolderAction()

        // THEN
        XCTAssertEqual(bookmarkFolderViewModelMock.selectedFolder, folder)
    }

    func testShouldReceiveEventsWhenBookmarkModelChanges() {
        // GIVEN
        let expectation = self.expectation(description: #function)
        var didCallChangeValue = false
        sut.objectWillChange.sink { _ in
            didCallChangeValue = true
            expectation.fulfill()
        }
        .store(in: &cancellables)

        // WHEN
        sut.bookmarkModel.objectWillChange.send()

        // THEN
        waitForExpectations(timeout: 1.0)
        XCTAssertTrue(didCallChangeValue)
    }

    func testShouldReceiveEventsWhenBookmarkFolderModelChanges() {
        // GIVEN
        let expectation = self.expectation(description: #function)
        var didCallChangeValue = false
        sut.objectWillChange.sink { _ in
            didCallChangeValue = true
            expectation.fulfill()
        }
        .store(in: &cancellables)

        // WHEN
        sut.folderModel.objectWillChange.send()

        // THEN
        waitForExpectations(timeout: 1.0)
        XCTAssertTrue(didCallChangeValue)
    }

    func testShouldSetSelectedFolderOnBookmarkViewModelWhenAddFolderPublisherSendsEvent() {
        // GIVEN
        let expectation = self.expectation(description: #function)
        bookmarkViewModelMock.selectedFolderExpectation = expectation
        let folder = BookmarkFolder(id: "ABCDE", title: #function)
        XCTAssertNil(bookmarkViewModelMock.selectedFolder)

        // WHEN
        sut.folderModel.subject.send(folder)

        // THEN
        waitForExpectations(timeout: 1.0)
        XCTAssertEqual(bookmarkViewModelMock.selectedFolder, folder)
    }

}

final class AddEditBookmarkDialogViewModelMock: BookmarkDialogEditing {
    var bookmarkName: String = ""
    var bookmarkURLPath: String = ""
    var isBookmarkFavorite: Bool = false
    var isURLFieldHidden: Bool = false
    var title: String = ""
    var folders: [DuckDuckGo_Privacy_Browser.FolderViewModel] = []
    var selectedFolder: DuckDuckGo_Privacy_Browser.BookmarkFolder? {
        didSet {
            selectedFolderExpectation?.fulfill()
        }
    }
    var cancelActionTitle: String = ""
    var isOtherActionDisabled: Bool = false
    var defaultActionTitle: String = ""
    var isDefaultActionDisabled: Bool = false

    func cancel(dismiss: () -> Void) {}
    func addOrSave(dismiss: () -> Void) {}

    var selectedFolderExpectation: XCTestExpectation?
}

final class AddEditBookmarkFolderDialogViewModelMock: BookmarkFolderDialogEditing {
    let subject = PassthroughSubject<BookmarkFolder, Never>()

    var addFolderPublisher: AnyPublisher<DuckDuckGo_Privacy_Browser.BookmarkFolder, Never> {
        subject.eraseToAnyPublisher()
    }
    var folderName: String = ""
    var title: String = ""
    var folders: [DuckDuckGo_Privacy_Browser.FolderViewModel] = []
    var selectedFolder: DuckDuckGo_Privacy_Browser.BookmarkFolder?
    var cancelActionTitle: String = ""
    var isOtherActionDisabled: Bool = false
    var defaultActionTitle: String = ""
    var isDefaultActionDisabled: Bool = false

    func cancel(dismiss: () -> Void) {}
    func addOrSave(dismiss: () -> Void) {}
}