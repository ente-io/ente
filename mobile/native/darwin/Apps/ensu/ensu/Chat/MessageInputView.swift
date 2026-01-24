#if canImport(EnteCore)
import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct MessageInputView: View {
    @Binding var text: String
    @Binding var attachments: [ChatAttachment]
    let isGenerating: Bool
    let isDownloading: Bool
    let editingMessage: ChatMessage?
    let isProcessingAttachments: Bool
    let isAttachmentDownloadBlocked: Bool
    let onSend: () -> Void
    let onStop: () -> Void
    let onCancelEdit: () -> Void
    let onAddImage: (Data, String?) -> Void
    let onAddDocument: (URL) -> Void
    let onRemoveAttachment: (ChatAttachment) -> Void
    let onUserFocus: () -> Void
    let onDismissKeyboard: () -> Void

    @FocusState.Binding var isFocused: Bool

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var inputResetToken = UUID()

    private var placeholder: String {
        if isAttachmentDownloadBlocked {
            return "Downloading attachments..."
        }
        return "Write a message..."
    }

    private var canSend: Bool {
        let hasContent = !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !attachments.isEmpty
        return hasContent && !isGenerating && !isDownloading && !isAttachmentDownloadBlocked
    }

    private var isSendEnabled: Bool {
        let hasContent = !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !attachments.isEmpty
        return hasContent && !isDownloading && !isAttachmentDownloadBlocked
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(alignment: .leading, spacing: EnsuSpacing.sm) {
                if let editingMessage {
                    editBanner(for: editingMessage)
                }

                let inputVerticalPadding: CGFloat = 10
                let textFieldPadding: CGFloat = 6

                // Lift the bar slightly off the bottom edge.
                let bottomPadding: CGFloat = EnsuSpacing.md

                let inputStackSpacing: CGFloat = EnsuSpacing.sm

                VStack(alignment: .leading, spacing: inputStackSpacing) {
                    if !attachments.isEmpty {
                        let maxAttachmentHeight = CGFloat(3) * 40 + CGFloat(2) * EnsuSpacing.sm
                        let shouldScroll = attachments.count > 4

                        Group {
                            if shouldScroll {
                                ScrollView(.vertical, showsIndicators: false) {
                                    attachmentFlowLayout
                                }
                                .frame(maxHeight: maxAttachmentHeight)
                            } else {
                                attachmentFlowLayout
                            }
                        }
                        .padding(.horizontal, EnsuSpacing.pageHorizontal)
                    }

                if isProcessingAttachments {
                    HStack(spacing: EnsuSpacing.sm) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Reading attachment...")
                            .font(EnsuTypography.small)
                            .foregroundStyle(EnsuColor.textMuted)
                        Spacer()
                    }
                    .padding(.horizontal, EnsuSpacing.pageHorizontal)
                }

                HStack(alignment: .bottom, spacing: EnsuSpacing.sm) {
                    TextField(placeholder, text: $text, axis: .vertical)
                        .id(inputResetToken)
                        .focused($isFocused)
                        .onChange(of: isFocused) { focused in
                            if focused {
                                onUserFocus()
                            }
                        }
                        .lineLimit(1...5)
                        .font(EnsuTypography.message)
                        .foregroundStyle(EnsuColor.textPrimary)
                        .platformTextFieldStyle()
                        .platformTextInputAutocapitalization(.sentences)
                        .padding(.vertical, textFieldPadding)
                        .onSubmit {
                            if canSend {
                                onSend()
                                isFocused = false
                                hideKeyboard()
                                onDismissKeyboard()
                            }
                        }
                        .onChange(of: text) { newValue in
                            if newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isFocused {
                                inputResetToken = UUID()
                            }
                        }

                    if editingMessage == nil {
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            Image("Upload01Icon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: attachmentIconSize, height: attachmentIconSize)
                                .frame(width: 32, height: 32, alignment: .center)
                        }
                        .disabled(isGenerating || isDownloading || isAttachmentDownloadBlocked)
                        .foregroundStyle(EnsuColor.textMuted)
                        .simultaneousGesture(TapGesture().onEnded {
                            hapticTap()
                        })
                        #if os(macOS)
                        .buttonStyle(.plain)
                        .frame(width: 32, height: 32, alignment: .center)
                        #endif
                        .onChange(of: selectedPhotoItem) { newItem in
                            guard let newItem else { return }
                            Task {
                                let data = try? await newItem.loadTransferable(type: Data.self)
                                await MainActor.run {
                                    if let data {
                                        onAddImage(data, nil)
                                    }
                                    selectedPhotoItem = nil
                                }
                            }
                        }
                    }

                    Button {
                        if isGenerating {
                            hapticWarning()
                            onStop()
                        } else if isSendEnabled {
                            hapticMedium()
                            onSend()
                            isFocused = false
                            hideKeyboard()
                            onDismissKeyboard()
                        }
                    } label: {
                        if sendIcon == "StopIcon" {
                            ZStack {
                                Circle()
                                    .fill(EnsuColor.textPrimary)
                                    .frame(width: attachmentIconSize + 6, height: attachmentIconSize + 6)
                                Image(sendIcon)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: attachmentIconSize - 4, height: attachmentIconSize - 4)
                                    .foregroundStyle(EnsuColor.stopButton)
                            }
                            .frame(width: 32, height: 32)
                        } else {
                            Image(sendIcon)
                                .resizable()
                                .scaledToFit()
                                .frame(width: attachmentIconSize, height: attachmentIconSize)
                                .rotationEffect(sendIcon == "Navigation06Icon" ? .degrees(90) : .zero)
                                .foregroundStyle(sendColor)
                                .frame(width: 32, height: 32)
                        }
                    }
                    .disabled(isDownloading || (!canSend && !isGenerating))
                }
                .padding(.horizontal, EnsuSpacing.inputHorizontal)
                .padding(.vertical, inputVerticalPadding)
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: EnsuCornerRadius.input + 4, style: .continuous))
                .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 6)
                .padding(.horizontal, EnsuSpacing.pageHorizontal)
                .padding(.bottom, bottomPadding)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .preference(key: InputBarHeightKey.self, value: proxy.size.height)
                }
            )
        }
    }
    .padding(.top, EnsuSpacing.sm)
}

    private var attachmentIconSize: CGFloat {
        #if os(macOS)
        return 18
        #else
        return 16
        #endif
    }

    private var attachmentFlowLayout: some View {
        FlowLayout(spacing: EnsuSpacing.sm) {
            ForEach(attachments) { attachment in
                AttachmentChip(
                    name: attachment.name,
                    size: attachment.formattedSize,
                    icon: attachment.iconName,
                    isUploading: attachment.isUploading
                ) {
                    onRemoveAttachment(attachment)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var sendIcon: String {
        if isGenerating {
            return "StopIcon"
        }
        return "Navigation06Icon"
    }

    private var sendColor: Color {
        if isGenerating {
            return EnsuColor.stopButton
        }
        return isSendEnabled ? EnsuColor.textPrimary : EnsuColor.textMuted
    }

    private func editBanner(for message: ChatMessage) -> some View {
        HStack(spacing: EnsuSpacing.sm) {
            Image("Edit01Icon")
                .resizable()
                .scaledToFit()
                .frame(width: 14, height: 14)
                .foregroundStyle(EnsuColor.accent)

            Text("Editing:")
                .font(EnsuTypography.small)
                .foregroundStyle(EnsuColor.textMuted)

            Text(message.text)
                .font(EnsuTypography.small)
                .foregroundStyle(EnsuColor.textPrimary)
                .lineLimit(1)

            Spacer()

            Button(action: {
                hapticTap()
                onCancelEdit()
            }) {
                Image("Cancel01Icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 12, height: 12)
                    .foregroundStyle(EnsuColor.textMuted)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, EnsuSpacing.md)
        .padding(.vertical, EnsuSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: EnsuCornerRadius.input, style: .continuous)
                .fill(EnsuColor.fillFaint)
        )
        .overlay(
            Rectangle()
                .fill(EnsuColor.accent)
                .frame(width: 3),
            alignment: .leading
        )
        .padding(.horizontal, EnsuSpacing.pageHorizontal)
    }
}

struct InputBarHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
#else
import SwiftUI

struct MessageInputView: View {
    var body: some View {
        Text("Input unavailable")
    }
}
#endif

