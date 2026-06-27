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
                onApply: { settings in
                    store.updateCrop(for: item.id, settings: settings)
                    editingItem = nil
                }
            )
        }
    }
}
