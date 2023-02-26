//
//  StandupsApp.swift
//  Standups
//
//  Created by bruno on 15/01/23.
//

import SwiftUI

@main
struct StandupsApp: App {
    var body: some Scene {
        WindowGroup {
            var standup = Standup.mock
            let _ = standup.duration = .seconds(1)
            let _ = standup.attendees = [
                Attendee(id: Attendee.ID(UUID()), name: "Bob")
            ]
            
            StandupsList(
                model: StandupsListModel(
//                    destination: .detail(StandupDetailModel(
//                        destination: .record(RecordMeetingModel(standup: standup)),
//                        standup: standup
//                    ))
//                    destination: .detail(StandupDetailModel(
//                        destination: .record(RecordMeetingModel(standup: standup)),
//                        standup: standup
//                    )),
//                    standups: [
//                        standup,
//                    ]
                )
            )
            .preferredColorScheme(.dark)
        }
    }
}
