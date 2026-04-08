import Cocoa

func roundImage(inputPath: String, outputPath: String, radius: CGFloat) {
    guard let image = NSImage(contentsOfFile: inputPath) else {
        print("Could not load image at \(inputPath)")
        return
    }

    let rect = NSRect(origin: .zero, size: image.size)
    let newImage = NSImage(size: image.size)
    
    newImage.lockFocus()
    let clipPath = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    clipPath.addClip()
    image.draw(in: rect)
    newImage.unlockFocus()
    
    guard let cgImage = newImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
        print("Could not create CGImage")
        return
    }
    let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
    guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
        print("Could not get PNG representation")
        return
    }
    
    do {
        try pngData.write(to: URL(fileURLWithPath: outputPath))
        print("Saved rounded image to \(outputPath)")
    } catch {
        print("Could not save image: \(error)")
    }
}

let args = CommandLine.arguments
if args.count < 4 {
    print("Usage: swift make_rounded.swift <input> <output> <radius>")
    exit(1)
}

let input = args[1]
let output = args[2]
if let r = Double(args[3]) {
    roundImage(inputPath: input, outputPath: output, radius: CGFloat(r))
} else {
    print("Invalid radius")
}
