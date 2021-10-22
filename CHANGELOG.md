# Pulse 1.x

## Pulse 1.3.1

*21 Oct, 2021*

This release has new performance improvements finally getting energy usage to "Low" even while inserting 100 messages per second in an existing store with 100K messages during remote logging. 

### Optimizations

- Optimize message insertion during remote logging
- Optimize text rendering in Text mode
- Optimize pins

### Fixes

- Fix an issue with programmatic (non-database) filters (headers and body filters) not being applied progressively during remote logging on the Network tab
- Fix an issue where text was rendered twice when you switch to a Text mode (most strings were cached during the second run, but combining and rendering them is slow)
- Fix a rare crash when switching between Table and Text mode
- Fix an issue with the "Now" mode not disabling when your start jumping between search results
- Fix an issue with messages being inserted in Text mode with "Limit to a Thousand" mode enabled even after the limit was reached

## Pulse 1.3.0

*20 Oct, 2021*

### Features

- Add "Auto-Scroll" button for remote logging that, when enabled, automatically scrolls to the bottom of the table when new messages are added. This mode is enabled by default.
- In Text mode, new messages are now inserted automatically during remote logging. This is possible due to rewritten subsystem for managing updates from the remote clients. "Auto Scroll" is also supported in the Text mode.

### Enhancements

- Optimize how messages are inserted during remote logging (both in table and text views)
- More JSON viewer optimizations (search, filtering, etc)

### Fixes
- Fix a crash when you try to collapse JSON objects in a filtered output of the JSON viewer - this option is now disabled. You can still Cmd+Click and see some of the remaining options, e.g. "Copy Object"
- Fix an issue where a toolbar in Text Mode was not reloading when you change the options
- Fix "Interval" field formatting; no fractional minutes anymore
- Fix an issue with pinned messages sometimes showing with gray text color instead of white

## Pulse 1.2.1

*18 Oct, 2021*

- Fix an issue with a URL hardcoded for testing on the summary page

## Pulse 1.2.0

*17 Oct, 2021*

- Fix typo on the welcome page - [#13](https://github.com/kean/PulsePro/issues/13)
- Fix long URLs truncation mode in the network summary page - [#12](https://github.com/kean/PulsePro/issues/12)
- Add "filename" column - [#8](https://github.com/kean/PulsePro/issues/8)
- Show HTTP additional header fields in the Headers view

## Pulse 1.1.2

*13 Oct, 2021*

- More performance improvements
- In text mode, the text view no longer reloads automatically when the remote client is attached and the server recieves new messages

## Pulse 1.1.1

*13 Oct, 2021*

- Reduce CPU and memory usage. More improvements coming in the future version. There is still a bug I'm tracking where a SwiftUI toolbar leaks memory in macOS 11.
- Fix an issue with JQ output not reloading

## Pulse 1.1.0

*9 Oct, 2021*

### JSON Viewer Improvements

- You can now expand and collapse objects and arrays (click on the opening or the closing brace)
- You can now expand/collapse all objects and array
- Optimize search and filtering (about x10 improvement)
- Add new search selection style, similar to Xcode
- Cmd+click on opening or closing brace to show a object/array-specific menu
	- "Copy Object" - You can copy an expanded vesion of the object with nice formatting
	- "Select Object" - Selects the string in NSTextView
	- "Fold"/"Expand" - Same as clicking on an opening/closing braket
	- "Focus" - Focuses on the object/array. You can then press "Close" to remove focus; or dive even deeper if needed
- Fix some window-resizing glithes
- Hover over an opening/closing braket to see number of objects in array/object (tooltip)
- Regster Pulse Pro as a JSON viewer
- Large JSON files (> 1 MB) are now open collapsed by default

## Pulse 1.0.1

*8 Oct, 2021*

- Fix an issue [#7](https://github.com/kean/PulsePro/issues/7) where the remote logger sometimes starts as paused

## Pulse 1.0.0

*5 Oct, 2021*

Initial release
