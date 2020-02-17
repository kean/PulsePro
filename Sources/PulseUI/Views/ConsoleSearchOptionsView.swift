// The MIT License (MIT)
//
// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).

import SwiftUI
import Pulse

struct ConsoleSearchOptionsView: View {
    @Binding var searchCriteria: ConsoleSearchCriteria

    var body: some View {
        HStack(spacing: 8) {
            MenuButton("Levels") {
                Text("Test")
            }.fixedSize()
            Spacer(minLength: 8)
        }
    }
}

//final class MultiselectPickerItemViewModel: NSObject {
//    @Published var isSelected = false
//    let title: String
//    let onValueChanged: (Bool) -> Void
//
//    init(title: String, isSelected: Bool, onValueChanged: @escaping (Bool) -> Void) {
//        self.title = title
//        self.isSelected = isSelected
//        self.onValueChanged = onValueChanged
//    }
//
//    static func makeLevels(searchCriteria: Binding<ConsoleSearchCriteria>) {
//        var all = [Logger.Level.debug, .info, .error, .fatal]
//        var selected: Set<Logger.Level> = []
//        switch searchCriteria.levels {
//        case let .focus(levels):
//
//        case let .hide(levels):
//
//        }
//
//        [Logger.Level.debug, .info, .error, .fatal].map {
//            MultiselectPickerItemViewModel(title: $0.description, isSelected: <#T##Bool#>, onValueChanged: <#T##(Bool) -> Void#>)
//        }
//    }
//}
//
//struct MultiselectPickerView: View {
//    var body: some View {
//
//    }
//}

struct PickerExample: View {
    var strengths = ["Mild", "Medium", "Mature"]

    @State private var selectedStrength = 0

    var body: some View {
        Form {
            Section {
                Picker(selection: $selectedStrength, label: Text("Strength")) {
                    ForEach(0 ..< strengths.count) {
                        Text(self.strengths[$0])

                    }
                }
            }
        }
    }
}

struct ConsoleSearchOptionsView_Previews: PreviewProvider {
    static var previews: some View {
        ConsoleSearchOptionsView(searchCriteria: .constant(.init()))
    }
}
