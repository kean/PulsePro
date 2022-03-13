// The MIT License (MIT)
//
// Copyright (c) 2020–2022 Alexander Grebenyuk (github.com/kean).

import SwiftUI
import CoreData
import PulseCore
import Combine

struct NetworkFiltersPanelPro: View {
    @ObservedObject var model: NetworkFiltersViewModelPro

    @AppStorage("networkFilterIsParametersExpanded") private var isParametersExpanded = true
    @AppStorage("networkFilterIsStatusCodeExpanded") private var isStatusCodeExpanded = true
    @AppStorage("networkFilterIsTimePeriodExpanded") private var isTimePeriodExpanded = true
    @AppStorage("networkFilterIsDomainsGroupExpanded") private var isDomainsGroupExpanded = true
    @AppStorage("networkFilterIsDurationGroupExpanded") private var isDurationGroupExpanded = true
    @AppStorage("networkFilterIsContentTypeGroupExpanded") private var isContentTypeGroupExpanded = true
    
    var body: some View {
        ScrollView {
            VStack(spacing: Filters.formSpacing) {
                VStack(spacing: 6) {
                    HStack {
                        Text("FILTERS")
                            .foregroundColor(.secondary)
                        Spacer()
                        Button("Reset") { model.resetAll() }
                        .disabled(!model.isButtonResetEnabled)
                    }
                    Divider()
                }.padding(.top, 6)
                
                parametersGroup
                statusCode
                contentTypeGroup
                timePeriodGroup
                domainsGroup
                durationGroup
            }.padding(Filters.formPadding)
        }
    }
    
    private var parametersGroup: some View {
        DisclosureGroup(isExpanded: $isParametersExpanded, content: {
            VStack {
                ForEach(model.filters) { filter in
                    CustomFilterView(filter: filter, onRemove: {
                        model.removeFilter(filter)
                    })
                }
            }.padding(.top, Filters.contentTopInset)
            Button(action: model.addFilter) {
                Image(systemName: "plus.circle")
            }
        }, label: {
            FilterSectionHeader(
                icon: "line.horizontal.3.decrease.circle", title: "General",
                color: .yellow,
                reset: { model.resetFilters() },
                isDefault: model.filters.count == 1 && model.filters[0].isDefault,
                isEnabled: $model.criteria.isFiltersEnabled
            )
        })
    }
    
    private var statusCode: some View {
        DisclosureGroup(isExpanded: $isStatusCodeExpanded, content: {
            HStack {
                Text("Range:")
                    .foregroundColor(.secondary)
                TextField("From", text: $model.criteria.statusCode.from, onEditingChanged: {
                    if $0 { model.criteria.statusCode.isEnabled = true }
                })
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 52)
                TextField("To", text: $model.criteria.statusCode.to, onEditingChanged: {
                    if $0 { model.criteria.statusCode.isEnabled = true }
                })
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 49)
            }.padding(EdgeInsets(top: Filters.contentTopInset, leading: 8, bottom: 4, trailing: 6))
        }, label: {
            FilterSectionHeader(
                icon: "number", title: "Status Code",
                color: .yellow,
                reset:  { model.criteria.statusCode = .default },
                isDefault: model.criteria.statusCode == .default,
                isEnabled: $model.criteria.statusCode.isEnabled
            )
        })
    }
    
    private var timePeriodGroup: some View {
        DisclosureGroup(isExpanded: $isTimePeriodExpanded, content: {
            Filters.toggle("Latest Session", isOn: $model.criteria.dates.isCurrentSessionOnly)
                .padding(.top, Filters.contentTopInset)
                        
            let fromBinding = Binding(get: {
                model.criteria.dates.startDate ?? Date().addingTimeInterval(-3600)
            }, set: { newValue in
                model.criteria.dates.startDate = newValue
            })
            
            let toBinding = Binding(get: {
                model.criteria.dates.endDate ?? Date()
            }, set: { newValue in
                model.criteria.dates.endDate = newValue
            })
            
            Filters.toggle("Start Date", isOn: $model.criteria.dates.isStartDateEnabled)
            HStack(spacing: 0) {
                DatePicker("", selection: fromBinding)
                    .disabled(!model.criteria.dates.isStartDateEnabled)
                    .fixedSize()
                Spacer()
            }

            Filters.toggle("End Date", isOn: $model.criteria.dates.isEndDateEnabled)
            HStack(spacing: 0) {
                DatePicker("", selection: toBinding)
                    .disabled(!model.criteria.dates.isEndDateEnabled)
                    .fixedSize()
                Spacer()
            }
            HStack {
                Button("Recent") {
                    var dates = model.criteria.dates
                    dates.startDate = Date().addingTimeInterval(-1800)
                    dates.isStartDateEnabled = true
                    dates.isEndDateEnabled = false
                    model.criteria.dates = dates
                }
                Button("Today") {
                    var dates = model.criteria.dates
                    dates.startDate = Calendar.current.startOfDay(for: Date())
                    dates.isStartDateEnabled = true
                    dates.isEndDateEnabled = false
                    model.criteria.dates = dates
                }
                Spacer()
            }.padding(.leading, 13)
        }, label: {
            FilterSectionHeader(
                icon: "calendar", title: "Time Period",
                color: .yellow,
                reset: { model.criteria.dates = .default },
                isDefault: model.criteria.dates == .default,
                isEnabled: $model.criteria.dates.isEnabled
            )
        })
    }
    
    private var domainsGroup: some View {
        DisclosureGroup(isExpanded: $isDomainsGroupExpanded, content: {
            Picker("", selection: $model.criteria.host.value) {
                Text("Any").tag("")
                ForEach(model.allDomains, id: \.self) {
                    Text($0).tag($0)
                }
            }.padding(.top, Filters.contentTopInset)
        }, label: {
            FilterSectionHeader(
                icon: "server.rack", title: "Host",
                color: .yellow,
                reset: { model.criteria.host = .default },
                isDefault: model.criteria.host == .default,
                isEnabled: $model.criteria.host.isEnabled
            )
        })
    }
    
    private var durationGroup: some View {
        DisclosureGroup(isExpanded: $isDurationGroupExpanded, content: {
            VStack(spacing: 6) {
                DurationPicker(title: "Min", value: $model.criteria.duration.from)
                DurationPicker(title: "Max", value: $model.criteria.duration.to)
            }.padding(.top, Filters.contentTopInset)
        }, label: {
            FilterSectionHeader(
                icon: "hourglass", title: "Duration",
                color: .yellow,
                reset: { model.criteria.duration = .default },
                isDefault: model.criteria.duration == .default,
                isEnabled: $model.criteria.duration.isEnabled
            )
        })
    }
    
    private typealias ContentType = NetworkSearchCriteria.ContentTypeFilter.ContentType
    
    private var contentTypeGroup: some View {
        DisclosureGroup(isExpanded: $isContentTypeGroupExpanded, content: {
            VStack(spacing: 6) {
                Picker("", selection: $model.criteria.contentType.contentType) {
                    Section {
                        Text("Any").tag(ContentType.any)
                        Text("JSON").tag(ContentType.json)
                        Text("Plain Text").tag(ContentType.plain)
                    }
                    Section {
                        Text("HTML").tag(ContentType.html)
                        Text("CSS").tag(ContentType.css)
                        Text("CSV").tag(ContentType.csv)
                        Text("JS").tag(ContentType.javascript)
                        Text("XML").tag(ContentType.xml)
                        Text("PDF").tag(ContentType.pdf)
                    }
                    Section {
                        Text("Image").tag(ContentType.anyImage)
                        Text("JPEG").tag(ContentType.jpeg)
                        Text("PNG").tag(ContentType.png)
                        Text("GIF").tag(ContentType.gif)
                        Text("WebP").tag(ContentType.webp)
                    }
                    Section {
                        Text("Video").tag(ContentType.anyVideo)
                    }
                }
            }.padding(.top, Filters.contentTopInset)
        }, label: {
            FilterSectionHeader(
                icon: "doc", title: "Content Type",
                color: .yellow,
                reset: { model.criteria.contentType = .default },
                isDefault: model.criteria.contentType == .default,
                isEnabled: $model.criteria.contentType.isEnabled
            )
        })
    }
}

private struct CustomFilterView: View {
    @ObservedObject var filter: NetworkSearchFilter
    let onRemove: () -> Void
    
    var body: some View {
        VStack(spacing: 6) {
            HStack {
                fieldPicker
                Spacer()
                Button(action: onRemove) {
                    Image(systemName: "minus.circle")
                }
                .buttonStyle(PlainButtonStyle())
                .foregroundColor(Color.red)
                Button(action: { filter.isEnabled.toggle() }) {
                    Image(systemName: filter.isEnabled ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(PlainButtonStyle())
            }
            HStack {
                matchPicker
                Spacer()
            }
            HStack {
                TextField("Value", text: $filter.value)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.leading, 6)
                    .padding(.trailing, 2)
            }
        }
        .padding(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 4))
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(8)
    }
    
    private var fieldPicker: some View {
        Picker("", selection: $filter.field) {
            Section {
                Text("URL").tag(NetworkSearchFilter.Field.url)
                Text("Host").tag(NetworkSearchFilter.Field.host)
                Text("Method").tag(NetworkSearchFilter.Field.method)
                Text("Status Code").tag(NetworkSearchFilter.Field.statusCode)
                Text("Error Code").tag(NetworkSearchFilter.Field.errorCode)
            }
            Section {
                Text("Request Headers").tag(NetworkSearchFilter.Field.requestHeader)
                Text("Response Headers").tag(NetworkSearchFilter.Field.responseHeader)
            }
            Section {
                Text("Request Body").tag(NetworkSearchFilter.Field.requestBody)
                Text("Response Body").tag(NetworkSearchFilter.Field.responseBody)
            }
        }.frame(width: 120)
    }
    
    private var matchPicker: some View {
        Picker("", selection: $filter.match) {
            Section {
                Text("Contains").tag(NetworkSearchFilter.Match.contains)
                Text("Not Contains").tag(NetworkSearchFilter.Match.notContains)
            }
            Section {
                Text("Equals").tag(NetworkSearchFilter.Match.equal)
                Text("Not Equals").tag(NetworkSearchFilter.Match.notEqual)
            }
            Section {
                Text("Begins With").tag(NetworkSearchFilter.Match.beginsWith)
            }
            Section {
                Text("Regex").tag(NetworkSearchFilter.Match.regex)
            }
        }.frame(width: 120)
    }
}

private struct DurationPicker: View {
    let title: String
    @Binding var value: DurationFilterPoint
    
    var body: some View {
        HStack {
            Text(title + ":")
                .foregroundColor(.secondary)
                .frame(width: 42, alignment: .trailing)
            TextField("", text: $value.value)
            Picker("", selection: $value.unit) {
                Text("min").tag(DurationFilterPoint.Unit.minutes)
                Text("sec").tag(DurationFilterPoint.Unit.seconds)
                Text("ms").tag(DurationFilterPoint.Unit.milliseconds)
            }
            .fixedSize()
        }
    }
}

#if DEBUG
struct NetworkFiltersPanelPro_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NetworkFiltersPanelPro(model: .init())
                .previewLayout(.fixed(width: 175, height: 800))
        }
    }
}
#endif
