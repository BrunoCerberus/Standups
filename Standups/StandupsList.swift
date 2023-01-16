//
//  StandupsList.swift
//  Standups
//
//  Created by bruno on 15/01/23.
//

import SwiftUI

final class StandupsListModel: ObservableObject {
    
}

struct StandupsList: View {
  var body: some View {
    NavigationStack {
      List {
      }
      .navigationTitle("Daily Standups")
    }
  }
}

struct StandupsList_Previews: PreviewProvider {
  static var previews: some View {
    StandupsList()
  }
}
