// Generates the app icon: a treemap under a magnifying lens.
// Usage: swift scripts/generate-icon.swift <output.png>
// The PNG is 1024×1024; turn it into an .icns with sips + iconutil
// (see scripts/generate-icon.sh).

import AppKit
import CoreGraphics

let canvas: CGFloat = 1024
// macOS Big Sur icon grid: the rounded square occupies ~824 pt of a 1024 pt
// canvas with a ~185 pt corner radius.
let iconRect = CGRect(x: 100, y: 100, width: 824, height: 824)
let cornerRadius: CGFloat = 185

let palette: [NSColor] = [
    NSColor(red: 0.95, green: 0.61, blue: 0.15, alpha: 1),  // orange
    NSColor(red: 0.25, green: 0.56, blue: 0.92, alpha: 1),  // blue
    NSColor(red: 0.36, green: 0.72, blue: 0.36, alpha: 1),  // green
    NSColor(red: 0.85, green: 0.35, blue: 0.37, alpha: 1),  // red
    NSColor(red: 0.60, green: 0.42, blue: 0.86, alpha: 1),  // purple
    NSColor(red: 0.22, green: 0.68, blue: 0.72, alpha: 1),  // teal
    NSColor(red: 0.91, green: 0.47, blue: 0.65, alpha: 1),  // pink
    NSColor(red: 0.71, green: 0.63, blue: 0.28, alpha: 1),  // olive
]

/// Minimal squarified treemap, values sorted descending.
func squarify(values: [Double], in rect: CGRect) -> [CGRect] {
    let total = values.reduce(0, +)
    guard total > 0 else { return [] }
    let scale = Double(rect.width * rect.height) / total
    let areas = values.map { $0 * scale }
    var result: [CGRect] = []
    var remaining = rect
    var index = 0

    func worst(_ sum: Double, _ minA: Double, _ maxA: Double, _ side: Double) -> Double {
        let s2 = sum * sum, side2 = side * side
        return max(side2 * maxA / s2, s2 / (side2 * minA))
    }

    while index < areas.count {
        let side = Double(min(remaining.width, remaining.height))
        var end = index + 1
        var sum = areas[index]
        var w = worst(sum, areas[index], areas[index], side)
        while end < areas.count {
            let cand = sum + areas[end]
            let cw = worst(cand, areas[end], areas[index], side)
            if cw > w { break }
            sum = cand; w = cw; end += 1
        }
        if remaining.width >= remaining.height {
            let rowW = CGFloat(sum) / remaining.height
            var y = remaining.minY
            for i in index..<end {
                let h = CGFloat(areas[i]) / rowW
                result.append(CGRect(x: remaining.minX, y: y, width: rowW, height: h))
                y += h
            }
            remaining = CGRect(x: remaining.minX + rowW, y: remaining.minY,
                               width: remaining.width - rowW, height: remaining.height)
        } else {
            let rowH = CGFloat(sum) / remaining.width
            var x = remaining.minX
            for i in index..<end {
                let wdt = CGFloat(areas[i]) / rowH
                result.append(CGRect(x: x, y: remaining.minY, width: wdt, height: rowH))
                x += wdt
            }
            remaining = CGRect(x: remaining.minX, y: remaining.minY + rowH,
                               width: remaining.width, height: remaining.height - rowH)
        }
        index = end
    }
    return result
}

guard CommandLine.arguments.count > 1 else {
    FileHandle.standardError.write(Data("Usage: swift generate-icon.swift <output.png>\n".utf8))
    exit(1)
}
let outputPath = CommandLine.arguments[1]

let image = NSImage(size: NSSize(width: canvas, height: canvas))
image.lockFocus()
guard let ctx = NSGraphicsContext.current?.cgContext else { exit(1) }

// Background: rounded square with a dark vertical gradient.
let bgPath = NSBezierPath(roundedRect: iconRect, xRadius: cornerRadius, yRadius: cornerRadius)
ctx.saveGState()
bgPath.addClip()
let gradient = NSGradient(
    starting: NSColor(red: 0.13, green: 0.15, blue: 0.22, alpha: 1),
    ending: NSColor(red: 0.05, green: 0.06, blue: 0.10, alpha: 1)
)
gradient?.draw(in: iconRect, angle: -90)

// Treemap tiles.
let values: [Double] = [34, 21, 13, 8, 8, 5, 4, 3, 2, 1.5, 1]
let tileArea = iconRect.insetBy(dx: 72, dy: 72)
let rects = squarify(values: values, in: tileArea)
for (i, r) in rects.enumerated() {
    let tile = r.insetBy(dx: 7, dy: 7)
    guard tile.width > 0, tile.height > 0 else { continue }
    let path = NSBezierPath(roundedRect: tile, xRadius: 14, yRadius: 14)
    palette[i % palette.count].withAlphaComponent(0.92).setFill()
    path.fill()
}
ctx.restoreGState()

// Magnifying lens over the largest tile area.
let lensCenter = CGPoint(x: 620, y: 430)
let lensRadius: CGFloat = 195
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -10), blur: 30,
              color: NSColor.black.withAlphaComponent(0.55).cgColor)

// Handle.
let handleAngle: CGFloat = -45 * .pi / 180
let handleStart = CGPoint(x: lensCenter.x + cos(handleAngle) * (lensRadius + 8),
                          y: lensCenter.y + sin(handleAngle) * (lensRadius + 8))
let handleEnd = CGPoint(x: lensCenter.x + cos(handleAngle) * (lensRadius + 145),
                        y: lensCenter.y + sin(handleAngle) * (lensRadius + 145))
let handle = NSBezierPath()
handle.move(to: handleStart)
handle.line(to: handleEnd)
handle.lineWidth = 64
handle.lineCapStyle = .round
NSColor(white: 0.94, alpha: 1).setStroke()
handle.stroke()

// Ring.
let ring = NSBezierPath(ovalIn: CGRect(x: lensCenter.x - lensRadius, y: lensCenter.y - lensRadius,
                                       width: lensRadius * 2, height: lensRadius * 2))
ring.lineWidth = 44
NSColor(white: 0.94, alpha: 1).setStroke()
ring.stroke()
ctx.restoreGState()

// Subtle glass tint + highlight inside the lens.
let glass = NSBezierPath(ovalIn: CGRect(x: lensCenter.x - lensRadius + 22, y: lensCenter.y - lensRadius + 22,
                                        width: (lensRadius - 22) * 2, height: (lensRadius - 22) * 2))
NSColor(white: 1.0, alpha: 0.10).setFill()
glass.fill()
let highlight = NSBezierPath(ovalIn: CGRect(x: lensCenter.x - 110, y: lensCenter.y + 40,
                                            width: 150, height: 80))
NSColor(white: 1.0, alpha: 0.18).setFill()
highlight.fill()

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else {
    FileHandle.standardError.write(Data("Failed to render PNG\n".utf8))
    exit(1)
}
try png.write(to: URL(fileURLWithPath: outputPath))
print("Wrote \(outputPath)")
