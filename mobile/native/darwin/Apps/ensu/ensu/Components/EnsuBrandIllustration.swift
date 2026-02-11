import SwiftUI
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
