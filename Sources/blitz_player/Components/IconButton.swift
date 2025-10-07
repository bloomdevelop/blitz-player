import SwiftUI

struct ScalingButtonStyle: ButtonStyle {
  let size: CGFloat?
  let color: Color

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .padding()
      .frame(width: size, height: size)
      .background(color.opacity(configuration.isPressed ? 0.2 : 0))
      .clipShape(.circle)
      .scaleEffect(configuration.isPressed ? 0.8 : 1)
      .animation(.spring(), value: configuration.isPressed)
  }
}

struct IconButton: View {
  let icon: String  // SF Symbol name
  let action: () -> Void
  let size: CGFloat
  let color: Color

  var body: some View {
    Button(action: action) {
      ZStack {
        Image(systemName: icon)
          .font(.system(size: size * 0.672))
          .foregroundColor(color)
      }
    }
    .buttonStyle(ScalingButtonStyle(size: size, color: color))
  }
}
