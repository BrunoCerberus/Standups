//
//  StandupDetail.swift
//  Standups
//
//  Created by bruno on 19/01/23.
//

import SwiftUI
import SwiftUINavigation
import XCTestDynamicOverlay
import IdentifiedCollections

final class StandupDetailModel: ObservableObject {
    enum Destination {
        case alert(AlertState<AlertAction>)
        case edit(EditStandupModel)
        case meeting(Meeting)
    }
    
    enum AlertAction {
        case confirmDeletion
    }
    
    @Published var destination: Destination?
    @Published var standup: Standup
    
    // With that, we have a guarantee that this closure will be implemented by its parent,
    // if not, a purple warning should pop up warning user to implement this closure once
    // this closure executes.
    var onConfirmDeletion: () -> Void = unimplemented("StandupDetailModel.onConfirmDeletion")
    
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
    
    func deleteButtonTapped() {
        destination = .alert(.delete)
//        destination = .alert(
//            AlertState<AlertAction>(
//                title: TextState("Delete?"),
//                message: TextState("Are you sure you want to delete this meeting?"),
//                buttons: [
//                    .destructive(
//                        TextState("Yes"),
//                        action: .send(.confirmDeletion)
//                    ),
//                    .cancel(TextState("Nevermind"))
//                ]
//            )
//        )
    }
    
    func alertButtonTapped(_ action: AlertAction) {
        switch action {
        case .confirmDeletion:
            onConfirmDeletion()
        }
    }
    
    func editButtonTapped() {
        self.destination = .edit(EditStandupModel(standup: standup))
    }
    
    func cancelEditButtonTapped() {
        self.destination = nil
    }
    
    func doneEditingButtonTapped() {
        guard case let .edit(model) = self.destination else { return }
        self.standup = model.standup
        self.destination = nil
    }
}


// here we can define a static constant in order to call any
// AlertState<StandupDetailModel.AlertAction> case easily
extension AlertState where Action == StandupDetailModel.AlertAction {
    static let delete = AlertState<Action>(
        title: TextState("Delete?"),
        message: TextState("Are you sure you want to delete this meeting?"),
        buttons: [
            .destructive(
                TextState("Yes"),
                action: .send(.confirmDeletion)
            ),
            .cancel(TextState("Nevermind"))
        ]
    )
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
                    self.model.deleteButtonTapped()
                }
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle(self.model.standup.title)
        .toolbar {
            Button("Edit") {
                self.model.editButtonTapped()
            }
        }
        .sheet(
            // another way to define a Binding<T>
            unwrapping: Binding<StandupDetailModel.Destination?>(
                get: { self.model.destination },
                set: { self.model.destination = $0 }
            ),
            case: /StandupDetailModel.Destination.meeting
        ) { $meeting in
            MeetingView(
                meeting: meeting,
                standup: self.model.standup
            )
        }
        .alert(
            unwrapping: self.$model.destination,
            case: /StandupDetailModel.Destination.alert,
            // you can omit braces closure definition and parameter
            // method name.
            action: self.model.alertButtonTapped
        )
        .sheet(
            unwrapping: self.$model.destination,
            case: /StandupDetailModel.Destination.edit
        ) { $model in
            NavigationStack {
                EditStandupView(model: model)
                    .navigationTitle(model.standup.title)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                self.model.cancelEditButtonTapped()
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                self.model.doneEditingButtonTapped()
                            }
                        }
                    }
            }
        }
    }
}

struct StandupDetail_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            StandupDetailView(
                model: StandupDetailModel(
                    standup: .mock
                )
            )
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
        .preferredColorScheme(.dark)
    }
}
