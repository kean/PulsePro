# PulseUI

**PulseUI** allows you to quickly preview logs in your iOS or tvOS apps. Share logs, and use Pulse macOS app to search and filter them.

<br/>

## iOS Console

Use `ConsoleView` to display messages in your iOS apps.

```swift
let view = ConsoleView(store: .default)
```

> PulseUI is built almost entirely using SwiftUI. To use it in UIKit, wrap `ConsoleView` in a `UIHostingController`.

<br/>

## macOS Console

Share your Pulse database and view it on your Mac. Use advanced search to filter your messages.

To install the app, either download it from the [latest release](https://github.com/kean/PulseUI/releases), or build it from source.

# Minimum Requirements

| Nuke          | Swift           | Xcode           | Platforms                                         |
|---------------|-----------------|-----------------|---------------------------------------------------|
| PulseUI 0.1      | Swift 5.2       | Xcode 11.3      | iOS 13.0 / watchOS 6.0 / macOS 10.15 / tvOS 13.0  |

# License

PulseUI is available under the Apache License license. See the LICENSE file for more info.

