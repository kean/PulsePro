// The MIT License (MIT)
//
// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).

import SwiftUI
import Pulse

struct ConsoleSettingsView: View {
    @ObservedObject var model: ConsoleViewModel
    @Binding var isPresented: Bool
    @State private var isShowingRemoveConfirmationAlert = false

    var body: some View {
        NavigationView {
            Form {
                Section {
                    timePeriodPicker
                }
                Section {
                    buttonRemoveAll
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

    private var timePeriodPicker: some View {
        Picker(selection: $model.searchCriteria.timePeriod, label: Text("Time Period")) {
            ForEach(TimePeriod.allCases, id: \.self) {
                Text($0.description)
            }
        }
    }

    private var buttonRemoveAll: some View {
        Button(action: {
            self.isShowingRemoveConfirmationAlert = true
            self.model.buttonRemoveAllMessagesTapped()
        }) {
            Text("Remove All Messages")
        }
        .foregroundColor(.red)
        .alert(isPresented: $isShowingRemoveConfirmationAlert) {
            Alert(
                title: Text("Are you sure you want to remove all recorded messages?"),
                primaryButton: .destructive(Text("Remove all messages"), action: {
                    self.model.buttonRemoveAllMessagesTapped()
                }),
                secondaryButton: .cancel()
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
