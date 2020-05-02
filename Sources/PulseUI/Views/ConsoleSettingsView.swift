// The MIT License (MIT)
//
// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).

import SwiftUI
import Pulse

struct ConsoleSettingsView: View {
    @ObservedObject var model: ConsoleViewModel
    @Binding var isPresented: Bool

    var body: some View {
        NavigationView {
            Form {
                Section {
                    Picker(selection: $model.searchCriteria.timePeriod, label: Text("Time Period")) {
                        ForEach(TimePeriod.allCases, id: \.self) {
                            Text($0.description)
                        }
                    }
                }
            }
            .navigationBarTitle("Settings")
            .navigationBarItems(trailing:
                Button(action: { self.isPresented = false }) {
                     Image(systemName: "xmark.circle.fill")
                         .frame(width: 44, height: 44)
                 }
            )
        }
    }
}

struct ConsoleSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ConsoleSettingsView(model: ConsoleViewModel(container: mockMessagesStore), isPresented: .constant(true))
        }
    }
}
