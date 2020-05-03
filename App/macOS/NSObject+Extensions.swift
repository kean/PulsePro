// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).
// Licensed under Apache License v2.0 with Runtime Library Exception.

import Foundation
import ObjectiveC
import Combine

private var AnyCancellableKey: UInt8 = 0

extension NSObject {
    var bag: [AnyCancellable] {
        get {
            if let bag = objc_getAssociatedObject(self, &AnyCancellableKey) as? [AnyCancellable] {
                return bag
            }
            let bag = [AnyCancellable]()
            objc_setAssociatedObject(self, &AnyCancellableKey, bag, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return bag
        }
        set {
            objc_setAssociatedObject(self, &AnyCancellableKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
