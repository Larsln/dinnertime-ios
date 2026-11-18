import UIKit

/// Prepares a picked photo for the upload as cover image.
enum CoverEncoder {
    private static let maximumLength: CGFloat = 2000
    private static let quality: CGFloat = 0.85

    /// Converts image data of any format the system reads into a JPEG whose longer side is at most 2000 points.
    ///
    /// Returns `nil` when the data is not an image.
    static func jpeg(from data: Data) -> Data? {
        guard let image = UIImage(data: data) else {
            return nil
        }
        let longest = max(image.size.width, image.size.height)
        guard longest > maximumLength else {
            return image.jpegData(compressionQuality: quality)
        }
        let factor = maximumLength / longest
        let size = CGSize(width: image.size.width * factor, height: image.size.height * factor)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let scaled = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        return scaled.jpegData(compressionQuality: quality)
    }
}
