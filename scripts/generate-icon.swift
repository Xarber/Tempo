// SPDX-License-Identifier: AGPL-3.0-only
import AppKit
import Foundation
let output = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "build/Tempo.iconset"
try FileManager.default.createDirectory(atPath: output, withIntermediateDirectories: true)
for size in [16,32,128,256,512] {
    for scale in [1,2] {
        let pixels = size * scale
        let image = NSImage(size: NSSize(width: pixels, height: pixels))
        image.lockFocus()
        let transform = AffineTransform(scale: Double(pixels) / 1024); (transform as NSAffineTransform).concat()
        NSColor(srgbRed: 98/255, green: 105/255, blue: 245/255, alpha: 1).setFill()
        NSBezierPath(roundedRect: NSRect(x: 0,y: 0,width: 1024,height: 1024), xRadius: 220,yRadius: 220).fill()
        NSColor.white.withAlphaComponent(0.2).setStroke()
        let track = NSBezierPath(ovalIn: NSRect(x:234,y:234,width:556,height:556)); track.lineWidth = 66; track.stroke()
        NSColor.white.setStroke()
        let ring = NSBezierPath(); ring.appendArc(withCenter: NSPoint(x:512,y:512), radius:278, startAngle:90, endAngle:-150, clockwise:true); ring.lineWidth = 66; ring.lineCapStyle = .round; ring.stroke()
        let hands = NSBezierPath(); hands.move(to: NSPoint(x:512,y:661)); hands.line(to:NSPoint(x:512,y:512)); hands.line(to:NSPoint(x:616,y:452)); hands.lineWidth = 56; hands.lineCapStyle = .round; hands.lineJoinStyle = .round; hands.stroke()
        NSColor.white.setFill(); NSBezierPath(ovalIn:NSRect(x:238,y:617,width:66,height:66)).fill()
        image.unlockFocus()
        guard let tiff = image.tiffRepresentation, let bitmap = NSBitmapImageRep(data:tiff), let png = bitmap.representation(using:.png,properties:[:]) else { fatalError("Cannot render icon") }
        let name = "icon_\(size)x\(size)\(scale == 2 ? "@2x" : "").png"
        try png.write(to:URL(fileURLWithPath:output).appendingPathComponent(name))
    }
}
