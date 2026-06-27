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
}

