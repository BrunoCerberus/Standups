//
//  StandupDetail.swift
//  Standups
//
//  Created by bruno on 19/01/23.
//

import SwiftUI
import SwiftUINavigation

final class StandupDetailModel: ObservableObject {
    enum Destination {
        case meeting(Meeting)
    }
    
    @Published var destination: Destination?
    @Published var standup: Standup
    
    init(
        destination: Destination? = nil,
        standup: Standup
    ) {
        self.destination = destination
        self.standup = standup
    }
    
    func deleteMeetings(atOffsets indices: IndexSet) {
        self.standup.meetings.remove(atOffsets: indices)
    }
    
    func meetingTapped(_ meeting: Meeting) {
        destination = .meeting(meeting)
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
                            self.model.meetingTapped(meeting)
                        } label: {
                            HStack {
                                Image(systemName: "calendar")
                                Text(meeting.date, style: .date)
                                Text(meeting.date, style: .time)
                            }
                        }
                    }
                    .onDelete { indices in
                        self.model.deleteMeetings(atOffsets: indices)
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
        .navigationDestination(
            // another way to define a Binding<T>
            unwrapping: Binding<StandupDetailModel.Destination?>.init(
                get: { self.model.destination },
                set: { self.model.destination = $0 }
            ),
            case: /StandupDetailModel.Destination.meeting
        ) { $meeting in
            MeetingView(meeting: meeting, standup: self.model.standup)
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

struct MeetingView: View {
  let meeting: Meeting
  let standup: Standup

  var body: some View {
    ScrollView {
      VStack(alignment: .leading) {
        Divider()
          .padding(.bottom)
        Text("Attendees")
          .font(.headline)
        ForEach(self.standup.attendees) { attendee in
          Text(attendee.name)
        }
        Text("Transcript")
          .font(.headline)
          .padding(.top)
        Text(self.meeting.transcript)
      }
    }
    .navigationTitle(
      Text(self.meeting.date, style: .date)
    )
    .padding()
  }
}
