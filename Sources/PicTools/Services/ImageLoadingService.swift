import AppKit
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

struct LoadedImage {
    let item: ImageItem
    let preview: NSImage
}

enum ImageLoadingService {
    static func load(url: URL) -> LoadedImage? {
        guard
            let source = CGImageSourceCreateWithURL(url as CFURL, nil),
            let cgImage = orientedImage(from: source)
        else {
            return nil
        }

        let type = sourceType(from: source) ?? typeFromExtension(url) ?? .image
        let fileSize = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? NSNumber)?.int64Value ?? 0
        let pixelSize = CGSize(width: cgImage.width, height: cgImage.height)
        let item = ImageItem(url: url, type: type, pixelSize: pixelSize, fileSize: fileSize)
        let preview = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))

        return LoadedImage(item: item, preview: preview)
    }

    static func preview(url: URL) -> NSImage? {
        guard
            let source = CGImageSourceCreateWithURL(url as CFURL, nil),
            let cgImage = CGImageSourceCreateThumbnailAtIndex(
                source,
                0,
                [
                    kCGImageSourceCreateThumbnailFromImageAlways: true,
                    kCGImageSourceThumbnailMaxPixelSize: 1600,
                    kCGImageSourceCreateThumbnailWithTransform: true
                ] as CFDictionary
            )
        else {
            return nil
        }

        return NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
    }

    static func isLoadableImage(_ url: URL) -> Bool {
        load(url: url) != nil
    }

    private static func sourceType(from source: CGImageSource) -> UTType? {
        guard let identifier = CGImageSourceGetType(source) else {
            return nil
        }
        return UTType(identifier as String)
    }

    private static func typeFromExtension(_ url: URL) -> UTType? {
        UTType(filenameExtension: url.pathExtension)
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
