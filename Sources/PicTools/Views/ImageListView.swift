import AppKit
import SwiftUI

struct ImageListView: View {
    var store: ImageStore
    @Binding var editingItem: ImageItem?

    var body: some View {
        VStack(spacing: 12) {
            Button {
                chooseImagesOrFolder()
            } label: {
                Label("Choose Images or Folder", systemImage: "photo.badge.plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            List(selection: Bindable(store).selectedItemID) {
                ForEach(store.items) { item in
                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.url.lastPathComponent)
                                .lineLimit(1)
                                .font(.body)
                            Text("\(Int(item.displayPixelSize.width)) x \(Int(item.displayPixelSize.height)) · \(formattedBytes(item.fileSize))")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                            Text(item.hasCrop ? "Crop set" : item.status.label)
                                .foregroundStyle(statusColor(item.status))
                                .font(.caption2)
                        }

                        Spacer(minLength: 6)

                        Button {
                            editingItem = item
                        } label: {
                            Image(systemName: "slider.horizontal.3")
                        }
                        .help("Edit crop")
                        .buttonStyle(.borderless)
                    }
                    .padding(.vertical, 4)
                    .tag(item.id)
                }
            }
            .listStyle(.sidebar)

            Text(store.lastMessage)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(3)
        }
        .padding(12)
    }

    private func chooseImagesOrFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.allowedContentTypes = [.image, .folder]

        if panel.runModal() == .OK {
            store.importURLs(panel.urls)
        }
    }

    private func formattedBytes(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    private func statusColor(_ status: ImageStatus) -> Color {
        switch status {
        case .ready: .secondary
        case .exporting: .blue
        case .exported: .green
        case .failed: .red
        }
    }
}
