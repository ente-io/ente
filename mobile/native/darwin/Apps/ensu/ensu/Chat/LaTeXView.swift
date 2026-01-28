#if canImport(EnteCore)
import SwiftUI
import iosMath

struct LaTeXView: View {
    let latex: String

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        MathLabelView(
            latex: latex,
            textColor: colorScheme == .dark
                ? PlatformColor(hex: "#E8E4DF")
                : PlatformColor(hex: "#1A1A1A")
        )
    }
}

#if os(iOS)
private struct MathLabelView: UIViewRepresentable {
    let latex: String
    let textColor: PlatformColor

    func makeUIView(context: Context) -> MTMathUILabel {
        let label = MTMathUILabel()
        label.fontSize = 16
        label.textColor = textColor
        label.latex = latex
        return label
    }

    func updateUIView(_ label: MTMathUILabel, context: Context) {
        label.latex = latex
        label.textColor = textColor
    }
}
#elseif os(macOS)
private struct MathLabelView: NSViewRepresentable {
    let latex: String
    let textColor: PlatformColor

    func makeNSView(context: Context) -> MTMathUILabel {
        let label = MTMathUILabel()
        label.fontSize = 16
        label.textColor = textColor
        label.latex = latex
        return label
    }

    func updateNSView(_ label: MTMathUILabel, context: Context) {
        label.latex = latex
        label.textColor = textColor
    }
}
#endif
#endif
