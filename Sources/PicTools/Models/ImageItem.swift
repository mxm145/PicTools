import CoreGraphics
import Foundation
import UniformTypeIdentifiers

enum ImageStatus: Equatable {
    case ready
    case exporting
    case exported(URL)
    case failed(String)

    var label: String {
        switch self {
        case .ready: "Ready"
        case .exporting: "Exporting"
        case .exported: "Exported"
        case .failed: "Failed"
        }
    }
}

struct ImageItem: Identifiable, Equatable {
    let id: UUID
    let url: URL
    var type: UTType
    var pixelSize: CGSize
    var fileSize: Int64
    var cropSettings: CropSettings?
    var resizeSettings: ResizeSettings?
    var status: ImageStatus

    init(
        id: UUID = UUID(),
        url: URL,
        type: UTType,
        pixelSize: CGSize,
        fileSize: Int64,
        cropSettings: CropSettings? = nil,
        resizeSettings: ResizeSettings? = nil,
        status: ImageStatus = .ready
    ) {
        self.id = id
        self.url = url
        self.type = type
        self.pixelSize = pixelSize
        self.fileSize = fileSize
        self.cropSettings = cropSettings
        self.resizeSettings = resizeSettings
        self.status = status
    }

    var displayPixelSize: CGSize {
        let croppedSize = cropSettings?.cropRect(in: pixelSize).size ?? pixelSize
        return resizeSettings?.outputSize(sourceSize: croppedSize) ?? croppedSize
    }

    var hasCrop: Bool {
        cropSettings != nil
    }

    var hasResize: Bool {
        resizeSettings != nil
    }

    var hasEdits: Bool {
        hasCrop || hasResize
    }
}
