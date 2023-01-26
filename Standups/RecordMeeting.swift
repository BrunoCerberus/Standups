//
//  RecordMeeting.swift
//  Standups
//
//  Created by bruno on 25/01/23.
//

import SwiftUI

final class RecordMeetingModel: ObservableObject {
}

struct RecordMeetingView: View {
  @ObservedObject var model: RecordMeetingModel

  var body: some View {
    Text("Record")
  }
}

struct RecordMeeting_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      RecordMeetingView(
        model: RecordMeetingModel()
      )
    }
  }
}
