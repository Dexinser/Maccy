import AppKit.NSImage

// Based on https://stackoverflow.com/questions/73062803/resizing-nsimage-keeping-aspect-ratio-reducing-the-image-size-while-trying-to-sc.
extension NSImage {
  func resized(to newSize: NSSize) -> NSImage {
    guard size.width > 0, size.height > 0, newSize.width > 0, newSize.height > 0 else {
      return self
    }

    let ratioX = newSize.width / size.width
    let ratioY = newSize.height / size.height
    let ratio = ratioX < ratioY ? ratioX : ratioY
    let newHeight = size.height * ratio
    let newWidth = size.width * ratio
    let newSize = NSSize(width: newWidth, height: newHeight)

    // Don't attempt to size up.
    if newSize.height >= size.height {
      return self
    }

    guard let bitmap = NSBitmapImageRep(
      bitmapDataPlanes: nil,
      pixelsWide: max(1, Int(newSize.width.rounded(.up))),
      pixelsHigh: max(1, Int(newSize.height.rounded(.up))),
      bitsPerSample: 8,
      samplesPerPixel: 4,
      hasAlpha: true,
      isPlanar: false,
      colorSpaceName: .deviceRGB,
      bitmapFormat: [.alphaFirst],
      bytesPerRow: 0,
      bitsPerPixel: 0
    ) else {
      return self
    }

    bitmap.size = newSize

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    NSGraphicsContext.current?.imageInterpolation = .high
    draw(in: NSRect(origin: .zero, size: newSize), from: .zero, operation: .copy, fraction: 1)
    NSGraphicsContext.restoreGraphicsState()

    let image = NSImage(size: newSize)
    image.addRepresentation(bitmap)
    return image
  }
}
