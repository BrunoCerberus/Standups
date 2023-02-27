//
//  StandupListTests.swift
//  StandupsTests
//
//  Created by bruno on 27/02/23.
//

import XCTest
@testable import Standups

@MainActor
final class StandupListTests: XCTestCase {
    
    // For each test it executes in order to remove all persisted standups
    override class func setUp() {
        super.setUp()
        let fileManager = FileManager.default
        try? fileManager.removeItem(at: .standups)
    }
    
    func testPersistence() async {
        let listModel = StandupsListModel()
        
        XCTAssertEqual(listModel.standups.count, 0)
        
        listModel.addStandupButtonTapped()
        listModel.confirmAddStandupButtonTapped()
        XCTAssertEqual(listModel.standups.count, 1)
        
        try? await Task.sleep(for: .seconds(1))
        
        let nextLaunchListModel = StandupsListModel()
        XCTAssertEqual(nextLaunchListModel.standups.count, 1)
    }
}
