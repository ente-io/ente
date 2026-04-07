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
                : PlatformColor(hex: "#1A1A1A"),
            fontSize: 16,
            isInline: false
        )
    }
}

struct InlineLaTeXView: View {
    let latex: String
    let fontSize: CGFloat

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let sanitizedLatex = latex.replacingOccurrences(of: "\\boxed", with: "")
        MathLabelView(
            latex: sanitizedLatex,
            rawLatex: latex,
            textColor: colorScheme == .dark
                ? PlatformColor(hex: "#E8E4DF")
                : PlatformColor(hex: "#1A1A1A"),
            fontSize: fontSize,
            isInline: true
        )
    }
}

#if os(iOS)
private struct MathLabelView: UIViewRepresentable {
    let latex: String
    let rawLatex: String
    let textColor: PlatformColor
    let fontSize: CGFloat
    let isInline: Bool

    func makeUIView(context: Context) -> MathLabelContainerView {
        MathLabelContainerView()
    }

    func updateUIView(_ view: MathLabelContainerView, context: Context) {
        view.update(latex: latex, rawLatex: rawLatex, textColor: textColor, fontSize: fontSize, isInline: isInline)
    }
}

private final class MathLabelContainerView: UIView {
    private let mathLabel = MTMathUILabel()
    private let fallbackLabel = UILabel()
    private var currentInsets = UIEdgeInsets.zero

    override init(frame: CGRect) {
        super.init(frame: frame)
        fallbackLabel.numberOfLines = 0
        addSubview(mathLabel)
        addSubview(fallbackLabel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        if !mathLabel.isHidden {
            let childSize = mathLabel.intrinsicContentSize
            return CGSize(
                width: childSize.width + currentInsets.left + currentInsets.right,
                height: childSize.height + currentInsets.top + currentInsets.bottom
            )
        }
        let maxLabelWidth = fallbackLabel.preferredMaxLayoutWidth > 0
            ? fallbackLabel.preferredMaxLayoutWidth
            : CGFloat.greatestFiniteMagnitude
        let labelSize = fallbackLabel.sizeThatFits(CGSize(width: maxLabelWidth, height: .greatestFiniteMagnitude))
        return CGSize(
            width: labelSize.width + currentInsets.left + currentInsets.right,
            height: labelSize.height + currentInsets.top + currentInsets.bottom
        )
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let insetBounds = bounds.inset(by: currentInsets)
        mathLabel.frame = insetBounds
        fallbackLabel.frame = insetBounds
        let maxWidth = max(0, insetBounds.width)
        if fallbackLabel.preferredMaxLayoutWidth != maxWidth {
            fallbackLabel.preferredMaxLayoutWidth = maxWidth
            invalidateIntrinsicContentSize()
        }
    }

    func update(latex: String, rawLatex: String, textColor: PlatformColor, fontSize: CGFloat, isInline: Bool) {
        currentInsets = isInline
            ? UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1)
            : UIEdgeInsets(top: 4, left: 6, bottom: 4, right: 6)

        mathLabel.fontSize = fontSize
        mathLabel.textColor = textColor
        mathLabel.contentInsets = isInline ? .zero : currentInsets
        mathLabel.displayErrorInline = false
        mathLabel.latex = latex

        fallbackLabel.font = UIFont.systemFont(ofSize: fontSize)
        fallbackLabel.textColor = textColor
        fallbackLabel.text = rawLatex

        let trimmedLatex = latex.trimmingCharacters(in: .whitespacesAndNewlines)
        let shouldFallback = trimmedLatex.isEmpty || mathLabel.error != nil
        mathLabel.isHidden = shouldFallback
        fallbackLabel.isHidden = !shouldFallback

        invalidateIntrinsicContentSize()
    }
}

#elseif os(macOS)
private struct MathLabelView: NSViewRepresentable {
    let latex: String
    let rawLatex: String
    let textColor: PlatformColor
    let fontSize: CGFloat
    let isInline: Bool

    func makeNSView(context: Context) -> MathLabelContainerView {
        MathLabelContainerView()
    }

    func updateNSView(_ view: MathLabelContainerView, context: Context) {
        view.update(latex: latex, rawLatex: rawLatex, textColor: textColor, fontSize: fontSize, isInline: isInline)
    }
}

private final class MathLabelContainerView: NSView {
    private let mathLabel = MTMathUILabel()
    private let fallbackLabel = NSTextField(labelWithString: "")
    private var currentInsets = NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        fallbackLabel.lineBreakMode = .byWordWrapping
        fallbackLabel.maximumNumberOfLines = 0
        addSubview(mathLabel)
        addSubview(fallbackLabel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: NSSize {
        if !mathLabel.isHidden {
            let childSize = mathLabel.intrinsicContentSize
            return NSSize(
                width: childSize.width + currentInsets.left + currentInsets.right,
                height: childSize.height + currentInsets.top + currentInsets.bottom
            )
        }
        let maxWidth = fallbackLabel.preferredMaxLayoutWidth > 0
            ? fallbackLabel.preferredMaxLayoutWidth
            : CGFloat.greatestFiniteMagnitude
        let labelSize = fallbackLabel.sizeThatFits(NSSize(width: maxWidth, height: .greatestFiniteMagnitude))
        return NSSize(
            width: labelSize.width + currentInsets.left + currentInsets.right,
            height: labelSize.height + currentInsets.top + currentInsets.bottom
        )
    }

    override func layout() {
        super.layout()
        let insetRect = NSRect(
            x: currentInsets.left,
            y: currentInsets.bottom,
            width: max(0, bounds.width - currentInsets.left - currentInsets.right),
            height: max(0, bounds.height - currentInsets.top - currentInsets.bottom)
        )
        mathLabel.frame = insetRect
        fallbackLabel.frame = insetRect
        let maxWidth = max(0, insetRect.width)
        if fallbackLabel.preferredMaxLayoutWidth != maxWidth {
            fallbackLabel.preferredMaxLayoutWidth = maxWidth
            invalidateIntrinsicContentSize()
        }
    }

    func update(latex: String, rawLatex: String, textColor: PlatformColor, fontSize: CGFloat, isInline: Bool) {
        currentInsets = isInline
            ? NSEdgeInsets(top: 1, left: 1, bottom: 1, right: 1)
            : NSEdgeInsets(top: 4, left: 6, bottom: 4, right: 6)

        let nsInsets = isInline ? NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 0) : currentInsets

        mathLabel.fontSize = fontSize
        mathLabel.textColor = textColor
        mathLabel.contentInsets = nsInsets
        mathLabel.displayErrorInline = false
        mathLabel.latex = latex

        fallbackLabel.font = NSFont.systemFont(ofSize: fontSize)
        fallbackLabel.textColor = textColor
        fallbackLabel.stringValue = rawLatex

        let trimmedLatex = latex.trimmingCharacters(in: .whitespacesAndNewlines)
        let shouldFallback = trimmedLatex.isEmpty || mathLabel.error != nil
        mathLabel.isHidden = shouldFallback
        fallbackLabel.isHidden = !shouldFallback

        invalidateIntrinsicContentSize()
    }
}
#endif
#endif
