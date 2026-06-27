import SwiftUI

struct DetailPreviewView: View {
    var store: ImageStore

    var body: some View {
        VStack(spacing: 16) {
            if let item = store.selectedItem {
                preview(for: item)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                HStack(spacing: 12) {
                    infoBox(title: "Original", value: ByteCountFormatter.string(fromByteCount: item.fileSize, countStyle: .file))
                    infoBox(title: "Size", value: "\(Int(item.pixelSize.width)) x \(Int(item.pixelSize.height))")
                    infoBox(title: "Status", value: item.status.label)
                }
            } else {
                ContentUnavailableView(
                    "No Image Selected",
                    systemImage: "photo",
                    description: Text("Choose images or a folder to start.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(18)
    }

    @ViewBuilder
    private func preview(for item: ImageItem) -> some View {
        if let image = ImageLoadingService.preview(url: item.url) {
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.quaternary.opacity(0.35))
                .clipShape(RoundedRectangle(cornerRadius: 6))
        } else {
            ContentUnavailableView("Preview Unavailable", systemImage: "exclamationmark.triangle")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func infoBox(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.callout)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
