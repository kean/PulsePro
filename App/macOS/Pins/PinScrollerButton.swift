//
//  PinScrollerButton.swift
//  Pulse Pro
//
//  Created by Alexander Grebenyuk on 9/30/21.
//  Copyright © 2021 kean. All rights reserved.
//

import Foundation
import AppKit

private let red = Palette.red

final class PinScrollerButton: NSControl {
    var index: Int = 0
    
    static var preferreHeight: CGFloat = 8
    
    private var backgroundView = NSView()
    
    enum Style {
        case error
        case pin
    }
    
    private var primaryColor: NSColor = .systemBlue
    
    var style: Style = .pin {
        didSet {
            guard style != oldValue else { return }
            switch style {
            case .pin: primaryColor = NSColor.systemBlue
            case .error: primaryColor = red
            }
            backgroundView.layer?.backgroundColor = primaryColor.withAlphaComponent(0.66).cgColor
        }
    }
    
    init() {
        super.init(frame: .zero)
        
        addSubview(backgroundView)
        
        backgroundView.wantsLayer = true
        backgroundView.layer?.backgroundColor = primaryColor.withAlphaComponent(0.66).cgColor
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layout() {
        super.layout()
        
        backgroundView.frame = CGRect(x: 0, y: 3, width: bounds.width, height: 2)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        
        sendAction(action, to: target)
    }
    
    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)

        NSCursor.pointingHand.set()

        let animation1 = CABasicAnimation()
        animation1.duration = 0.15
        animation1.fromValue = CATransform3DIdentity
        animation1.toValue = CATransform3DMakeScale(1.0, 1.5, 1.0)
        backgroundView.layer?.add(animation1, forKey: "transform")
        
        let animation2 = CABasicAnimation()
        animation2.duration = 0.5
        animation2.fromValue = primaryColor.withAlphaComponent(0.66).cgColor
        animation2.toValue = primaryColor.cgColor
        backgroundView.layer?.add(animation2, forKey: "color")
        
        backgroundView.layer?.transform = CATransform3DMakeScale(1.0, 1.5, 1.0)
        backgroundView.layer?.backgroundColor = primaryColor.cgColor
    }
    
    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        
        NSCursor.arrow.set()
        
        backgroundView.layer?.transform = CATransform3DMakeAffineTransform(CGAffineTransform.identity)
        backgroundView.layer?.backgroundColor = primaryColor.withAlphaComponent(0.66).cgColor
    }
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        for trackingArea in self.trackingAreas {
            self.removeTrackingArea(trackingArea)
        }
        
        let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .activeAlways]
        let trackingArea = NSTrackingArea(rect: self.bounds, options: options, owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea)
    }
}
