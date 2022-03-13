//
//  Attributed.swift
//  Pulse Pro
//
//  Created by Alexander Grebenyuk on 9/30/21.
//  Copyright © 2021 kean. All rights reserved.
//

import Foundation
import AppKit

extension NSParagraphStyle {
    static func make(fontSize: Int) -> NSParagraphStyle {
        let lineHeight = Constants.ResponseViewer.lineHeight(for: fontSize)
        return make(lineHeight: lineHeight)
    }
}
