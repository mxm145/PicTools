import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers
import XCTest
@testable import PicTools

final class ImageExportServiceTests: XCTestCase {
    func testExportsJPEGCopyWithoutChangingSource() throws {
        let folder = try temporaryFolder()
        let source = folder.appendingPathComponent("source.png")
        try makeImage(at: source, type: .png, width: 8, height: 6)
        let originalData = try Data(contentsOf: source)
        let loaded = try XCTUnwrap(ImageLoadingService.load(url: source))

        let output = try ImageExportService.export(
            ImageExportRequest(
                item: loaded.item,
                outputFolder: folder,
                outputFormat: .jpeg,
                quality: 0.7
            )
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: output.path))
        XCTAssertEqual(output.pathExtension.lowercased(), "jpg")
        XCTAssertEqual(try Data(contentsOf: source), originalData)
    }

    func testExportsCroppedImage() throws {
        let folder = try temporaryFolder()
        let source = folder.appendingPathComponent("source.png")
        try makeImage(at: source, type: .png, width: 10, height: 10)
        var item = try XCTUnwrap(ImageLoadingService.load(url: source)).item
        item.cropSettings = CropSettings(width: 4, height: 4, anchor: .center, selection: nil)

        let output = try ImageExportService.export(
            ImageExportRequest(item: item, outputFolder: folder, outputFormat: .png, quality: 1.0)
        )

        let loaded = try XCTUnwrap(ImageLoadingService.load(url: output))
        XCTAssertEqual(loaded.item.pixelSize, CGSize(width: 4, height: 4))
    }

    func testExportsResizedImage() throws {
        let folder = try temporaryFolder()
        let source = folder.appendingPathComponent("source.png")
        try makeImage(at: source, type: .png, width: 10, height: 8)
        var item = try XCTUnwrap(ImageLoadingService.load(url: source)).item
        item.resizeSettings = ResizeSettings(width: 5, height: 4, preservesAspectRatio: true)

        let output = try ImageExportService.export(
            ImageExportRequest(item: item, outputFolder: folder, outputFormat: .png, quality: 1.0)
        )

        let loaded = try XCTUnwrap(ImageLoadingService.load(url: output))
        XCTAssertEqual(loaded.item.pixelSize, CGSize(width: 5, height: 4))
    }

    func testTopAnchoredCropExportsTopPixels() throws {
        let folder = try temporaryFolder()
        let source = folder.appendingPathComponent("source.png")
        try makeTopRedBottomBlueImage(at: source, width: 4, height: 4)
        var item = try XCTUnwrap(ImageLoadingService.load(url: source)).item
        item.cropSettings = CropSettings(width: 4, height: 2, anchor: .topLeft, selection: nil)

        let output = try ImageExportService.export(
            ImageExportRequest(item: item, outputFolder: folder, outputFormat: .png, quality: 1.0)
        )

        let topLeft = try topLeftPixel(at: output)
        XCTAssertGreaterThan(topLeft.red, 200)
        XCTAssertLessThan(topLeft.blue, 80)
    }

    private func temporaryFolder() throws -> URL {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }

    private func makeImage(at url: URL, type: UTType, width: Int, height: Int) throws {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = try XCTUnwrap(
            CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        )
        context.setFillColor(CGColor(red: 0.2, green: 0.6, blue: 0.9, alpha: 1.0))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        let image = try XCTUnwrap(context.makeImage())
        let destination = try XCTUnwrap(CGImageDestinationCreateWithURL(url as CFURL, type.identifier as CFString, 1, nil))
        CGImageDestinationAddImage(destination, image, nil)
        XCTAssertTrue(CGImageDestinationFinalize(destination))
    }

    private func makeTopRedBottomBlueImage(at url: URL, width: Int, height: Int) throws {
        var pixels: [UInt8] = []
        for y in 0..<height {
            for _ in 0..<width {
                if y < height / 2 {
                    pixels.append(contentsOf: [255, 0, 0, 255])
                } else {
                    pixels.append(contentsOf: [0, 0, 255, 255])
                }
            }
        }

        let data = Data(pixels)
        let provider = try XCTUnwrap(CGDataProvider(data: data as CFData))
        let image = try XCTUnwrap(
            CGImage(
                width: width,
                height: height,
                bitsPerComponent: 8,
                bitsPerPixel: 32,
                bytesPerRow: width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                provider: provider,
                decode: nil,
                shouldInterpolate: false,
                intent: .defaultIntent
            )
        )
        let destination = try XCTUnwrap(CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil))
        CGImageDestinationAddImage(destination, image, nil)
        XCTAssertTrue(CGImageDestinationFinalize(destination))
    }

    private func topLeftPixel(at url: URL) throws -> (red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8) {
        let source = try XCTUnwrap(CGImageSourceCreateWithURL(url as CFURL, nil))
        let image = try XCTUnwrap(CGImageSourceCreateImageAtIndex(source, 0, nil))
        let data = try XCTUnwrap(image.dataProvider?.data as Data?)
        return (data[0], data[1], data[2], data[3])
    }
}
