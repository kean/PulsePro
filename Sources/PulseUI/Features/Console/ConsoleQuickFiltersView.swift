// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).
// Licensed under Apache License v2.0 with Runtime Library Exception.

import SwiftUI
import Pulse

struct ConsoleQuickFiltersView: View {
    @Binding var filter: ConsoleViewModel.FilterType
    #if os(iOS)
    @Binding var isShowingSettings: Bool
    #endif

    var body: some View {
        HStack {
            Picker("", selection: $filter) {
                Text("Trace").tag(ConsoleViewModel.FilterType.trace)
                Text("Debug").tag(ConsoleViewModel.FilterType.debug)
                Text("Errors").tag(ConsoleViewModel.FilterType.errors)
            }.pickerStyle(SegmentedPickerStyle())
            Spacer(minLength: 40)
            #if os(iOS)
            Button(action: { self.isShowingSettings = true }) {
                Image(systemName: "gear")
                    .frame(width: 44, height: 44)
            }.buttonStyle(BorderlessButtonStyle())
            #endif
        }
    }
}

#if DEBUG
#if os(iOS)
struct ConsoleQuickFiltersView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ConsoleQuickFiltersView(filter: .constant(.debug), isShowingSettings: .constant(false))
                .previewLayout(.fixed(width: 320, height: 80))
        }
    }
}
#endif
#endif
