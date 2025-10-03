import SwiftUI

struct CustomSlider: View {
    @Binding var value: CGFloat
    @GestureState private var isDragging: Bool = false
    @State private var scaleFactor: CGFloat = 1

    let currentTime: String
    let totalDuration: String

    // value is expected to be normalized between 0.0 and 1.0
    // The view renders a pill-shaped track with a lighter filled portion and no visible thumb.
    var body: some View {
        VStack (alignment: .center, spacing: 6 * scaleFactor) {
            GeometryReader { gr in
                let clampedValue = min(max(value, 0.0), 1.0)
                let fillWidth = gr.size.width * clampedValue
                let baseHeight = gr.size.height

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.16))

                    Capsule()
                        .fill(Color.white.opacity(isDragging ? 0.75 : 0.6))
                        .frame(height: baseHeight * scaleFactor, alignment: .center)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .mask(
                            HStack(spacing: 0) {
                                Rectangle()
                                    .frame(width: max(0, fillWidth))
                                Spacer(minLength: 0)
                            }
                        )
                }
                .frame(height: baseHeight * scaleFactor, alignment: .center)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .updating($isDragging) { _, state, _ in
                            state = true
                        }
                        .onChanged { gesture in
                            if scaleFactor == 1.0 {
                                withAnimation {
                                    scaleFactor = 2
                                }
                            }
                            let x = max(0, min(gesture.location.x, gr.size.width))
                            value = CGFloat(x / gr.size.width)
                        }
                        .onEnded { _ in
                            withAnimation {
                                scaleFactor = 1.0
                            }
                        }
                )
                .animation(.easeInOut(duration: 0.12), value: value)
                .accessibilityLabel("Progress")
                .accessibilityValue(Text(String(format: "%.0f%%", min(max(value, 0.0), 1.0) * 100)))
            }
            .frame(height: 6, alignment: .center)
            
            HStack {
                Text(currentTime)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                Spacer()
                Text(totalDuration)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
}
