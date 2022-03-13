// The MIT License (MIT)
//
// Copyright (c) 2020–2022 Alexander Grebenyuk (github.com/kean).

import SwiftUI

struct LoaderView: NSViewRepresentable {
    let color: NSColor
    var duration: TimeInterval = 1
    
    func makeNSView(context: Context) -> NSView {
       NSPulseLoaderView(color: color, duration: duration)
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        // Do nothing
    }
}

final class NSPulseLoaderView: NSView {
    private let color: NSColor
    private let duration: TimeInterval
    
    init(color: NSColor, duration: TimeInterval) {
        self.color = color
        self.duration = duration
        
        super.init(frame: .zero)
        
        wantsLayer = true
    }
    
    override func layout() {
        super.layout()
        
        guard let layer = self.layer else {
            return
        }
        layer.sublayers?.removeAll()
        layer.sublayers = nil
        layer.speed = 1
        addAnimation(in: layer, size: bounds.size, color: color.cgColor, duration: duration)
    }
        
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private func addAnimation(in layer: CALayer, size: CGSize, color: CGColor, duration: TimeInterval) {
    let beginTime = CACurrentMediaTime()
    let beginTimes = [0, 0.2, 0.4]
    
    // Scale animation
    let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
    
    scaleAnimation.duration = duration
    scaleAnimation.fromValue = 0
    scaleAnimation.toValue = 1
    
    // Opacity animation
    let opacityAnimation = CAKeyframeAnimation(keyPath: "opacity")
    
    opacityAnimation.duration = duration
    opacityAnimation.keyTimes = [0, 0.05, 1]
    opacityAnimation.values = [0, 1, 0]
    
    // Animation
    let animation = CAAnimationGroup()
    
    animation.animations = [scaleAnimation, opacityAnimation]
    animation.timingFunction = CAMediaTimingFunction(name: .linear)
    animation.duration = duration
    animation.repeatCount = HUGE
    animation.isRemovedOnCompletion = false
    
    // Draw balls
    for i in 0 ..< 3 {
        let circle = circleLayerWith(size: size, color: color)
        let frame = CGRect(x: (layer.bounds.size.width - size.width) / 2,
                           y: (layer.bounds.size.height - size.height) / 2,
                           width: size.width,
                           height: size.height)
        
        animation.beginTime = beginTime + beginTimes[i]
        circle.frame = frame
        circle.opacity = 0
        circle.add(animation, forKey: "animation")
        layer.addSublayer(circle)
    }
}

private func circleLayerWith(size: CGSize, color: CGColor) -> CALayer {
    let layer = CAShapeLayer()
    layer.fillColor = color
    layer.backgroundColor = nil
    layer.path = CGPath(ellipseIn: CGRect(x: 0, y: 0, width: size.width, height: size.height), transform: nil)
    layer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
    return layer
}

struct PulsatingLoaderView_Previews: PreviewProvider {
    static var previews: some View {
        LoaderView(color: .systemBlue)
            .frame(width: 100, height: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/)
    }
}
