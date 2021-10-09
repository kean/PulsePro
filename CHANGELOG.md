# Pulse 1.x

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
