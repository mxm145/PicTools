import Foundation
import Observation

@Observable
final class ImageStore {
    var items: [ImageItem] = []
    var selectedItemID: ImageItem.ID?
    var quality: Double = 0.8
    var outputFormat: OutputFormat = .keepOriginal
    var outputFolder: URL?
    var isExporting = false
    var lastMessage = "Choose images or a folder to begin."

    var selectedItem: ImageItem? {
        guard let selectedItemID else {
            return nil
        }
        return items.first { $0.id == selectedItemID }
    }

    func importURLs(_ urls: [URL]) {
        let imageURLs = expandedImageURLs(from: urls)
        var imported: [ImageItem] = []
        var skipped = 0

        for url in imageURLs {
            guard let loaded = ImageLoadingService.load(url: url) else {
                skipped += 1
                continue
            }
            imported.append(loaded.item)
        }

        items.append(contentsOf: imported)
        if selectedItemID == nil {
            selectedItemID = items.first?.id
        }

        if imported.isEmpty {
            lastMessage = skipped > 0 ? "No supported images found." : "Nothing was imported."
        } else if skipped > 0 {
            lastMessage = "Imported \(imported.count) image(s). Skipped \(skipped) unsupported file(s)."
        } else {
            lastMessage = "Imported \(imported.count) image(s)."
        }
    }

    func updateCrop(for id: ImageItem.ID, settings: CropSettings?) {
        guard let index = items.firstIndex(where: { $0.id == id }) else {
            return
        }
        items[index].cropSettings = settings
        items[index].status = .ready
    }

    func exportAll() {
        guard let outputFolder else {
            lastMessage = "Choose an output folder before exporting."
            return
        }

        guard !items.isEmpty else {
            lastMessage = "Choose at least one image before exporting."
            return
        }

        isExporting = true
        var successCount = 0
        var failureCount = 0

        for index in items.indices {
            items[index].status = .exporting
            do {
                let outputURL = try ImageExportService.export(
                    ImageExportRequest(
                        item: items[index],
                        outputFolder: outputFolder,
                        outputFormat: outputFormat,
                        quality: quality
                    )
                )
                items[index].status = .exported(outputURL)
                successCount += 1
            } catch {
                items[index].status = .failed(error.localizedDescription)
                failureCount += 1
            }
        }

        isExporting = false
        if failureCount == 0 {
            lastMessage = "Exported \(successCount) image(s)."
        } else {
            lastMessage = "Exported \(successCount) image(s). Failed \(failureCount)."
        }
    }

    private func expandedImageURLs(from urls: [URL]) -> [URL] {
        var result: [URL] = []
        for url in urls {
            if isDirectory(url) {
                result.append(contentsOf: imageFiles(in: url))
            } else {
                result.append(url)
            }
        }
        return result
    }

    private func imageFiles(in folder: URL) -> [URL] {
        guard let enumerator = FileManager.default.enumerator(
            at: folder,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        return enumerator.compactMap { entry -> URL? in
            guard let url = entry as? URL else {
                return nil
            }
            return isDirectory(url) ? nil : url
        }
    }

    private func isDirectory(_ url: URL) -> Bool {
        (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
    }
}
