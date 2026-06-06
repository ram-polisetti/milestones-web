import AppKit

let outputURL = URL(fileURLWithPath: CommandLine.arguments[1])
let size = 1024
let colorSpace = CGColorSpaceCreateDeviceRGB()
guard let context = CGContext(
    data: nil,
    width: size,
    height: size,
    bitsPerComponent: 8,
    bytesPerRow: size * 4,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
) else {
    fatalError("Unable to create drawing context")
}

let colors = [
    NSColor(calibratedRed: 0.04, green: 0.43, blue: 0.98, alpha: 1).cgColor,
    NSColor(calibratedRed: 0.03, green: 0.73, blue: 0.95, alpha: 1).cgColor
] as CFArray
let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0, 1])!
context.drawLinearGradient(
    gradient,
    start: CGPoint(x: 90, y: 934),
    end: CGPoint(x: 934, y: 90),
    options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
)

let paragraph = NSMutableParagraphStyle()
paragraph.alignment = .center
paragraph.minimumLineHeight = 230
paragraph.maximumLineHeight = 230

let font = NSFont.monospacedSystemFont(ofSize: 230, weight: .black)
let attributes: [NSAttributedString.Key: Any] = [
    .font: font,
    .foregroundColor: NSColor.white,
    .paragraphStyle: paragraph,
    .kern: -8
]
let mark = NSAttributedString(string: "M>\n--|", attributes: attributes)
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
mark.draw(in: NSRect(x: 112, y: 267, width: 800, height: 500))
NSGraphicsContext.restoreGraphicsState()

guard let cgImage = context.makeImage() else {
    fatalError("Unable to create icon image")
}
let bitmap = NSBitmapImageRep(cgImage: cgImage)
guard let png = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Unable to encode icon")
}

try png.write(to: outputURL)
