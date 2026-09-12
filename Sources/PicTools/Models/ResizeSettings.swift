import CoreGraphics

struct ResizeSettings: Equatable {
    var width: CGFloat
    var height: CGFloat
    var preservesAspectRatio: Bool

    func outputSize(sourceSize: CGSize) -> CGSize {
        let outputWidth = min(max(width, 1), 20_000)
        let outputHeight = min(max(height, 1), 20_000)
        return CGSize(width: outputWidth.rounded(), height: outputHeight.rounded())
    }
}
