import AppKit

var LineNumberViewAssocObjKey: UInt8 = 0

extension NSTextView {
    var lineNumberView: LineNumberRulerView {
        get {
            return objc_getAssociatedObject(self, &LineNumberViewAssocObjKey) as! LineNumberRulerView
        }
        set {
            objc_setAssociatedObject(self, &LineNumberViewAssocObjKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    func lnv_setUpLineNumberView(fontSize: CGFloat = 11, rulerWidth: CGFloat?) {
        
        func configure(_ view: LineNumberRulerView) {
            view.fontSize = fontSize
            view.ruleThickness = (rulerWidth ?? 16) + CGFloat(Int(fontSize * 1.84))
        }
        
        if let view = (objc_getAssociatedObject(self, &LineNumberViewAssocObjKey) as? LineNumberRulerView) {
            configure(view)
            enclosingScrollView?.rulersVisible = true
            return
        }
        
        if font == nil {
            font = NSFont.systemFont(ofSize: 16)
        }
        
        if let scrollView = enclosingScrollView {
            lineNumberView = LineNumberRulerView(textView: self)
            configure(lineNumberView)
            
            scrollView.verticalRulerView = lineNumberView
            scrollView.hasVerticalRuler = true
            scrollView.rulersVisible = true
        }
    }
}

private let newLineRegex = try! NSRegularExpression(pattern: "\n", options: [])

private final class LineNumberView: NSTextField {
    init() {
        super.init(frame: .zero)
        
        isBezeled = false
        drawsBackground = false
        isEditable = false
        isSelectable = false
        lineBreakMode = .byTruncatingTail
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class LineNumberRulerView: NSRulerView {
    private struct Row {
        let lineNumber: Int
        let offsetY: CGFloat
        var lineView: LineNumberView?
    }
    
    private var visibleRows: [Row] = []
    private var reusable: [LineNumberView] = []
    
    private var lineNumberAttributes: [NSAttributedString.Key: Any] = [:]
    
    var fontSize: CGFloat = 11 {
        didSet {
            for row in visibleRows {
                row.lineView?.removeFromSuperview()
            }
            visibleRows = []
            needsDisplay = true
            lineNumberAttributes = [
                .font: NSFont.monospacedDigitSystemFont(ofSize: fontSize - 1, weight: .regular),
                .foregroundColor: NSColor.tertiaryLabelColor,
                .kern: -0.6,
                .paragraphStyle: {
                    let ps = NSMutableParagraphStyle()
                    ps.alignment = .right
                    return ps
                }()
            ]
        }
    }

    var font: NSFont! {
        didSet {
            self.needsDisplay = true
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    init(textView: NSTextView) {
        super.init(scrollView: textView.enclosingScrollView!, orientation: NSRulerView.Orientation.verticalRuler)
        self.font = textView.font ?? NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        self.clientView = textView
        
        postsFrameChangedNotifications = true
        NotificationCenter.default.addObserver(self, selector: #selector(pulse_frameDidChange), name: NSView.frameDidChangeNotification, object: self)
        
        NotificationCenter.default.addObserver(self, selector: #selector(pulse_textDidChange), name: NSText.didChangeNotification, object: self)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func pulse_frameDidChange(notification: NSNotification) {
        needsDisplay = true
    }
    
    @objc func pulse_textDidChange(notification: NSNotification) {
        needsDisplay = true
    }

    override func didAddSubview(_ subview: NSView) {
        super.didAddSubview(subview)
        
        if subview.className == "NSBannerView" {
            subview.isHidden = true
        }
    }
            
    override func drawHashMarksAndLabels(in rect: NSRect) {
        _drawHashMarksAndLabels(in: rect)
    }
        
    func _drawHashMarksAndLabels(in rect: NSRect) {
        guard let textView = self.clientView as? NSTextView,
              let layoutManager = textView.layoutManager else { return }
        
        let relativePoint = self.convert(NSZeroPoint, from: textView)
        
        var newVisibleRows: [Row] = []
        
        func drawLineNumber(_ lineNumber: Int, _ y: CGFloat) -> Void {
            let row = Row(lineNumber: lineNumber, offsetY: y, lineView: nil)
            newVisibleRows.append(row)
        }
                
        let visibleGlyphRange = layoutManager.glyphRange(forBoundingRect: textView.visibleRect, in: textView.textContainer!)
        let firstVisibleGlyphCharacterIndex = layoutManager.characterIndexForGlyph(at: visibleGlyphRange.location)
        
        var lineNumber = newLineRegex.numberOfMatches(in: textView.string, options: [], range: NSMakeRange(0, firstVisibleGlyphCharacterIndex)) + 1
        
        var glyphIndexForStringLine = visibleGlyphRange.location
                
        // Go through each line in the string.
        while glyphIndexForStringLine < NSMaxRange(visibleGlyphRange) {
            
            // Range of current line in the string.
            let characterRangeForStringLine = (textView.string as NSString).lineRange(
                for: NSMakeRange(layoutManager.characterIndexForGlyph(at: glyphIndexForStringLine), 0)
            )
            let glyphRangeForStringLine = layoutManager.glyphRange(forCharacterRange: characterRangeForStringLine, actualCharacterRange: nil)
            
            var glyphIndexForGlyphLine = glyphIndexForStringLine
            var glyphLineCount = 0
            
            while ( glyphIndexForGlyphLine < NSMaxRange(glyphRangeForStringLine) ) {
                
                // See if the current line in the string spread across
                // several lines of glyphs
                var effectiveRange = NSMakeRange(0, 0)
                
                // Range of current "line of glyphs". If a line is wrapped,
                // then it will have more than one "line of glyphs"
                let lineRect = layoutManager.lineFragmentRect(forGlyphAt: glyphIndexForGlyphLine, effectiveRange: &effectiveRange, withoutAdditionalLayout: true)
                
                if glyphLineCount > 0 {
//                    drawLineNumber("", lineRect.minY + 4)
                } else {
                    drawLineNumber(lineNumber, lineRect.minY + 4 + textView.textContainerInset.height)
                }
                
                // Move to next glyph line
                glyphLineCount += 1
                glyphIndexForGlyphLine = NSMaxRange(effectiveRange)
            }
            
            glyphIndexForStringLine = NSMaxRange(glyphRangeForStringLine)
            lineNumber += 1
        }
                
        // Draw line number for the extra line at the end of the text
        if layoutManager.extraLineFragmentTextContainer != nil {
            drawLineNumber(lineNumber, layoutManager.extraLineFragmentRect.minY)
        }

        let newVisibleRange: Range<Int>
        if newVisibleRows.count > 0 {
            newVisibleRange = newVisibleRows.first!.lineNumber..<(newVisibleRows.last!.lineNumber + 1)
        } else {
            newVisibleRange = 0..<0
        }
        
        // Find all of the visible rows that can be reused and attach it to the new items
        // Remove all of the remaining old rows adding them to the reuse pool
        for row in visibleRows {
            let lineView = row.lineView!
            if newVisibleRange.contains(row.lineNumber) {
                newVisibleRows[row.lineNumber - newVisibleRange.startIndex].lineView = lineView
            } else {
                reusable.append(lineView)
            }
        }
    
        // Create missing rows
        for (index, row) in newVisibleRows.enumerated() {
            if row.lineView == nil {
                var lineView: LineNumberView! = reusable.popLast()
                if lineView == nil {
                    lineView = LineNumberView()
                    addSubview(lineView)
                } else {
                    if lineView.isHidden {
                        lineView.isHidden = false
                    }
                }
                lineView.attributedStringValue = NSAttributedString(string: "\(row.lineNumber)", attributes: lineNumberAttributes)
                newVisibleRows[index].lineView = lineView
            }
        }
        
        // Relayout all views
        for row in newVisibleRows {
            let rect = NSRect(x: 0, y: relativePoint.y + row.offsetY, width: bounds.width - 5, height: fontSize + 5)
            if row.lineView!.frame != rect {
                row.lineView!.frame = rect
            }
        }
        
        for view in reusable {
            if !view.isHidden {
                view.isHidden = true
            }
        }
        
        // Commit changes
        self.visibleRows = newVisibleRows
    }
}
