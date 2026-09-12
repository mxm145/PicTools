import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

enum ImageExportError: LocalizedError {
    case cannotLoadSource
    case cannotCreateDestination
    case cannotWriteImage

    var errorDescription: String? {
        switch self {
        case .cannotLoadSource: "Could not load source image."
        case .cannotCreateDestination: "Could not create output image."
        case .cannotWriteImage: "Could not write output image."
        }
    }
}

struct ImageExportRequest {
    var item: ImageItem
    var outputFolder: URL
    var outputFormat: OutputFormat
    var quality: Double
}

enum ImageExportService {
    static func export(_ request: ImageExportRequest) throws -> URL {
        guard
            let source = CGImageSourceCreateWithURL(request.item.url as CFURL, nil),
            var image = orientedImage(from: source)
        else {
            throw ImageExportError.cannotLoadSource
        }

        if let cropSettings = request.item.cropSettings {
            let rect = cropSettings.cropRect(in: CGSize(width: image.width, height: image.height))
            if let cropped = image.cropping(to: rect) {
                image = cropped
            }
        }

        if let resizeSettings = request.item.resizeSettings,
           let resized = resizedImage(image, to: resizeSettings.outputSize(sourceSize: CGSize(width: image.width, height: image.height))) {
            image = resized
        }

        let outputType = request.outputFormat.resolvedType(sourceType: request.item.type)
        let outputURL = FileNaming.uniqueOutputURL(
            sourceURL: request.item.url,
            outputFolder: request.outputFolder,
            outputType: outputType
        )

        guard let destination = CGImageDestinationCreateWithURL(outputURL as CFURL, outputType.identifier as CFString, 1, nil) else {
            throw ImageExportError.cannotCreateDestination
        }

        let properties = destinationProperties(for: outputType, quality: request.quality)
        CGImageDestinationAddImage(destination, image, properties as CFDictionary)

        guard CGImageDestinationFinalize(destination) else {
            throw ImageExportError.cannotWriteImage
        }

        return outputURL
    }

    private static func destinationProperties(for type: UTType, quality: Double) -> [CFString: Any] {
        let clampedQuality = min(max(quality, 0.1), 1.0)
        if type.conforms(to: .jpeg) || type.conforms(to: .heic) || type.identifier.lowercased().contains("webp") {
            return [kCGImageDestinationLossyCompressionQuality: clampedQuality]
        }

        return [:]
    }

    private static func resizedImage(_ image: CGImage, to size: CGSize) -> CGImage? {
        let width = Int(size.width.rounded())
        let height = Int(size.height.rounded())
        guard width > 0, height > 0, width != image.width || height != image.height else {
            return image
        }

        let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
        context?.interpolationQuality = .high
        context?.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        return context?.makeImage()
    }

    private static func orientedImage(from source: CGImageSource) -> CGImage? {
        let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
        let width = properties?[kCGImagePropertyPixelWidth] as? Int ?? 0
        let height = properties?[kCGImagePropertyPixelHeight] as? Int ?? 0
        let maxPixelSize = max(width, height)

        guard maxPixelSize > 0 else {
            return CGImageSourceCreateImageAtIndex(source, 0, nil)
        }

        return CGImageSourceCreateThumbnailAtIndex(
            source,
            0,
            [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
                kCGImageSourceCreateThumbnailWithTransform: true
            ] as CFDictionary
        ) ?? CGImageSourceCreateImageAtIndex(source, 0, nil)
    }
}
