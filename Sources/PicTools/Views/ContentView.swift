import SwiftUI

struct ContentView: View {
    @State private var store = ImageStore()
    @State private var editingItem: ImageItem?

    var body: some View {
        HStack(spacing: 0) {
            ImageListView(store: store, editingItem: $editingItem)
                .frame(width: 260)

            Divider()

            DetailPreviewView(store: store)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            CompressionSettingsView(store: store)
                .frame(width: 260)
        }
        .sheet(item: $editingItem) { item in
            CropEditorView(
                item: item,
                onCancel: {
                    editingItem = nil
                },
                onApply: { cropSettings, resizeSettings in
                    store.updateEdits(for: item.id, cropSettings: cropSettings, resizeSettings: resizeSettings)
                    editingItem = nil
                }
            )
        }
    }
}
