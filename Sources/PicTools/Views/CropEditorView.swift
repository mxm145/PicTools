import SwiftUI

struct CropEditorView: View {
    let item: ImageItem
    let onCancel: () -> Void
    let onApply: (CropSettings?) -> Void

    @State private var width: Double
    @State private var height: Double
    @State private var anchor: CropAnchor
    @State private var selectionInImage: CGRect?
    @State private var dragStart: CGPoint?
    @State private var dragRect: CGRect?

    init(item: ImageItem, onCancel: @escaping () -> Void, onApply: @escaping (CropSettings?) -> Void) {
        self.item = item
        self.onCancel = onCancel
        self.onApply = onApply
        _width = State(initialValue: Double(item.cropSettings?.width ?? item.pixelSize.width))
        _height = State(initialValue: Double(item.cropSettings?.height ?? item.pixelSize.height))
        _anchor = State(initialValue: item.cropSettings?.anchor ?? .center)
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
                Button("Clear Crop") {
                    selectionInImage = nil
                    dragRect = nil
                    width = Double(item.pixelSize.width)
                    height = Double(item.pixelSize.height)
                }

                Spacer()

                Button("Cancel") {
                    onCancel()
                }

                Button("Apply and Return") {
                    onApply(CropSettings(width: width, height: height, anchor: anchor, selection: selectionInImage))
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
                            width = selectionInImage.map { Double($0.width) } ?? width
                            height = selectionInImage.map { Double($0.height) } ?? height
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
                Text("Output Size")
                    .font(.subheadline)
                TextField("Width", value: numericWidthBinding, format: .number)
                TextField("Height", value: numericHeightBinding, format: .number)
            }

            Picker("Anchor", selection: numericAnchorBinding) {
                ForEach(CropAnchor.allCases) { anchor in
                    Text(anchor.label).tag(anchor)
                }
            }

            if selectionInImage != nil {
                Text("Mouse selection will be used.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("No mouse selection. Numeric size and anchor will be used.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    private var numericWidthBinding: Binding<Double> {
        Binding(
            get: { width },
            set: { newValue in
                width = newValue
                useNumericCrop()
            }
        )
    }

    private var numericHeightBinding: Binding<Double> {
        Binding(
            get: { height },
            set: { newValue in
                height = newValue
                useNumericCrop()
            }
        )
    }

    private var numericAnchorBinding: Binding<CropAnchor> {
        Binding(
            get: { anchor },
            set: { newValue in
                anchor = newValue
                useNumericCrop()
            }
        )
    }

    private func useNumericCrop() {
        selectionInImage = nil
        dragRect = nil
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
        let numeric = CropSettings(width: width, height: height, anchor: anchor, selection: nil)
            .cropRect(in: item.pixelSize)
        return overlayRect(fromImage: numeric, fitted: fitted)
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
