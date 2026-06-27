import Foundation
import UniformTypeIdentifiers

enum FileNaming {
    static func uniqueOutputURL(
        sourceURL: URL,
        outputFolder: URL,
        outputType: UTType,
        fileManager: FileManager = .default
    ) -> URL {
        let baseName = sourceURL.deletingPathExtension().lastPathComponent
        let extensionName = outputType.picToolsPreferredExtension ?? sourceURL.pathExtension
        var candidate = outputFolder.appendingPathComponent(baseName).appendingPathExtension(extensionName)

        var index = 1
        while fileManager.fileExists(atPath: candidate.path) {
            candidate = outputFolder
                .appendingPathComponent("\(baseName)-\(index)")
                .appendingPathExtension(extensionName)
            index += 1
        }

        return candidate
    }
}

extension UTType {
    var picToolsPreferredExtension: String? {
        if conforms(to: .jpeg) {
            return "jpg"
        }

        return preferredFilenameExtension
    }
}
