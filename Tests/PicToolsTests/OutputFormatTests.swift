import UniformTypeIdentifiers
import XCTest
@testable import PicTools

final class OutputFormatTests: XCTestCase {
    func testKeepOriginalUsesSourceType() {
        XCTAssertEqual(OutputFormat.keepOriginal.resolvedType(sourceType: .png), .png)
    }

    func testJPEGMapsToJpegType() {
        XCTAssertEqual(OutputFormat.jpeg.resolvedType(sourceType: .png), .jpeg)
    }

    func testPreferredExtension() {
        XCTAssertEqual(OutputFormat.png.resolvedType(sourceType: .jpeg).preferredFilenameExtension, "png")
    }
}
