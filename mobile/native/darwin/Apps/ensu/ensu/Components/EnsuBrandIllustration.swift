import SwiftUI

#if canImport(RiveRuntime)
import RiveRuntime

struct EnsuBrandIllustration: View {
    var width: CGFloat = 92
    var height: CGFloat = 42
    var animated: Bool = true

    @StateObject private var riveViewModel = RiveViewModel(
        fileName: "ensu",
        fit: .contain,
        alignment: .centerLeft,
        autoPlay: true
    )

    var body: some View {
        riveViewModel
            .view()
            .frame(width: width, height: height, alignment: .leading)
            .clipped()
            .onAppear {
                if animated {
                    riveViewModel.play()
                } else {
                    riveViewModel.pause()
                }
            }
            .onChange(of: animated) { value in
                if value {
                    riveViewModel.play()
                } else {
                    riveViewModel.pause()
                }
            }
            .accessibilityLabel("Ensu")
    }
}

#else

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
                animated ? .easeInOut(duration: 0.9).repeatForever(autoreverses: true) : nil,
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

#endif
