import Foundation
import ImageIO

struct ImagePreviewInfo {
  let pixelWidth: Int?
  let pixelHeight: Int?
  let byteCount: Int?
  let formattedDataSize: String

  init(data: Data?) {
    guard let data else {
      pixelWidth = nil
      pixelHeight = nil
      byteCount = nil
      formattedDataSize = ""
      return
    }

    byteCount = data.count
    formattedDataSize = ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file)

    let properties = ImagePreviewInfo.properties(from: data)
    pixelWidth = properties?[kCGImagePropertyPixelWidth] as? Int
      ?? (properties?[kCGImagePropertyPixelWidth] as? NSNumber)?.intValue
    pixelHeight = properties?[kCGImagePropertyPixelHeight] as? Int
      ?? (properties?[kCGImagePropertyPixelHeight] as? NSNumber)?.intValue
  }

  var dimensions: String? {
    guard let pixelWidth, let pixelHeight else {
      return nil
    }

    return "\(pixelWidth) x \(pixelHeight) px"
  }

  private static func properties(from data: Data) -> [CFString: Any]? {
    guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
      return nil
    }

    return CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
  }
}
