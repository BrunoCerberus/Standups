//
//  StandupListTests.swift
//  StandupsTests
//
//  Created by bruno on 27/02/23.
//

import XCTest
import Dependencies
@testable import Standups

@MainActor
final class StandupListTests: XCTestCase {
    
    // For each test it executes in order to remove all persisted standups
    override class func setUp() {
        super.setUp()
        let fileManager = FileManager.default
        try? fileManager.removeItem(at: .standups)
    }
    
    func testPersistence() async throws {
        let testQueue = DispatchQueue.test
        withDependencies({ $0.mainQueue = testQueue.eraseToAnyScheduler() }) {
            let listModel = StandupsListModel()
            XCTAssertEqual(listModel.standups.count, 0)
            
            listModel.addStandupButtonTapped()
            listModel.confirmAddStandupButtonTapped()
            XCTAssertEqual(listModel.standups.count, 1)
            
            testQueue.advance(by: .seconds(1))
            
            let nextLaunchListModel = StandupsListModel()
            XCTAssertEqual(nextLaunchListModel.standups.count, 1)
        }
    }
}
