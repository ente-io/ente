#if canImport(EnteCore)
import SwiftUI
import SwiftMath

struct LaTeXView: View {
    let latex: String

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let sanitizedLatex = latex.replacingOccurrences(of: "\\boxed", with: "")
        MathLabelView(
            latex: sanitizedLatex,
            rawLatex: latex,
            textColor: colorScheme == .dark
                ? PlatformColor(hex: "#E8E4DF")
                : PlatformColor(hex: "#1A1A1A")
        )
    }
}

#if os(iOS)
private struct MathLabelView: UIViewRepresentable {
    let latex: String
    let rawLatex: String
    let textColor: PlatformColor

    func makeUIView(context: Context) -> MathLabelContainerView {
        MathLabelContainerView()
    }

    func updateUIView(_ view: MathLabelContainerView, context: Context) {
        view.update(latex: latex, rawLatex: rawLatex, textColor: textColor)
    }
}

private final class MathLabelContainerView: UIView {
    private let mathLabel = MTMathUILabel()
    private let fallbackLabel = UILabel()
    private let insets = UIEdgeInsets(top: 4, left: 6, bottom: 4, right: 6)

    override init(frame: CGRect) {
        super.init(frame: frame)

        mathLabel.translatesAutoresizingMaskIntoConstraints = false
        fallbackLabel.translatesAutoresizingMaskIntoConstraints = false
        fallbackLabel.numberOfLines = 0

        addSubview(mathLabel)
        addSubview(fallbackLabel)

        NSLayoutConstraint.activate([
            mathLabel.topAnchor.constraint(equalTo: topAnchor, constant: insets.top),
            mathLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: insets.left),
            mathLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -insets.right),
            mathLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -insets.bottom),
            fallbackLabel.topAnchor.constraint(equalTo: topAnchor, constant: insets.top),
            fallbackLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: insets.left),
            fallbackLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -insets.right),
            fallbackLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -insets.bottom),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(latex: String, rawLatex: String, textColor: PlatformColor) {
        mathLabel.fontSize = 16
        mathLabel.textColor = textColor
        mathLabel.contentInsets = insets
        mathLabel.displayErrorInline = false
        mathLabel.latex = latex

        fallbackLabel.font = UIFont.systemFont(ofSize: 16)
        fallbackLabel.textColor = textColor
        fallbackLabel.text = rawLatex

        let trimmedLatex = latex.trimmingCharacters(in: .whitespacesAndNewlines)
        let shouldFallback = trimmedLatex.isEmpty || mathLabel.error != nil
        mathLabel.isHidden = shouldFallback
        fallbackLabel.isHidden = !shouldFallback
    }
}

#elseif os(macOS)
private struct MathLabelView: NSViewRepresentable {
    let latex: String
    let rawLatex: String
    let textColor: PlatformColor

    func makeNSView(context: Context) -> MathLabelContainerView {
        MathLabelContainerView()
    }

    func updateNSView(_ view: MathLabelContainerView, context: Context) {
        view.update(latex: latex, rawLatex: rawLatex, textColor: textColor)
    }
}

private final class MathLabelContainerView: NSView {
    private let mathLabel = MTMathUILabel()
    private let fallbackLabel = NSTextField(labelWithString: "")
    private let insets = NSEdgeInsets(top: 4, left: 6, bottom: 4, right: 6)

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        mathLabel.translatesAutoresizingMaskIntoConstraints = false
        fallbackLabel.translatesAutoresizingMaskIntoConstraints = false
        fallbackLabel.lineBreakMode = .byWordWrapping
        fallbackLabel.maximumNumberOfLines = 0

        addSubview(mathLabel)
        addSubview(fallbackLabel)

        NSLayoutConstraint.activate([
            mathLabel.topAnchor.constraint(equalTo: topAnchor, constant: insets.top),
            mathLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: insets.left),
            mathLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -insets.right),
            mathLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -insets.bottom),
            fallbackLabel.topAnchor.constraint(equalTo: topAnchor, constant: insets.top),
            fallbackLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: insets.left),
            fallbackLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -insets.right),
            fallbackLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -insets.bottom),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(latex: String, rawLatex: String, textColor: PlatformColor) {
        mathLabel.fontSize = 16
        mathLabel.textColor = textColor
        mathLabel.contentInsets = insets
        mathLabel.displayErrorInline = false
        mathLabel.latex = latex

        fallbackLabel.font = NSFont.systemFont(ofSize: 16)
        fallbackLabel.textColor = textColor
        fallbackLabel.stringValue = rawLatex

        let trimmedLatex = latex.trimmingCharacters(in: .whitespacesAndNewlines)
        let shouldFallback = trimmedLatex.isEmpty || mathLabel.error != nil
        mathLabel.isHidden = shouldFallback
        fallbackLabel.isHidden = !shouldFallback
    }
}
#endif
#endif
