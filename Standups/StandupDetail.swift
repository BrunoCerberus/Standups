//
//  StandupDetail.swift
//  Standups
//
//  Created by bruno on 19/01/23.
//

import SwiftUI

final class StandupDetailModel: ObservableObject {
    @Published var standup: Standup
    
    init(standup: Standup) {
        self.standup = standup
    }
}

struct StandupDetailView: View {
    @ObservedObject var model: StandupDetailModel
    
    var body: some View {
        List {
            Section {
                Button {
                } label: {
                    Label("Start Meeting", systemImage: "timer")
                        .font(.headline)
                        .foregroundColor(.accentColor)
                }
                HStack {
                    Label("Length", systemImage: "clock")
                    Spacer()
                    Text(self.model.standup.duration.formatted(
                        .units())
                    )
                }
                
                HStack {
                    Label("Theme", systemImage: "paintpalette")
                    Spacer()
                    Text(self.model.standup.theme.name)
                        .padding(4)
                        .foregroundColor(
                            self.model.standup.theme.accentColor
                        )
                        .background(self.model.standup.theme.mainColor)
                        .cornerRadius(4)
                }
            } header: {
                Text("Standup Info")
            }
            
            if !self.model.standup.meetings.isEmpty {
                Section {
                    ForEach(self.model.standup.meetings) { meeting in
                        Button {
                        } label: {
                            HStack {
                                Image(systemName: "calendar")
                                Text(meeting.date, style: .date)
                                Text(meeting.date, style: .time)
                            }
                        }
                    }
                    .onDelete { indices in
                    }
                } header: {
                    Text("Past meetings")
                }
            }
            
            Section {
                ForEach(self.model.standup.attendees) { attendee in
                    Label(attendee.name, systemImage: "person")
                }
            } header: {
                Text("Attendees")
            }
            
            Section {
                Button("Delete") {
                }
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle(self.model.standup.title)
        .toolbar {
            Button("Edit") {
            }
        }
    }
}

struct StandupDetail_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            StandupDetailView(model: StandupDetailModel(standup: .mock))
        }
        .preferredColorScheme(.dark)
    }
}
