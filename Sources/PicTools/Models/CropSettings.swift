import CoreGraphics

enum CropAnchor: String, CaseIterable, Identifiable {
    case center
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight

    var id: String { rawValue }

    var label: String {
        switch self {
        case .center: "Center"
        case .topLeft: "Top Left"
        case .topRight: "Top Right"
        case .bottomLeft: "Bottom Left"
        case .bottomRight: "Bottom Right"
        }
    }
}

struct CropSettings: Equatable {
    var width: CGFloat
    var height: CGFloat
    var anchor: CropAnchor
    var selection: CGRect?

    func cropRect(in imageSize: CGSize) -> CGRect {
        if let selection {
            return clamp(selection, to: imageSize)
        }

        let cropWidth = min(max(width, 1), imageSize.width)
        let cropHeight = min(max(height, 1), imageSize.height)
        let origin: CGPoint

        switch anchor {
        case .center:
            origin = CGPoint(x: (imageSize.width - cropWidth) / 2, y: (imageSize.height - cropHeight) / 2)
        case .topLeft:
            origin = CGPoint(x: 0, y: imageSize.height - cropHeight)
        case .topRight:
            origin = CGPoint(x: imageSize.width - cropWidth, y: imageSize.height - cropHeight)
        case .bottomLeft:
            origin = .zero
        case .bottomRight:
            origin = CGPoint(x: imageSize.width - cropWidth, y: 0)
        }

        return CGRect(origin: origin, size: CGSize(width: cropWidth, height: cropHeight)).integral
    }

    private func clamp(_ rect: CGRect, to imageSize: CGSize) -> CGRect {
        let normalized = rect.standardized
        let width = min(max(normalized.width, 1), imageSize.width)
        let height = min(max(normalized.height, 1), imageSize.height)
        let x = min(max(normalized.minX, 0), imageSize.width - width)
        let y = min(max(normalized.minY, 0), imageSize.height - height)
        return CGRect(x: x, y: y, width: width, height: height).integral
    }
}

