import AppKit
import SwiftUI

struct CompressionSettingsView: View {
    var store: ImageStore

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Compression")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Quality")
                    Spacer()
                    Text("\(Int(store.quality * 100))%")
                        .foregroundStyle(.secondary)
                }
                Slider(value: Bindable(store).quality, in: 0.1...1.0)
            }

            Picker("Output Format", selection: Bindable(store).outputFormat) {
                ForEach(OutputFormat.allCases) { format in
                    Text(format.label).tag(format)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Output Folder")
                    .font(.subheadline)
                Text(store.outputFolder?.path(percentEncoded: false) ?? "Not selected")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)

                Button {
                    chooseOutputFolder()
                } label: {
                    Label("Choose Folder", systemImage: "folder")
                        .frame(maxWidth: .infinity)
                }
            }

            Divider()

            Button {
                store.exportAll()
            } label: {
                Label("Compress and Export", systemImage: "square.and.arrow.down")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(store.isExporting || store.items.isEmpty)

            Spacer()

            Text("Original files are preserved. Processed copies are written to the selected output folder.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
    }

    private func chooseOutputFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true

        if panel.runModal() == .OK {
            store.outputFolder = panel.url
        }
    }
}

