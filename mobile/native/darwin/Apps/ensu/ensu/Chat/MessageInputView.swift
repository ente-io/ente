import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import UIKit

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
    let onAddImage: (Data, String?) -> Void
    let onAddDocument: (URL) -> Void
    let onRemoveAttachment: (ChatAttachment) -> Void

    @StateObject private var keyboard = KeyboardObserver()
    @FocusState private var isFocused: Bool
    @State private var isImagePickerPresented = false
    @State private var isDocumentPickerPresented = false

    private var placeholder: String {
        isDownloading ? "Downloading model... (queue messages)" : "Compose your message..."
    }

    private var canSend: Bool {
        let hasContent = !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !attachments.isEmpty
        return hasContent && !isGenerating && !isDownloading
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(alignment: .leading, spacing: EnsuSpacing.sm) {
                if let editingMessage {
                    editBanner(for: editingMessage)
                }

                let hasAttachmentContent = !attachments.isEmpty || isProcessingAttachments
                let inputVerticalPadding: CGFloat = hasAttachmentContent ? EnsuSpacing.xs : EnsuSpacing.inputVertical
                let textFieldPadding: CGFloat = hasAttachmentContent ? 2 : 8
                let bottomPadding: CGFloat = hasAttachmentContent ? EnsuSpacing.xs : EnsuSpacing.sm
                let inputStackSpacing: CGFloat = hasAttachmentContent ? EnsuSpacing.xs : EnsuSpacing.sm

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
                        .focused($isFocused)
                        .lineLimit(1...5)
                        .font(EnsuTypography.message)
                        .foregroundStyle(EnsuColor.textPrimary)
                        .platformTextFieldStyle()
                        .platformTextInputAutocapitalization(.sentences)
                        .padding(.vertical, textFieldPadding)
                        .onSubmit {
                            if canSend {
                                onSend()
                            }
                        }

                    if editingMessage == nil {
                        Menu {
                            Button("Image") {
                                isImagePickerPresented = true
                            }
                            Button("Document") {
                                isDocumentPickerPresented = true
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
                        .sheet(isPresented: $isImagePickerPresented) {
                            ImagePicker(
                                onPick: { data, name in
                                    onAddImage(data, name)
                                    isImagePickerPresented = false
                                },
                                onCancel: {
                                    isImagePickerPresented = false
                                }
                            )
                        }
                        .sheet(isPresented: $isDocumentPickerPresented) {
                            DocumentPicker(
                                onPick: { url in
                                    onAddDocument(url)
                                    isDocumentPickerPresented = false
                                },
                                onCancel: {
                                    isDocumentPickerPresented = false
                                }
                            )
                        }
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
                .padding(.vertical, inputVerticalPadding)
                .frame(maxWidth: .infinity)
                .background(EnsuColor.fillFaint)
                .clipShape(RoundedRectangle(cornerRadius: EnsuCornerRadius.input, style: .continuous))
                .padding(.horizontal, EnsuSpacing.pageHorizontal)
                .padding(.bottom, bottomPadding)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
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

private struct ImagePicker: UIViewControllerRepresentable {
    let onPick: (Data, String?) -> Void
    let onCancel: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick, onCancel: onCancel)
    }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        private let onPick: (Data, String?) -> Void
        private let onCancel: () -> Void

        init(onPick: @escaping (Data, String?) -> Void, onCancel: @escaping () -> Void) {
            self.onPick = onPick
            self.onCancel = onCancel
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let result = results.first else {
                onCancel()
                return
            }
            let provider = result.itemProvider
            let typeIdentifier = UTType.image.identifier
            provider.loadDataRepresentation(forTypeIdentifier: typeIdentifier) { data, _ in
                DispatchQueue.main.async {
                    guard let data else {
                        self.onCancel()
                        return
                    }
                    self.onPick(data, provider.suggestedName)
                }
            }
        }
    }
}

private struct DocumentPicker: UIViewControllerRepresentable {
    let onPick: (URL) -> Void
    let onCancel: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick, onCancel: onCancel)
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.data], asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        private let onPick: (URL) -> Void
        private let onCancel: () -> Void

        init(onPick: @escaping (URL) -> Void, onCancel: @escaping () -> Void) {
            self.onPick = onPick
            self.onCancel = onCancel
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else {
                onCancel()
                return
            }
            onPick(url)
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            onCancel()
        }
    }
}
