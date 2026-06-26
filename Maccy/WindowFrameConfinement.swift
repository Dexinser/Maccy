import Foundation

enum WindowFrameConfinement {
  static func visibleFrame(for frame: NSRect, in visibleFrames: [NSRect]) -> NSRect? {
    guard !visibleFrames.isEmpty else { return nil }

    let center = NSPoint(x: frame.midX, y: frame.midY)
    if let containingFrame = visibleFrames.first(where: { $0.contains(center) }) {
      return containingFrame
    }

    let overlappingFrame = visibleFrames.max { lhs, rhs in
      lhs.intersection(frame).area < rhs.intersection(frame).area
    }
    if let overlappingFrame, overlappingFrame.intersection(frame).area > 0 {
      return overlappingFrame
    }

    return visibleFrames.min { lhs, rhs in
      lhs.center.distanceSquared(to: center) < rhs.center.distanceSquared(to: center)
    }
  }

  static func confine(frame: NSRect, in visibleFrames: [NSRect]) -> NSRect {
    guard let visibleFrame = visibleFrame(for: frame, in: visibleFrames) else {
      return frame
    }

    return confine(frame: frame, to: visibleFrame)
  }

  static func confine(frame: NSRect, to visibleFrame: NSRect) -> NSRect {
    var confinedFrame = frame

    if confinedFrame.width > visibleFrame.width {
      confinedFrame.size.width = visibleFrame.width
    }

    if confinedFrame.height > visibleFrame.height {
      confinedFrame.size.height = visibleFrame.height
    }

    confinedFrame.origin.x = min(
      max(confinedFrame.origin.x, visibleFrame.minX),
      visibleFrame.maxX - confinedFrame.width
    )
    confinedFrame.origin.y = min(
      max(confinedFrame.origin.y, visibleFrame.minY),
      visibleFrame.maxY - confinedFrame.height
    )

    return confinedFrame
  }
}

private extension NSRect {
  var area: CGFloat {
    guard !isNull, !isEmpty else { return 0 }
    return width * height
  }

  var center: NSPoint {
    return NSPoint(x: midX, y: midY)
  }
}

private extension NSPoint {
  func distanceSquared(to point: NSPoint) -> CGFloat {
    let xDistance = x - point.x
    let yDistance = y - point.y
    return xDistance * xDistance + yDistance * yDistance
  }
}
