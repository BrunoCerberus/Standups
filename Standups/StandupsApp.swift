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
            StandupsList(
                model: StandupsListModel(
                    destination: .detail(StandupDetailModel(
                        destination: .alert(.delete),
                        standup: .mock
                    )),
                    standups: [
                        .mock,
                    ]
                )
            )
            .preferredColorScheme(.dark)
        }
    }
}
