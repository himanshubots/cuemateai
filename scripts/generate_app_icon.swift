import AppKit
import Foundation

let arguments = CommandLine.arguments
guard arguments.count >= 2 else {
    fputs("Usage: generate_app_icon.swift <iconset-directory>\n", stderr)
    exit(1)
}

let outputDirectory = URL(fileURLWithPath: arguments[1], isDirectory: true)
try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

let iconFiles: [(String, CGFloat)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

for (fileName, side) in iconFiles {
    let image = NSImage(size: NSSize(width: side, height: side))
    image.lockFocus()

    guard let context = NSGraphicsContext.current?.cgContext else {
        continue
    }

    let rect = CGRect(x: 0, y: 0, width: side, height: side)
    let gradientColors = [
        NSColor(calibratedRed: 0.96, green: 0.51, blue: 0.28, alpha: 1.0).cgColor,
        NSColor(calibratedRed: 0.15, green: 0.26, blue: 0.58, alpha: 1.0).cgColor
    ] as CFArray
    let gradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: gradientColors,
        locations: [0.0, 1.0]
    )!

    let rounded = NSBezierPath(roundedRect: rect.insetBy(dx: side * 0.06, dy: side * 0.06), xRadius: side * 0.22, yRadius: side * 0.22)
    rounded.addClip()
    context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 0), end: CGPoint(x: side, y: side), options: [])

    let glowRect = rect.insetBy(dx: side * 0.18, dy: side * 0.18)
    let glowPath = NSBezierPath(ovalIn: glowRect)
    NSColor.white.withAlphaComponent(0.12).setFill()
    glowPath.fill()

    let waveform = NSBezierPath()
    waveform.lineWidth = max(2, side * 0.045)
    waveform.lineCapStyle = .round
    waveform.move(to: CGPoint(x: side * 0.20, y: side * 0.48))
    waveform.line(to: CGPoint(x: side * 0.32, y: side * 0.48))
    waveform.line(to: CGPoint(x: side * 0.40, y: side * 0.68))
    waveform.line(to: CGPoint(x: side * 0.50, y: side * 0.28))
    waveform.line(to: CGPoint(x: side * 0.60, y: side * 0.64))
    waveform.line(to: CGPoint(x: side * 0.70, y: side * 0.40))
    waveform.line(to: CGPoint(x: side * 0.82, y: side * 0.40))
    NSColor.white.withAlphaComponent(0.92).setStroke()
    waveform.stroke()

    let micStand = NSBezierPath(roundedRect: CGRect(x: side * 0.46, y: side * 0.20, width: side * 0.08, height: side * 0.10), xRadius: side * 0.02, yRadius: side * 0.02)
    NSColor.white.withAlphaComponent(0.88).setFill()
    micStand.fill()

    let micBody = NSBezierPath(roundedRect: CGRect(x: side * 0.39, y: side * 0.34, width: side * 0.22, height: side * 0.24), xRadius: side * 0.11, yRadius: side * 0.11)
    NSColor.white.withAlphaComponent(0.18).setFill()
    micBody.fill()
    NSColor.white.withAlphaComponent(0.88).setStroke()
    micBody.lineWidth = max(2, side * 0.028)
    micBody.stroke()

    image.unlockFocus()

    guard
        let tiffData = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiffData),
        let pngData = bitmap.representation(using: .png, properties: [:])
    else {
        continue
    }

    try pngData.write(to: outputDirectory.appendingPathComponent(fileName), options: .atomic)
}
