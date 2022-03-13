// The MIT License (MIT)
//
// Copyright (c) 2020–2022 Alexander Grebenyuk (github.com/kean).

import AppKit
import Combine

// MARK: PlainTableCell

final class PlainTableCell: NSTableCellView {
    private let label = NSTextField.label()
    private var preferredColor: NSColor?
    
    var stringValue: String? {
        label.stringValue
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect); createView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder); createView()
    }
    
    static let preferredLabelHeigt: CGFloat = {
        let label = NSTextField.label()
        label.stringValue = "A"
        return label.sizeThatFits(NSSize(width: 100, height: 100)).height
    }()
    
    override var backgroundStyle: NSView.BackgroundStyle {
        didSet {
            guard backgroundStyle != oldValue else { return }
            label.textColor = backgroundStyle == .emphasized ? .labelColor : preferredColor
        }
    }
    
    private func createView() {
        addSubview(label)
    }
    
    override func layout() {
        super.layout()
        
        let size = PlainTableCell.preferredLabelHeigt
        let newFrame = CGRect(x: 0, y: CGFloat(Int(bounds.midY - size / 2)), width: bounds.width, height: size)
        if newFrame != label.frame {
            label.frame = newFrame
        }
    }
    
    static func make(in tableView: NSTableView) -> PlainTableCell {
        let id = NSUserInterfaceItemIdentifier(rawValue: "PlainTableCell")
        if let view = tableView.makeView(withIdentifier: id, owner: nil) as? PlainTableCell {
          return view
        }
        let view = PlainTableCell()
        view.identifier = id
        return view
    }
    
    func display(_ text: String, color: NSColor) {
        label.stringValue = text
        label.textColor = color
        preferredColor = color
    }
}

// MARK: BadgeTableCell

private let circle = NSImage(systemSymbolName: "circle.fill", accessibilityDescription: nil) ?? NSImage()

final class BadgeTableCell: NSView {
    private let badge = NSImageView(image: circle)
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect); createView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder); createView()
    }
        
    private func createView() {
        addSubview(badge)
    }
    
    var color: NSColor? {
        didSet {
            badge.contentTintColor = color ?? .clear
        }
    }

    override func layout() {
        super.layout()

        let side: CGFloat = 10
        badge.frame = CGRect(x: bounds.midX - side / 2, y: bounds.midY - side / 2, width: side, height: side)
    }
    
    static func make(in tableView: NSTableView) -> BadgeTableCell {
        let id = NSUserInterfaceItemIdentifier(rawValue: "BadgeTableCell")
        if let view = tableView.makeView(withIdentifier: id, owner: nil) as? BadgeTableCell {
          return view
        }
        let view = BadgeTableCell()
        view.identifier = id
        return view
    }
}

private final class CircleView: NSView {
    var fillColor: NSColor = .red

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let path = NSBezierPath(ovalIn: dirtyRect)
        fillColor.setFill()
        path.fill()
    }
}

// MARK: IndexTableCell

final class IndexTableCell: NSView {
    private let label = NSTextField.label()
    private var pinBackgroundView: NSView?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect); createView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder); createView()
    }
        
    private func createView() {
        addSubview(label)
    }
    
    private func addPinBackgroundIfNeeded() {
        guard pinBackgroundView == nil else { return }
        
        let background = NSView()
        addSubview(background, positioned: .below, relativeTo: label)
        background.wantsLayer = true
        background.layer?.backgroundColor = NSColor.systemBlue.cgColor
        background.layer?.cornerRadius = 5
        pinBackgroundView = background
    }
        
    override func layout() {
        super.layout()

        let size = PlainTableCell.preferredLabelHeigt
        let newFrame = CGRect(x: 0, y: CGFloat(Int(bounds.midY - size / 2)), width: bounds.width - 2, height: size)
        if newFrame != label.frame {
            label.frame = newFrame
        }
        
        if let background = pinBackgroundView {
            let newPinFrame = bounds.insetBy(dx: 0, dy: 4)
            if background.frame != newPinFrame {
                background.frame = newPinFrame
            }
        }
    }
    
    var text: String? = nil {
        didSet {
            redrawText()
        }
    }
    
    private func redrawText() {
        let text = self.text ?? ""
        let key = IndexCacheKey(text: text, isPinned: isPinned)
        if let string = attributedStringsCache.value(forKey: key) {
            label.attributedStringValue = string
        } else {
            let string = NSAttributedString(string: text, attributes: isPinned ? digitAttributesPinned : digitAttriubutes)
            attributedStringsCache.set(string, forKey: key)
            label.attributedStringValue = string
        }
    }
    
    var isPinned: Bool = false {
        didSet {
            guard isPinned != oldValue else { return }
            if isPinned {
                addPinBackgroundIfNeeded()
            }
            pinBackgroundView?.isHidden = !isPinned
            redrawText()
        }
    }
    
    static func make(in tableView: NSTableView) -> IndexTableCell {
        let id = NSUserInterfaceItemIdentifier(rawValue: "IndexTableCell")
        if let view = tableView.makeView(withIdentifier: id, owner: nil) as? IndexTableCell {
          return view
        }
        let view = IndexTableCell()
        view.identifier = id
        return view
    }
}

// MARK: Cache

private struct IndexCacheKey: Hashable {
    let text: String
    let isPinned: Bool
}

private var attributedStringsCache = Cache<IndexCacheKey, NSAttributedString>(costLimit: .max, countLimit: 200)

private let digitAttributesPinned: [NSAttributedString.Key: Any] = [
    .font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular),
    .foregroundColor: NSColor.white,
    .kern: -0.6,
    .paragraphStyle: digitPS
]

private let digitAttriubutes: [NSAttributedString.Key: Any] = [
    .font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular),
    .foregroundColor: NSColor.secondaryLabelColor,
    .kern: -0.6,
    .paragraphStyle: digitPS
]

private let digitPS: NSParagraphStyle = {
    let ps = NSMutableParagraphStyle()
    ps.alignment = .right
    return ps
}()

private let pinImage2: NSImage = {
    let image = NSImage(systemSymbolName: "pin.circle.fill", accessibilityDescription: nil)
    let config = NSImage.SymbolConfiguration(textStyle: .caption1)
    return image?.withSymbolConfiguration(config) ?? NSImage()
}()

// MARK: RemoteLoggerClientTableViewCell

final class RemoteLoggerClientTableViewCell: NSView {
    private let icon = NSImageView()
    private let label = NSTextField.label()
    private let bolt = NSImageView()
    
    private var cancellables: [AnyCancellable] = []
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect); createView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder); createView()
    }

    private func createView() {
        icon.contentTintColor = NSColor.controlAccentColor
        
        bolt.image = NSImage(systemSymbolName: "bolt.horizontal.circle.fill", accessibilityDescription: nil)
        bolt.contentTintColor = NSColor.secondaryLabelColor
        
        bolt.setContentCompressionResistancePriority(.init(900), for: .horizontal)
        icon.setContentCompressionResistancePriority(.init(900), for: .horizontal)
        
        let spacer = NSView()
        Constraints {
            spacer.anchors.width.equal(1000).priority = .init(rawValue: 50)
        }
        let stack = NSStackView(views: [icon, label, spacer, bolt])
        addSubview(stack)
        stack.anchors.edges.pin()
    }

    static func make(in tableView: NSTableView) -> RemoteLoggerClientTableViewCell {
        let id = NSUserInterfaceItemIdentifier(rawValue: "RemoteLoggerClientTableViewCell")
        if let view = tableView.makeView(withIdentifier: id, owner: nil) as? RemoteLoggerClientTableViewCell {
          return view
        }
        let view = RemoteLoggerClientTableViewCell()
        view.identifier = id
        return view
    }
    
    func display(client: RemoteLoggerClient) {
        cancellables = []
        
        icon.image = NSImage(systemSymbolName: getIconName(client: client), accessibilityDescription: nil)
        
        label.stringValue = client.deviceInfo.name + (client.preferredSuffix ?? "")
                
        client.$isConnected.sink { [weak self] in
            self?.bolt.isHidden = $0
        }.store(in: &cancellables)
    }
    
    private func getIconName(client: RemoteLoggerClient) -> String {
        let system = client.deviceInfo.systemName.lowercased()
        let model = client.deviceInfo.model.lowercased()
        
        switch system {
        case "ios", "ipados":
            if model.contains("ipad") {
                return "ipad"
            } else {
                return "iphone"
            }
        case "watchos":
            return "applewatch"
        case "tvos":
            return "tv"
        case "macos":
            return "laptopcomputer"
        default:
            return "folder"
        }
    }
}
