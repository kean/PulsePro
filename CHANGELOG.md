# Pulse 1.x

## Pulse 1.4.0

*Nov 8, 2021*

### Navigation

- You can now switch to a Network view using the main Toolbar. It has several advantages. For example, when you switch, it keeps your selection, filters, and other perferences. You can now also close the sidebar if you don't need to switch between devices.
- Sidebar now displayes your connected devices making it easier to switch between them. Devices and their associated logs are stored persistently. With a context menu, you can open the device in a separate window, show the store in Finder, or remove the device.
- When you open a log file (`.pulse` extension), it nows opens in a clean window with no sidebar and with a filename in the navigation title.
- Remove status bar item. It's not needed anymore thanks to the new siderbar and the fact that "Remote Logging" is now enabled by default.
- You can now close a defails panel
- Add remote logger server status view in "Remote Logging" Preferences

### Pins

- Add "Remove All Pins" menu bar command (⌃⌥⌘P)
- Add "Toggle Pin" menu bar command (⌘P)
- Add "Only Pins" menu bar command (⇧⌘P). Unlike the previous dedicated "Pins" tab, it acts as a filter and can be combined with the rest of the filters.
- Improve performance when adding/removing pins in a large dataset 

### Commands

- Add "Remove All Messages" command (⌘K)
- Add "Viewers" menu with commands "Show Messages" (⌘1), "Show Text Log" (⌘2), "Show Network Requests" (⌘3)
- "Only Errors" menu bar command is now implemented as a Toggle and is disabled when Console is not visible. Change the shortcut to (⇧⌘e)
- Add "Reset Filters" command in "Find" (⇧⌘0)
- Add "Start Streaming" and "Pause Streaming" commands (⇧⌘S)
- Add "Now Mode" command (⇧⌘N)
- Add `help` to toolbar items with info on shortcuts

### Fixes

- Fix an issue where afrer removing messages, time interval is displayed incorrectly until you reopen the console
- Fix an issue where labels/domains weren't reset after deleting all messages
- Fix an issue where the "Interval" column was calculated incorrecy after deleting all messages
- Fix an issue with "Now" not scrolling to the bottom when you open the Console for the first time
- Auto-hide scrollbars in text views

## Pulse 1.3.1

*Oct 21, 2021*

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

*Oct 20, 2021*

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

*Oct 17, 2021*

- Fix typo on the welcome page - [#13](https://github.com/kean/PulsePro/issues/13)
- Fix long URLs truncation mode in the network summary page - [#12](https://github.com/kean/PulsePro/issues/12)
- Add "filename" column - [#8](https://github.com/kean/PulsePro/issues/8)
- Show HTTP additional header fields in the Headers view

## Pulse 1.1.2

*Oct 13, 2021*

- More performance improvements
- In text mode, the text view no longer reloads automatically when the remote client is attached and the server recieves new messages

## Pulse 1.1.1

*Oct 13, 2021*

- Reduce CPU and memory usage. More improvements coming in the future version. There is still a bug I'm tracking where a SwiftUI toolbar leaks memory in macOS 11.
- Fix an issue with JQ output not reloading

## Pulse 1.1.0

*Oct 9, 2021*

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

*Oct 8, 2021*

- Fix an issue [#7](https://github.com/kean/PulsePro/issues/7) where the remote logger sometimes starts as paused

## Pulse 1.0.0

*Oct 5, 2021*

Initial release
