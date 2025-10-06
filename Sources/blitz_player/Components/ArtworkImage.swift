import SwiftUI
import UIKit

/// A flexible artwork view that supports both `UIImage` and remote `URL` sources.
/// - You can create it from a `UIImage` or a `URL`.
/// - Configurable `size` and `cornerRadius`.
struct ArtworkImage: View {
  // MARK: - Sources
  private let uiImage: UIImage?
  private let url: URL?

  // MARK: - Appearance
  private let size: CGFloat
  private let cornerRadius: CGFloat
  private let contentMode: ContentMode

  // MARK: - Initters

  /// Initialize with a `UIImage`.
  init(
    _ image: UIImage?,
    size: CGFloat = 40,
    cornerRadius: CGFloat = 8,
    contentMode: ContentMode = .fill
  ) {
    self.uiImage = image
    self.url = nil
    self.size = size
    self.cornerRadius = cornerRadius
    self.contentMode = contentMode
  }

  /// Labeled initializer that accepts a `UIImage` via `artwork:` label.
  init(
    artwork: UIImage?,
    size: CGFloat = 40,
    cornerRadius: CGFloat = 8,
    contentMode: ContentMode = .fill
  ) {
    self.uiImage = artwork
    self.url = nil
    self.size = size
    self.cornerRadius = cornerRadius
    self.contentMode = contentMode
  }

  /// Initialize with a `URL`.
  init(
    url: URL?,
    size: CGFloat = 40,
    cornerRadius: CGFloat = 8,
    contentMode: ContentMode = .fill
  ) {
    self.uiImage = nil
    self.url = url
    self.size = size
    self.cornerRadius = cornerRadius
    self.contentMode = contentMode
  }

  /// Labeled initializer that accepts a `URL` via `artwork:` label.
  init(
    artwork: URL?,
    size: CGFloat = 40,
    cornerRadius: CGFloat = 8,
    contentMode: ContentMode = .fill
  ) {
    self.uiImage = nil
    self.url = artwork
    self.size = size
    self.cornerRadius = cornerRadius
    self.contentMode = contentMode
  }

  /// Initialize with an optional `URL` string.
  init(
    urlString: String?,
    size: CGFloat = 40,
    cornerRadius: CGFloat = 8,
    contentMode: ContentMode = .fill
  ) {
    self.uiImage = nil
    self.url = urlString.flatMap { URL(string: $0) }
    self.size = size
    self.cornerRadius = cornerRadius
    self.contentMode = contentMode
  }

  // MARK: - Body
  var body: some View {
    Group {
      if let uiImage = uiImage {
        Image(uiImage: uiImage)
          .resizable()
          .renderingMode(.original)
          .aspectRatio(contentMode: contentMode)
          .applyArtworkSizing(size: size, cornerRadius: cornerRadius)
      } else if let url = url {
        AsyncImage(url: url) { phase in
          switch phase {
          case .empty:
            loadingPlaceholder
          case .success(let image):
            image
              .resizable()
              .aspectRatio(contentMode: contentMode)
              .applyArtworkSizing(size: size, cornerRadius: cornerRadius)
          case .failure(_):
            errorPlaceholder
          @unknown default:
            loadingPlaceholder
          }
        }
        .frame(width: size, height: size)
      } else {
        placeholder
      }
    }
    .frame(width: size, height: size)
  }

  // MARK: - Placeholders
  private var loadingPlaceholder: some View {
    RoundedRectangle(cornerRadius: cornerRadius)
      .fill(Color.gray.opacity(0.2))
      .overlay(
        ProgressView()
          .scaleEffect(0.9)
          .progressViewStyle(CircularProgressViewStyle(tint: .secondary))
      )
      .applyArtworkSizing(size: size, cornerRadius: cornerRadius)
  }

  private var errorPlaceholder: some View {
    RoundedRectangle(cornerRadius: cornerRadius)
      .fill(Color.gray.opacity(0.25))
      .overlay(
        Image(systemName: "music.note")
          .font(.system(size: size * 0.4))
          .foregroundColor(.secondary)
      )
      .applyArtworkSizing(size: size, cornerRadius: cornerRadius)
  }

  private var placeholder: some View {
    RoundedRectangle(cornerRadius: cornerRadius)
      .fill(Color.gray.opacity(0.15))
      .overlay(
        Image(systemName: "music.note")
          .font(.system(size: size * 0.4))
          .foregroundColor(.gray)
      )
      .applyArtworkSizing(size: size, cornerRadius: cornerRadius)
  }
}

// MARK: - View modifiers
extension View {
  /// Common sizing & corner rounding for artwork.
  fileprivate func applyArtworkSizing(size: CGFloat, cornerRadius: CGFloat) -> some View {
    self
      .frame(width: size, height: size)
      .clipped()
      .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
  }
}

// MARK: - Previews
#if DEBUG
  import SwiftUI

  struct ArtworkImage_Previews: PreviewProvider {
    static var sampleImage: UIImage {
      // Create a simple colored image for preview purposes
      let renderer = UIGraphicsImageRenderer(size: CGSize(width: 200, height: 200))
      return renderer.image { ctx in
        UIColor.systemIndigo.setFill()
        ctx.fill(CGRect(x: 0, y: 0, width: 200, height: 200))
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let attrs: [NSAttributedString.Key: Any] = [
          .foregroundColor: UIColor.white,
          .font: UIFont.boldSystemFont(ofSize: 36),
          .paragraphStyle: paragraph,
        ]
        let text = "ART"
        text.draw(
          with: CGRect(x: 0, y: 70, width: 200, height: 60),
          options: .usesLineFragmentOrigin, attributes: attrs, context: nil)
      }
    }

    static var previews: some View {
      VStack(spacing: 16) {
        HStack {
          ArtworkImage(sampleImage, size: 72, cornerRadius: 12)
          ArtworkImage(
            url: URL(string: "https://example.com/does-not-exist.png"),
            size: 72, cornerRadius: 12)
          ArtworkImage(nil as UIImage?, size: 72, cornerRadius: 12)
        }
        HStack {
          ArtworkImage(sampleImage, size: 40, cornerRadius: 6)
          ArtworkImage(urlString: nil, size: 40, cornerRadius: 6)
          ArtworkImage(
            urlString: "https://example.com/does-not-exist.png",
            size: 40, cornerRadius: 6)
        }
      }
      .padding()
      .previewLayout(.sizeThatFits)
    }
  }
#endif
