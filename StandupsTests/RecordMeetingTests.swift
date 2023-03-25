//
//  RecordMeetingTests.swift
//  StandupsTests
//
//  Created by bruno on 27/02/23.
//

import XCTest
import Dependencies
@testable import Standups

final class RecordMeetingTests: XCTestCase {
    func testTimer() async {
        await withDependencies({ $0.continuousClock = ImmediateClock() }) { @MainActor in
            var standup = Standup.mock
            standup.duration = .seconds(6)
            let recordModel = RecordMeetingModel(standup: standup)
            let expectation = self.expectation(description: "onMeetingFinished")
            recordModel.onMeetingFinished = { _ in expectation.fulfill() }
            
            await recordModel.task()
            self.wait(for: [expectation], timeout: 0)
            XCTAssertEqual(recordModel.secondsElapsed, 6)
            XCTAssertEqual(recordModel.dismiss, true)
        }
    }
}
