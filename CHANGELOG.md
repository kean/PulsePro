# PulseUI 0.x

## PulseUI 0.8.0

*Feb 5, 2021*

- `NetworkLogger` is now created with a default logger and blob store
- Add `URLSessionProxyDelegate` to automate `URLSession` task logging
- Add [a guide](https://github.com/kean/PulseUI/blob/0.8.0/Docs/Logging.md) on logging network events

## PulseUI 0.7.0

*Feb 4, 2021*

- Remove UserDefaults sharing from share service
- Response and Request blobs are now stored in a dedicated BlobStore, essentially filesystem. The store has a size limit and uses LRU algorithm for cleanup. BlobStore also deduplicates the blobs, so if the app recieves the same response multiple times, only one blob is stored.
- You can open a Pulse store on macOS be selecting a directory with a store, not just the store itself
- Refined view for message list on iOS
- Special messages list cells for network requests

## PulseUI 0.6.0

*Feb 1, 2021*

- Add Network Inspector

## PulseUI 0.5.0

*Jan 28, 2021*

- Add Big Sur support
- Add iOS 14 support
- Update to support "label" filters on macOS
- Add "trace" filter support, "trace" messages are no longer visible by default

## PulseUI 0.4.0

*May 6, 2020*

- Update to Pulse 0.3

## PulseUI 0.3.0

*May 4, 2020*

- Update package depenency to no longer use local dependencies

## PulseUI 0.2.0

*May 4, 2020*

- Optimize search queries

## PulseUI 0.1.0

*May 3, 2020*

- Initial version
