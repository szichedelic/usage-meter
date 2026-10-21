import SwiftUI

struct MenuBarIcon: View {
    @ObservedObject var store: UsageStore

    var body: some View {
        if let percentUsed = store.highestUsage {
            Image(nsImage: Self.dot(color: NSColor(ThemeColors.barColor(for: percentUsed))))
            Text("\(Int((percentUsed * 100).rounded()))%")
        } else {
            Image(systemName: "gauge.with.dots.needle.50percent")
        }
    }

    // Menu bar labels only render Image and Text, and tint template images,
    // so the dot is drawn as a non-template NSImage to keep its color.
    private static func dot(color: NSColor) -> NSImage {
        let image = NSImage(size: NSSize(width: 8, height: 8), flipped: false) { rect in
            color.setFill()
            NSBezierPath(ovalIn: rect).fill()
            return true
        }
        image.isTemplate = false
        return image
    }
}
