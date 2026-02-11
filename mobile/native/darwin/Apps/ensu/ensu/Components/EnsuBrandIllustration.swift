import SwiftUI

struct EnsuBrandIllustration: View {
    var width: CGFloat = 92
    var height: CGFloat = 42
    var animated: Bool = true

    @State private var isAnimating = false

    var body: some View {
        let activePhase = animated ? isAnimating : true

        Image("EnsuLogoForeground")
            .resizable()
            .scaledToFit()
            .frame(width: width, height: height, alignment: .leading)
            .scaleEffect(activePhase ? 1 : 0.94)
            .opacity(activePhase ? 1 : 0.84)
            .animation(
                animated
                    ? .easeInOut(duration: 0.9).repeatForever(autoreverses: true)
                    : nil,
                value: isAnimating
            )
            .onAppear {
                guard animated else { return }
                isAnimating = true
            }
            .onDisappear {
                isAnimating = false
            }
            .accessibilityLabel("Ensu")
    }
}
