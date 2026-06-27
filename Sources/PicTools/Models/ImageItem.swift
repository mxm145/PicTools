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
    var status: ImageStatus

    init(
        id: UUID = UUID(),
        url: URL,
        type: UTType,
        pixelSize: CGSize,
        fileSize: Int64,
        cropSettings: CropSettings? = nil,
        status: ImageStatus = .ready
    ) {
        self.id = id
        self.url = url
        self.type = type
        self.pixelSize = pixelSize
        self.fileSize = fileSize
        self.cropSettings = cropSettings
        self.status = status
    }

    var displayPixelSize: CGSize {
        guard let cropSettings else {
            return pixelSize
        }
        return cropSettings.cropRect(in: pixelSize).size
    }

    var hasCrop: Bool {
        cropSettings != nil
    }
}
