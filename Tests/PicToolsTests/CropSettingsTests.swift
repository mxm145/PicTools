import CoreGraphics
import XCTest
@testable import PicTools

final class CropSettingsTests: XCTestCase {
    func testCenteredOutputRect() {
        let settings = CropSettings(width: 400, height: 200, anchor: .center, selection: nil)

        XCTAssertEqual(
            settings.cropRect(in: CGSize(width: 1000, height: 800)),
            CGRect(x: 300, y: 300, width: 400, height: 200)
        )
    }

    func testBottomRightOutputRectClampsToImage() {
        let settings = CropSettings(width: 1200, height: 900, anchor: .bottomRight, selection: nil)

        XCTAssertEqual(
            settings.cropRect(in: CGSize(width: 1000, height: 800)),
            CGRect(x: 0, y: 0, width: 1000, height: 800)
        )
    }

    func testSelectionOverridesNumericAnchor() {
        let settings = CropSettings(
            width: 400,
            height: 200,
            anchor: .center,
            selection: CGRect(x: 10, y: 20, width: 300, height: 150)
        )

        XCTAssertEqual(
            settings.cropRect(in: CGSize(width: 1000, height: 800)),
            CGRect(x: 10, y: 20, width: 300, height: 150)
        )
    }

    func testTopRightOutputRect() {
        let settings = CropSettings(width: 200, height: 100, anchor: .topRight, selection: nil)

        XCTAssertEqual(
            settings.cropRect(in: CGSize(width: 1000, height: 800)),
            CGRect(x: 800, y: 0, width: 200, height: 100)
        )
    }
}
