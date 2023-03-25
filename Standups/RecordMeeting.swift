//
//  RecordMeeting.swift
//  Standups
//
//  Created by bruno on 25/01/23.
//

import Clocks
import Dependencies
import SwiftUI
import SwiftUINavigation
import XCTestDynamicOverlay
@preconcurrency import Speech

@MainActor
final class RecordMeetingModel: ObservableObject {
    let standup: Standup
    
    @Published var destination: Destination?
    @Published var dismiss = false
    @Published var secondsElapsed = 0
    @Published var speakerIndex = 0
    
    private var transcript: String = ""
    
    @Dependency(\.continuousClock) var clock
    
    enum Destination {
        case alert(AlertState<AlertAction>)
    }
    
    enum AlertAction {
        case confirmSave
        case confirmDiscard
    }
    
    var onMeetingFinished: (String) -> Void = unimplemented("RecordMeetingModel.onMeetingFinished")
    
    var durationRemaining: Duration {
        self.standup.duration - .seconds(secondsElapsed)
    }
    
    var isAlertOpen: Bool {
        switch destination {
        case .alert:
            return true
        case .none:
            return false
        }
    }
    
    init(
        destination: Destination? = nil,
        standup: Standup
    ) {
        self.destination = destination
        self.standup = standup
    }
    
    func nextButtonTapped() {
        guard self.speakerIndex < self.standup.attendees.count - 1 else {
//            self.onMeetingFinished()
//            self.dismiss = true
            self.destination = .alert(.nextEndMeeting)
            return
        }
        
        self.speakerIndex += 1
        self.secondsElapsed = self.speakerIndex * Int(self.standup.durationPerAttendee.components.seconds)
    }
    
    func endMeetingButtonTapped() {
        self.destination = .alert(.endMeeting)
    }
    
    func onConfirmSave() {
        self.onMeetingFinished(transcript)
        self.dismiss = true
    }
    
    func onConfirmDiscard() {
        self.dismiss = true
    }
    
    @MainActor
    func alertButtonTapped(_ action: AlertAction) {
        switch action {
        case .confirmSave:
            onConfirmSave()
        case .confirmDiscard:
            onConfirmDiscard()
        }
    }
    
    @MainActor
    func task() async {
        do {
            try await withThrowingTaskGroup(of: Void.self) { group in
                if await self.requestAuthorization() == .authorized {
                    group.addTask {
                        // start speech task
                        try await self.startSpeechRecoginition()
                    }
                }
                group.addTask { [self] in
                    // start timer task
                    await self.startTimer()
                }
                try await group.waitForAll()
            }
        } catch {
            self.destination = .alert(AlertState(title: TextState("Something went wrong.")))
        }
    }
    
    private func startSpeechRecoginition() async throws {
        let speech = Speech()
        for try await result in await speech
            .startTask(request: SFSpeechAudioBufferRecognitionRequest()) {
            self.transcript = result.bestTranscription.formattedString
        }
    }
    
    private func startTimer() async {
        for await _ in self.clock.timer(interval: .seconds(1)) where !isAlertOpen {
            self.secondsElapsed += 1
            
            if self.secondsElapsed.isMultiple(of: Int(self.standup.durationPerAttendee.components.seconds)) {
                if self.speakerIndex == self.standup.attendees.count - 1 {
                    self.onMeetingFinished(self.transcript)
                    self.dismiss = true
                    break
                }
                self.speakerIndex += 1
            }
        }
    }
    
    private func requestAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        await withUnsafeContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }
}

extension AlertState where Action == RecordMeetingModel.AlertAction {
    static let endMeeting = AlertState<Action>(
        title: TextState("End Meeting?"),
        message: TextState("You are ending the meeting early. What would you like to do?"),
        buttons: [
            .default(
                TextState("Save and end"),
                action: .send(.confirmSave)
            ),
            .destructive(
                TextState("Discard"),
                action: .send(.confirmDiscard)
            ),
            .cancel(TextState("Resume"))
        ]
    )
    
    static let nextEndMeeting = AlertState<Action>(
        title: TextState("End Meeting?"),
        message: TextState("You are ending the meeting early. What would you like to do?"),
        buttons: [
            .default(
                TextState("Save and end"),
                action: .send(.confirmSave)
            ),
            .cancel(TextState("Resume"))
        ]
    )
}

struct RecordMeetingView: View {
    
    @Environment(\.dismiss) var dismiss
    @ObservedObject var model: RecordMeetingModel
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(self.model.standup.theme.mainColor)
            
            VStack {
                MeetingHeaderView(
                    secondsElapsed: self.model.secondsElapsed,
                    durationRemaining: self.model.durationRemaining,
                    theme: self.model.standup.theme
                )
                MeetingTimerView(
                    standup: self.model.standup,
                    speakerIndex: self.model.speakerIndex
                )
                MeetingFooterView(
                    standup: self.model.standup,
                    nextButtonTapped: { self.model.nextButtonTapped() },
                    speakerIndex: self.model.speakerIndex
                )
            }
        }
        .padding()
        .foregroundColor(self.model.standup.theme.accentColor)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("End meeting") {
                    self.model.endMeetingButtonTapped()
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .task {
            await self.model.task()
        }
        .onChange(of: self.model.dismiss) { _ in self.dismiss() }
        .alert(
            unwrapping: self.$model.destination,
            case: /RecordMeetingModel.Destination.alert,
            // you can omit braces closure definition and parameter
            // method name.
            action: self.model.alertButtonTapped
        )
    }
}

struct MeetingHeaderView: View {
    let secondsElapsed: Int
    let durationRemaining: Duration
    let theme: Theme
    
    var body: some View {
        VStack {
            ProgressView(value: self.progress)
                .progressViewStyle(
                    MeetingProgressViewStyle(theme: self.theme)
                )
            HStack {
                VStack(alignment: .leading) {
                    Text("Seconds Elapsed")
                        .font(.caption)
                    Label(
                        "\(self.secondsElapsed)",
                        systemImage: "hourglass.bottomhalf.fill"
                    )
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Seconds Remaining")
                        .font(.caption)
                    Label(
                        self.durationRemaining.formatted(.units()),
                        systemImage: "hourglass.tophalf.fill"
                    )
                    .font(.body.monospacedDigit())
                    .labelStyle(.trailingIcon)
                }
            }
        }
        .padding([.top, .horizontal])
    }
    
    private var totalDuration: Duration {
        .seconds(self.secondsElapsed)
        + self.durationRemaining
    }
    
    private var progress: Double {
        guard totalDuration > .seconds(0) else { return 0 }
        return Double(self.secondsElapsed)
        / Double(self.totalDuration.components.seconds)
    }
}

struct MeetingProgressViewStyle: ProgressViewStyle {
    var theme: Theme
    
    func makeBody(
        configuration: Configuration
    ) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10.0)
                .fill(theme.accentColor)
                .frame(height: 20.0)
            
            ProgressView(configuration)
                .tint(theme.mainColor)
                .frame(height: 12.0)
                .padding(.horizontal)
        }
    }
}

struct MeetingTimerView: View {
    let standup: Standup
    let speakerIndex: Int
    
    var body: some View {
        Circle()
            .strokeBorder(lineWidth: 24)
            .overlay {
                VStack {
                    Text(self.currentSpeakerName)
                        .font(.title)
                    Text("is speaking")
                    Image(systemName: "mic.fill")
                        .font(.largeTitle)
                        .padding(.top)
                }
                .foregroundStyle(self.standup.theme.accentColor)
            }
            .overlay {
                ForEach(
                    Array(self.standup.attendees.enumerated()),
                    id: \.element.id
                ) { index, attendee in
                    if index < self.speakerIndex + 1 {
                        SpeakerArc(
                            totalSpeakers: self.standup.attendees.count,
                            speakerIndex: index
                        )
                        .rotation(Angle(degrees: -90))
                        .stroke(
                            self.standup.theme.mainColor,
                            lineWidth: 12
                        )
                    }
                }
            }
            .padding(.horizontal)
    }
    
    private var currentSpeakerName: String {
        guard
            self.speakerIndex < self.standup.attendees.count
        else { return "Someone" }
        return self.standup
            .attendees[self.speakerIndex].name
    }
}

struct SpeakerArc: Shape {
    let totalSpeakers: Int
    let speakerIndex: Int
    
    private var degreesPerSpeaker: Double {
        360.0 / Double(totalSpeakers)
    }
    private var startAngle: Angle {
        Angle(
            degrees: degreesPerSpeaker
            * Double(speakerIndex)
            + 1.0
        )
    }
    private var endAngle: Angle {
        Angle(
            degrees: startAngle.degrees
            + degreesPerSpeaker
            - 1.0
        )
    }
    
    func path(in rect: CGRect) -> Path {
        let diameter = min(
            rect.size.width, rect.size.height
        ) - 24.0
        let radius = diameter / 2.0
        let center = CGPoint(x: rect.midX, y: rect.midY)
        return Path { path in
            path.addArc(
                center: center,
                radius: radius,
                startAngle: startAngle,
                endAngle: endAngle,
                clockwise: false
            )
        }
    }
}

struct MeetingFooterView: View {
    let standup: Standup
    var nextButtonTapped: () -> Void
    let speakerIndex: Int
    
    var body: some View {
        VStack {
            HStack {
                Text(self.speakerText)
                Spacer()
                Button(action: self.nextButtonTapped) {
                    Image(systemName: "forward.fill")
                }
            }
        }
        .padding([.bottom, .horizontal])
    }
    
    private var speakerText: String {
        guard
            self.speakerIndex
                < self.standup.attendees.count - 1
        else {
            return "No more speakers."
        }
        return """
      Speaker \(self.speakerIndex + 1) \
      of \(self.standup.attendees.count)
      """
    }
}

struct RecordMeeting_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            RecordMeetingView(
                model: RecordMeetingModel(standup: .mock)
            )
            .preferredColorScheme(.dark)
        }
    }
}
