// The MIT License (MIT)
//
// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).

import SwiftUI

struct MultipleSelectionPicker: View {
    @Binding var selection: Set<String>

    var options: [String]

    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        List {
            ForEach(options, id: \.self) { item in
                MultipleSelectionRow(title: item, isSelected: $selection.map { $0.contains(item) })
//                MultipleSelectionRow(title: item, isSelected: self.selection.contains(item)) {
//                    if self.selection.contains(item) {
//                        self.selection.remove(item)
//                    } else {
//                        self.selection.insert(item)
//                    }
//                }
            }
        }
    }
}

struct MultipleSelectionRow: View {
    var title: String
    @Binding var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                Toggle(isOn: $isSelected)
            }
        }.foregroundColor(Color.black)
    }
}

struct PickerPreview: View {
    @State var selection: Set<String> = []

    var body: some View {
        MultipleSelectionPicker(selection: $selection, options: ["Option 1", "Option 2", "Option 3"])
    }
}

struct MultipleSelectionPicker_Previews: PreviewProvider {
    static var previews: some View {
        PickerPreview()
    }
}
