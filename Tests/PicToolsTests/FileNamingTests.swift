import UniformTypeIdentifiers
import XCTest
@testable import PicTools

final class FileNamingTests: XCTestCase {
    func testUsesOriginalBaseNameAndOutputExtension() throws {
        let folder = try temporaryFolder()
        let source = folder.appendingPathComponent("photo.png")

        let output = FileNaming.uniqueOutputURL(sourceURL: source, outputFolder: folder, outputType: .jpeg)

        XCTAssertEqual(output.lastPathComponent, "photo.jpg")
    }

    func testAddsNumericSuffixForCollisions() throws {
        let folder = try temporaryFolder()
        let source = folder.appendingPathComponent("photo.png")
        FileManager.default.createFile(atPath: folder.appendingPathComponent("photo.jpg").path, contents: Data())
        FileManager.default.createFile(atPath: folder.appendingPathComponent("photo-1.jpg").path, contents: Data())

        let output = FileNaming.uniqueOutputURL(sourceURL: source, outputFolder: folder, outputType: .jpeg)

        XCTAssertEqual(output.lastPathComponent, "photo-2.jpg")
    }

    private func temporaryFolder() throws -> URL {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }
}
