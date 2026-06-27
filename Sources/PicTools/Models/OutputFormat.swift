import UniformTypeIdentifiers

enum OutputFormat: String, CaseIterable, Identifiable {
    case keepOriginal
    case jpeg
    case png
    case heic
    case webp

    var id: String { rawValue }

    var label: String {
        switch self {
        case .keepOriginal: "Keep Original"
        case .jpeg: "JPG"
        case .png: "PNG"
        case .heic: "HEIC"
        case .webp: "WebP"
        }
    }

    func resolvedType(sourceType: UTType) -> UTType {
        switch self {
        case .keepOriginal: sourceType
        case .jpeg: .jpeg
        case .png: .png
        case .heic: .heic
        case .webp: .webP
        }
    }
}

