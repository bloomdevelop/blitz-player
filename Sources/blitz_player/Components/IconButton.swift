import SwiftUI

struct ScalingButtonStyle: ButtonStyle {
    let size: CGFloat?

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(width: size, height: size)
            .background(.white.opacity(configuration.isPressed ? 0.2 : 0))
            .clipShape(.circle)
    }
}

struct IconButton: View {
    let icon: String  // SF Symbol name
    let action: () -> Void
    let size: CGFloat
    let color: Color

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.672))
                .foregroundColor(color)
        }
        .buttonStyle(ScalingButtonStyle(size: size))
    }
}
