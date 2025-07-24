// ABOUTME: Fullscreen overlay window for interactive region selection
// ABOUTME: Handles mouse drag events to define capture region with ScreenCaptureKit

import AppKit
import Foundation

class RegionSelectionOverlay: NSWindow {
    fileprivate var startPoint: NSPoint = .zero
    fileprivate var currentPoint: NSPoint = .zero
    fileprivate var isDragging = false
    private var completion: ((NSRect?) -> Void)?
    
    init(completion: @escaping (NSRect?) -> Void) {
        self.completion = completion
        
        // Create fullscreen window covering all displays
        let screenFrame = NSScreen.screens.reduce(NSRect.zero) { result, screen in
            return result.union(screen.frame)
        }
        
        super.init(
            contentRect: screenFrame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        
        // Configure window for overlay
        self.backgroundColor = NSColor.black.withAlphaComponent(0.3)
        self.level = NSWindow.Level.screenSaver
        self.isOpaque = false
        self.hasShadow = false
        self.ignoresMouseEvents = false
        self.collectionBehavior = [.transient, .ignoresCycle]
        
        // Set up content view
        let overlayView = RegionSelectionView()
        overlayView.overlay = self
        self.contentView = overlayView
        
        // Accept mouse events
        self.acceptsMouseMovedEvents = true
    }
    
    func startSelection() {
        self.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func updateSelection(start: NSPoint, current: NSPoint) {
        startPoint = start
        currentPoint = current
        contentView?.needsDisplay = true
    }
    
    func completeSelection() {
        defer {
            cleanup()
        }
        
        guard isDragging else {
            // User clicked without dragging - cancel
            completion?(nil)
            return
        }
        
        // Convert window coordinates to screen coordinates
        let selectionRect = NSRect(
            x: min(startPoint.x, currentPoint.x),
            y: min(startPoint.y, currentPoint.y),
            width: abs(currentPoint.x - startPoint.x),
            height: abs(currentPoint.y - startPoint.y)
        )
        
        // Only proceed if selection has meaningful size
        if selectionRect.width > 10 && selectionRect.height > 10 {
            completion?(selectionRect)
        } else {
            completion?(nil)
        }
    }
    
    func cancelSelection() {
        completion?(nil)
        cleanup()
    }
    
    private func cleanup() {
        completion = nil
        orderOut(nil)
        DispatchQueue.main.async { [weak self] in
            self?.close()
        }
    }
    
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Escape key
            cancelSelection()
        }
    }
    
    func setDragging(_ dragging: Bool) {
        isDragging = dragging
    }
}

class RegionSelectionView: NSView {
    weak var overlay: RegionSelectionOverlay?
    
    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        overlay?.startPoint = point
        overlay?.currentPoint = point
        overlay?.setDragging(false)
    }
    
    override func mouseDragged(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        overlay?.setDragging(true)
        overlay?.updateSelection(start: overlay?.startPoint ?? .zero, current: point)
    }
    
    override func mouseUp(with event: NSEvent) {
        overlay?.completeSelection()
    }
    
    override func draw(_ dirtyRect: NSRect) {
        // Fill the entire view with semi-transparent dark overlay
        NSColor.black.withAlphaComponent(0.3).setFill()
        dirtyRect.fill()
        
        guard let overlay = overlay, overlay.isDragging else { return }
        
        // Calculate selection rectangle
        let selectionRect = NSRect(
            x: min(overlay.startPoint.x, overlay.currentPoint.x),
            y: min(overlay.startPoint.y, overlay.currentPoint.y),
            width: abs(overlay.currentPoint.x - overlay.startPoint.x),
            height: abs(overlay.currentPoint.y - overlay.startPoint.y)
        )
        
        // Clear the selection area by drawing with clear color
        NSColor.clear.setFill()
        selectionRect.fill()
        
        // Draw selection border
        NSColor.white.setStroke()
        let path = NSBezierPath(rect: selectionRect)
        path.lineWidth = 2.0
        path.stroke()
        
        // Draw dimension text
        let dimensions = "\(Int(selectionRect.width)) × \(Int(selectionRect.height))"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12),
            .foregroundColor: NSColor.white,
            .backgroundColor: NSColor.black.withAlphaComponent(0.7)
        ]
        
        let textSize = dimensions.size(withAttributes: attributes)
        let textRect = NSRect(
            x: selectionRect.maxX - textSize.width - 5,
            y: selectionRect.maxY + 5,
            width: textSize.width,
            height: textSize.height
        )
        
        dimensions.draw(in: textRect, withAttributes: attributes)
    }
    
    override var acceptsFirstResponder: Bool { true }
}