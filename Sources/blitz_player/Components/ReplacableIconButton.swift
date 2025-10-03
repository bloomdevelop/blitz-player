import SwiftUI

struct ReplacableIconButtonStyle: ButtonStyle {
    let size: CGFloat

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(width: size, height: size)
            .background(.white.opacity(configuration.isPressed ? 0.2 : 0))
            .clipShape(.circle)
            .scaleEffect(configuration.isPressed ? 0.8 : 1)
            .animation(.spring(), value: configuration.isPressed)
    }
}

struct ReplacableIconButton: View {
    let prevIcon: String
    let nextIcon: String
    @Binding var isSwitched: Bool
    let action: () -> Void
    let size: CGFloat
    var color: Color

    private let duration: Double = 0.4
    private let extraBounce: Double = 0.15

    var body: some View {
        Button(action: {
            isSwitched.toggle()
            action()
        }) {
            ZStack {
                Image(systemName: prevIcon)
                    .font(.system(size: size * 0.672))
                    .foregroundColor(color)
                    .opacity(isSwitched ? 0 : 1)
                    .scaleEffect(isSwitched ? 0 : 1)
                    .animation(
                        .snappy(duration: duration, extraBounce: extraBounce), value: isSwitched)
                Image(systemName: nextIcon)
                    .font(.system(size: size * 0.672))
                    .foregroundColor(color)
                    .opacity(isSwitched ? 1 : 0)
                    .scaleEffect(isSwitched ? 1 : 0)
                    .animation(
                        .snappy(duration: duration, extraBounce: extraBounce), value: isSwitched)
            }
        }

        .buttonStyle(ReplacableIconButtonStyle(size: size))
    }
}
