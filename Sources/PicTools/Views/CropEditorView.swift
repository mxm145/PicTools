import SwiftUI

struct CropEditorView: View {
    let item: ImageItem
    let onCancel: () -> Void
    let onApply: (CropSettings?, ResizeSettings?) -> Void

    @State private var outputWidth: Double
    @State private var outputHeight: Double
    @State private var preservesAspectRatio: Bool
    @State private var selectionInImage: CGRect?
    @State private var dragStart: CGPoint?
    @State private var dragRect: CGRect?

    init(item: ImageItem, onCancel: @escaping () -> Void, onApply: @escaping (CropSettings?, ResizeSettings?) -> Void) {
        self.item = item
        self.onCancel = onCancel
        self.onApply = onApply
        _outputWidth = State(initialValue: Double(item.resizeSettings?.width ?? item.displayPixelSize.width))
        _outputHeight = State(initialValue: Double(item.resizeSettings?.height ?? item.displayPixelSize.height))
        _preservesAspectRatio = State(initialValue: item.resizeSettings?.preservesAspectRatio ?? true)
        _selectionInImage = State(initialValue: item.cropSettings?.selection)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                cropCanvas
                    .frame(minWidth: 560, minHeight: 420)

                controls
                    .frame(width: 220)
            }
            .padding(18)

            Divider()

            HStack {
                Button("Reset Edits") {
                    selectionInImage = nil
                    dragRect = nil
                    outputWidth = Double(item.pixelSize.width)
                    outputHeight = Double(item.pixelSize.height)
                }

                Spacer()

                Button("Cancel") {
                    onCancel()
                }

                Button("Apply and Return") {
                    let cropSettings = selectionInImage.map {
                        CropSettings(width: $0.width, height: $0.height, anchor: .center, selection: $0)
                    }
                    let resizeSettings = resizeSettings(for: cropSettings)
                    onApply(cropSettings, resizeSettings)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(14)
        }
        .frame(minWidth: 840, minHeight: 560)
    }

    private var cropCanvas: some View {
        GeometryReader { proxy in
            let fitted = fittedImageRect(in: proxy.size)

            ZStack {
                Rectangle()
                    .fill(.quaternary.opacity(0.35))

                if let image = ImageLoadingService.preview(url: item.url) {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: fitted.width, height: fitted.height)
                        .position(x: fitted.midX, y: fitted.midY)
                }

                if let overlay = overlayRect(in: fitted) {
                    Rectangle()
                        .fill(.black.opacity(0.25))
                    Rectangle()
                        .path(in: overlay)
                        .fill(.clear)
                        .blendMode(.destinationOut)

                    Rectangle()
                        .stroke(Color.accentColor, lineWidth: 2)
                        .frame(width: overlay.width, height: overlay.height)
                        .position(x: overlay.midX, y: overlay.midY)
                }
            }
            .compositingGroup()
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .gesture(
                DragGesture(minimumDistance: 2)
                    .onChanged { value in
                        if dragStart == nil {
                            dragStart = value.startLocation
                        }
                        let rect = CGRect(
                            x: min(value.startLocation.x, value.location.x),
                            y: min(value.startLocation.y, value.location.y),
                            width: abs(value.location.x - value.startLocation.x),
                            height: abs(value.location.y - value.startLocation.y)
                        )
                        dragRect = rect.intersection(fitted)
                    }
                    .onEnded { _ in
                        if let dragRect, dragRect.width > 2, dragRect.height > 2 {
                            selectionInImage = imageRect(fromOverlay: dragRect, fitted: fitted)
                            outputWidth = selectionInImage.map { Double($0.width) } ?? outputWidth
                            outputHeight = selectionInImage.map { Double($0.height) } ?? outputHeight
                        }
                        dragStart = nil
                    }
            )
        }
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(item.url.lastPathComponent)
                .font(.headline)
                .lineLimit(2)

            VStack(alignment: .leading, spacing: 8) {
                Text("Resize Output")
                    .font(.subheadline)
                TextField("Width", value: outputWidthBinding, format: .number)
                TextField("Height", value: outputHeightBinding, format: .number)
                Toggle("Preserve aspect ratio", isOn: $preservesAspectRatio)
            }

            if selectionInImage != nil {
                Text("Mouse selection will crop first. Output size controls final resize.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("No crop selected. Output size will resize the whole image.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    private var outputWidthBinding: Binding<Double> {
        Binding(
            get: { outputWidth },
            set: { newValue in
                outputWidth = max(newValue, 1)
                if preservesAspectRatio {
                    outputHeight = outputWidth / currentAspectRatio
                }
            }
        )
    }

    private var outputHeightBinding: Binding<Double> {
        Binding(
            get: { outputHeight },
            set: { newValue in
                outputHeight = max(newValue, 1)
                if preservesAspectRatio {
                    outputWidth = outputHeight * currentAspectRatio
                }
            }
        )
    }

    private var currentAspectRatio: Double {
        let size = selectionInImage?.size ?? item.pixelSize
        guard size.height > 0 else {
            return 1
        }
        return Double(size.width / size.height)
    }

    private func resizeSettings(for cropSettings: CropSettings?) -> ResizeSettings? {
        let sourceSize = cropSettings?.cropRect(in: item.pixelSize).size ?? item.pixelSize
        let requestedSize = CGSize(width: outputWidth.rounded(), height: outputHeight.rounded())
        guard requestedSize != sourceSize else {
            return nil
        }
        return ResizeSettings(
            width: requestedSize.width,
            height: requestedSize.height,
            preservesAspectRatio: preservesAspectRatio
        )
    }

    private func fittedImageRect(in container: CGSize) -> CGRect {
        let imageSize = item.pixelSize
        guard imageSize.width > 0, imageSize.height > 0, container.width > 0, container.height > 0 else {
            return .zero
        }

        let scale = min(container.width / imageSize.width, container.height / imageSize.height)
        let size = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        return CGRect(
            x: (container.width - size.width) / 2,
            y: (container.height - size.height) / 2,
            width: size.width,
            height: size.height
        )
    }

    private func overlayRect(in fitted: CGRect) -> CGRect? {
        if let dragRect {
            return dragRect
        }
        if let selectionInImage {
            return overlayRect(fromImage: selectionInImage, fitted: fitted)
        }
        return fitted
    }

    private func overlayRect(fromImage rect: CGRect, fitted: CGRect) -> CGRect {
        let scaleX = fitted.width / item.pixelSize.width
        let scaleY = fitted.height / item.pixelSize.height
        return CGRect(
            x: fitted.minX + rect.minX * scaleX,
            y: fitted.minY + rect.minY * scaleY,
            width: rect.width * scaleX,
            height: rect.height * scaleY
        )
    }

    private func imageRect(fromOverlay rect: CGRect, fitted: CGRect) -> CGRect {
        let scaleX = item.pixelSize.width / fitted.width
        let scaleY = item.pixelSize.height / fitted.height
        let x = (rect.minX - fitted.minX) * scaleX
        let y = (rect.minY - fitted.minY) * scaleY
        return CGRect(x: x, y: y, width: rect.width * scaleX, height: rect.height * scaleY).integral
    }
}
