import SwiftUI

struct MessageInputView: View {
    @Binding var text: String
    @Binding var attachments: [ChatAttachment]
    let isGenerating: Bool
    let isDownloading: Bool
    let editingMessage: ChatMessage?
    let isProcessingAttachments: Bool
    let onSend: () -> Void
    let onStop: () -> Void
    let onCancelEdit: () -> Void
    let onAddAttachment: (ChatAttachment.Kind) -> Void
    let onRemoveAttachment: (ChatAttachment) -> Void

    @StateObject private var keyboard = KeyboardObserver()
    @FocusState private var isFocused: Bool

    private var placeholder: String {
        isDownloading ? "Downloading model... (queue messages)" : "Compose your message..."
    }

    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isGenerating && !isDownloading
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: EnsuSpacing.sm) {
                if let editingMessage {
                    editBanner(for: editingMessage)
                }

                if !attachments.isEmpty {
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
                        .focused($isFocused)
                        .lineLimit(1...5)
                        .font(EnsuTypography.message)
                        .foregroundStyle(EnsuColor.textPrimary)
                        .platformTextFieldStyle()
                        .platformTextInputAutocapitalization(.sentences)
                        .padding(.vertical, 8)
                        .onSubmit {
                            if canSend {
                                onSend()
                            }
                        }

                    if editingMessage == nil {
                        Menu {
                            Button("Image") {
                                onAddAttachment(.image)
                            }
                            Button("Document") {
                                onAddAttachment(.document)
                            }
                        } label: {
                            Image(systemName: "paperclip")
                                .font(attachmentIconFont)
                                .frame(width: 32, height: 32, alignment: .center)
                        }
                        .disabled(isGenerating || isDownloading)
                        .foregroundStyle(EnsuColor.textMuted)
                        #if os(macOS)
                        .menuStyle(.borderlessButton)
                        .menuIndicator(.hidden)
                        .buttonStyle(.plain)
                        .frame(width: 32, height: 32, alignment: .center)
                        #endif
                    }

                    Button {
                        if isGenerating {
                            onStop()
                        } else if canSend {
                            onSend()
                        }
                    } label: {
                        Image(systemName: sendIcon)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(sendColor)
                            .frame(width: 32, height: 32)
                    }
                    .disabled(isDownloading || (!canSend && !isGenerating))
                }
                .padding(.horizontal, EnsuSpacing.inputHorizontal)
                .padding(.vertical, EnsuSpacing.inputVertical)
                .background(EnsuColor.fillFaint)
                .clipShape(RoundedRectangle(cornerRadius: EnsuCornerRadius.input, style: .continuous))
                .padding(.horizontal, EnsuSpacing.pageHorizontal)
                .padding(.bottom, EnsuSpacing.sm)
            }

            if keyboard.isVisible {
                Button {
                    isFocused = false
                    hideKeyboard()
                } label: {
                    Image(systemName: "keyboard.chevron.compact.down")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(width: 36, height: 36)
                        .background(EnsuColor.fillFaint)
                        .clipShape(Circle())
                }
                .padding(.trailing, EnsuSpacing.pageHorizontal)
                .padding(.bottom, 64)
            }
        }
        .padding(.top, EnsuSpacing.sm)
        .background(EnsuColor.backgroundBase)
    }

    private var attachmentIconFont: Font {
        #if os(macOS)
        return .system(size: 22, weight: .semibold)
        #else
        return .system(size: 18, weight: .regular)
        #endif
    }

    private var sendIcon: String {
        if isGenerating {
            return "stop.fill"
        }
        if isDownloading {
            return "arrow.down"
        }
        return "paperplane"
    }

    private var sendColor: Color {
        if isGenerating {
            return EnsuColor.stopButton
        }
        if isDownloading {
            return EnsuColor.textMuted
        }
        return EnsuColor.textMuted
    }

    private func editBanner(for message: ChatMessage) -> some View {
        HStack(spacing: EnsuSpacing.sm) {
            Image(systemName: "pencil")
                .font(.system(size: 14))
                .foregroundStyle(EnsuColor.accent)

            Text("Editing:")
                .font(EnsuTypography.small)
                .foregroundStyle(EnsuColor.textMuted)

            Text(message.text)
                .font(EnsuTypography.small)
                .foregroundStyle(EnsuColor.textPrimary)
                .lineLimit(1)

            Spacer()

            Button(action: onCancelEdit) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
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
