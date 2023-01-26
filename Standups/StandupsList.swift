//
//  StandupsList.swift
//  Standups
//
//  Created by bruno on 15/01/23.
//

import SwiftUINavigation
import SwiftUI
import Combine

final class StandupsListModel: ObservableObject {
    enum Destination {
//        enum Specific {
//            case screenOne
//            case screenTwo
//        }
        case add(EditStandupModel)
        case detail(StandupDetailModel)
//        case navigate(Specific)
    }
    
    @Published var destination: Destination? {
        didSet { self.bind() }
    }
    @Published var standups: [Standup]
    
    private var destinationCancellable: AnyCancellable?
    
    init(
        destination: Destination? = nil,
        standups: [Standup] = []
    ) {
        self.destination = destination
        self.standups = standups
        self.bind()
    }
    
    func addStandupButtonTapped() {
        self.destination = .add(EditStandupModel(standup: Standup(id: Standup.ID(UUID()))))
    }
    
    func dismissAddStandupButtonTapped() {
        self.destination = nil
    }
    
    func confirmAddStandupButtonTapped() {
        defer { self.destination = nil }
        
        guard case let .add(editStandupModel) = self.destination else { return }
        var standup = editStandupModel.standup
        standup.attendees.removeAll { attendee in
            attendee.name.allSatisfy(\.isWhitespace)
        }
        if standup.attendees.isEmpty {
            standup.attendees.append(
                Attendee(
                    id: Attendee.ID(UUID()),
                    name: ""
                )
            )
        }
        self.standups.append(standup)
    }
    
    func standupTapped(standup: Standup) {
        let model = StandupDetailModel(standup: standup)
        self.destination = .detail(model)
//        self.destination = .navigate(.screenTwo)
    }
    
    private func bind() {
        switch self.destination {
        case let .detail(standupDetailModel):
            standupDetailModel.onConfirmDeletion = { [weak self, id = standupDetailModel.standup.id] in
                guard let self else { return }
                
                withAnimation {
                    self.standups.removeAll { $0.id == id }
                    self.destination = nil
                }
            }
            
            // another way to sync data without closure is using combine
            self.destinationCancellable = standupDetailModel.$standup
                .sink { [weak self] standup in
                    guard let self else { return }
                    guard let index = self.standups.firstIndex(where: { $0.id == standup.id }) else { return }
                    self.standups[index] = standup
                }
        case .add, .none:
            break
        }
    }
}

struct StandupsList: View {
    @ObservedObject var model: StandupsListModel
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(self.model.standups) { standup in
                    Button(action: { self.model.standupTapped(standup: standup) }) {
                        CardView(standup: standup)
                    }
                    .listRowBackground(standup.theme.mainColor)
                }
            }
            .toolbar {
                Button(action: { self.model.addStandupButtonTapped() }) {
                    Image(systemName: "plus")
                }
            }
            .navigationTitle("Daily Standups")
            .sheet(
                unwrapping: self.$model.destination,
                case: /StandupsListModel.Destination.add
            ) { $model in
                NavigationStack {
                    EditStandupView(model: model)
                        .navigationTitle("New standup")
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button(action: { self.model.dismissAddStandupButtonTapped() }) {
                                    Text("Dismiss")
                                }
                            }
                            ToolbarItem(placement: .confirmationAction) {
                                Button(action: { self.model.confirmAddStandupButtonTapped() }) {
                                    Text("Add")
                                }
                            }
                        }
                }
            }
            .navigationDestination(
                unwrapping: self.$model.destination,
                case: /StandupsListModel.Destination.detail
            ) { $model in
                StandupDetailView(model: model)
            }
//            .navigationDestination(
//                unwrapping: self.$model.destination,
//                case: /StandupsListModel.Destination.detail
//            ) { route in
////                navigationHandler(route: route.wrappedValue)
//            }
        }
        .preferredColorScheme(.dark)
    }
    
//    @ViewBuilder
//    private func navigationHandler(route: StandupsListModel.Destination.Specific) -> some View {
//        switch route {
//        case .screenOne:
//            StandupDetailView(model: .init(standup: .mock))
//        case .screenTwo:
//            StandupDetailView(model: .init(standup: .mock))
//        }
//    }
}

struct StandupsList_Previews: PreviewProvider {
    static var previews: some View {
        StandupsList(
            model: StandupsListModel(
                destination: .add(EditStandupModel(focus: .title, standup: .mock)),
                standups: [
                    .mock,
                ]
            )
        )
    }
}

struct CardView: View {
    let standup: Standup
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(self.standup.title)
                .font(.headline)
            Spacer()
            HStack {
                Label(
                    "\(self.standup.attendees.count)",
                    systemImage: "person.3"
                )
                Spacer()
                Label(
                    self.standup.duration.formatted(.units()),
                    systemImage: "clock"
                )
                .labelStyle(.trailingIcon)
            }
            .font(.caption)
        }
        .padding()
        .foregroundColor(self.standup.theme.accentColor)
    }
}

struct TrailingIconLabelStyle: LabelStyle {
    func makeBody(
        configuration: Configuration
    ) -> some View {
        HStack {
            configuration.title
            configuration.icon
        }
    }
}

extension LabelStyle where Self == TrailingIconLabelStyle {
    static var trailingIcon: Self { Self() }
}
