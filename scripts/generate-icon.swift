import AppKit

// Approved mark: a three-quarter quota ring with vertical green, amber and red dots.
// Coordinates use a 1024-point canvas, with transparent macOS icon margins.
let output = CommandLine.arguments.dropFirst().first ?? "assets"
let root = URL(fileURLWithPath:output, isDirectory:true)
let iconset = root.appendingPathComponent("AppIcon.iconset", isDirectory:true)
try FileManager.default.createDirectory(at:iconset,withIntermediateDirectories:true)
func png(_ pixels:Int, appIcon:Bool = true) throws -> Data {
    let bitmap=NSBitmapImageRep(bitmapDataPlanes:nil,pixelsWide:pixels,pixelsHigh:pixels,bitsPerSample:8,samplesPerPixel:4,hasAlpha:true,isPlanar:false,colorSpaceName:.deviceRGB,bytesPerRow:0,bitsPerPixel:0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current=NSGraphicsContext(bitmapImageRep:bitmap)
    let scale=CGFloat(pixels)/1024
    let transform=NSAffineTransform();transform.scale(by:scale);transform.concat()
    if appIcon {
        NSColor(srgbRed:0.985,green:0.981,blue:0.965,alpha:1).setFill()
        NSBezierPath(roundedRect:NSRect(x:64,y:64,width:896,height:896),xRadius:200,yRadius:200).fill()
    }
    NSColor(srgbRed:0.87,green:0.87,blue:0.87,alpha:1).setStroke()
    let track=NSBezierPath(ovalIn:NSRect(x:218,y:218,width:588,height:588))
    track.lineWidth=68;track.stroke()
    NSColor(srgbRed:0.16,green:0.17,blue:0.18,alpha:1).setStroke()
    let ring=NSBezierPath();ring.lineWidth=68;ring.lineCapStyle = .round
    ring.appendArc(withCenter:NSPoint(x:512,y:512),radius:294,startAngle:90,endAngle:-180,clockwise:true)
    ring.stroke()
    for (y,color) in [(622.0,NSColor(srgbRed:0.153,green:0.518,blue:0.329,alpha:1)),
                      (512.0,NSColor(srgbRed:0.839,green:0.608,blue:0.137,alpha:1)),
                      (402.0,NSColor(srgbRed:0.847,green:0.345,blue:0.290,alpha:1))] {
        color.setFill()
        NSBezierPath(ovalIn:NSRect(x:468,y:y-44,width:88,height:88)).fill()
    }
    NSGraphicsContext.restoreGraphicsState()
    return bitmap.representation(using:.png,properties:[:])!
}
for size in [16,32,128,256,512] {
    try png(size).write(to:iconset.appendingPathComponent("icon_\(size)x\(size).png"))
    try png(size*2).write(to:iconset.appendingPathComponent("icon_\(size)x\(size)@2x.png"))
}
try png(1024,appIcon:false).write(to:root.appendingPathComponent("nextreset-logo.png"))
try png(256).write(to:root.appendingPathComponent("app-icon-preview.png"))
