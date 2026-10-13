import SwiftUI

struct ChatSourcesView: View {
    @ObservedObject var viewModel: ChatViewModel
    @ObservedObject private var knowledgeStore: KnowledgeStore
    @ObservedObject private var notesStore: NotesStore
    @Environment(\.dismiss) private var dismiss
    @State private var showFolderPicker = false
    @State private var folderDestination: ChatSourceDestination?

    init(viewModel: ChatViewModel) {
        self.viewModel = viewModel
        knowledgeStore = viewModel.knowledgeStore
        notesStore = viewModel.notesStore
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: EnsuSpacing.md) {
                    Text("Choose the sources Ensu can use for new replies in this chat.")
                        .font(EnsuTypography.body)
                        .foregroundStyle(EnsuColor.textPrimary)
                    Text(
                        "Earlier replies and citations stay in the conversation when a source is turned off. Choices are saved on this device."
                    )
                    .font(EnsuTypography.small)
                    .foregroundStyle(EnsuColor.textMuted)

                    if let error = viewModel.sourceSelectionError {
                        Text(error)
                            .font(EnsuTypography.small)
                            .foregroundStyle(EnsuColor.error)
                        CompactButton(text: "Try again") { viewModel.retryLoadingSources() }
                            .disabled(viewModel.isGenerating || viewModel.isSendPending)
                    } else if !viewModel.isSourceSelectionReady {
                        ProgressView("Loading sources…")
                    } else if !viewModel.canChangeSources {
                        Text("Sources can be changed after this response finishes.")
                            .font(EnsuTypography.small)
                            .foregroundStyle(EnsuColor.textMuted)
                    }

                    Text("Ensu Packs")
                        .font(EnsuTypography.large)
                        .padding(.top, EnsuSpacing.sm)
                    ForEach(knowledgeStore.packs) { pack in
                        KnowledgePackCard(
                            store: knowledgeStore, pack: pack,
                            selection: Binding(
                                get: { viewModel.sourceSelection.includesPack(pack.id) },
                                set: { viewModel.setPackEnabled(pack.id, enabled: $0) }),
                            controlsDisabled: !viewModel.canChangeSources,
                            onDownload: { viewModel.downloadPackForChat(pack.id) })
                    }
                    if knowledgeStore.packs.isEmpty {
                        Text("No packs are available.")
                            .font(EnsuTypography.small)
                            .foregroundStyle(EnsuColor.textMuted)
                    }

                    Text("Your Notes")
                        .font(EnsuTypography.large)
                        .padding(.top, EnsuSpacing.sm)
                    ForEach(notesStore.collections) { collection in
                        NoteCollectionCard(
                            store: notesStore, collection: collection,
                            selection: Binding(
                                get: {
                                    viewModel.sourceSelection.includesCollection(collection.id)
                                },
                                set: { viewModel.setNotesFolderEnabled(collection.id, enabled: $0) }
                            ),
                            controlsDisabled: !viewModel.canChangeSources)
                    }
                    if notesStore.collections.isEmpty {
                        Text("Add a folder to use your notes in this chat.")
                            .font(EnsuTypography.small)
                            .foregroundStyle(EnsuColor.textMuted)
                    }
                    CompactButton(text: "Add notes folder") {
                        folderDestination = viewModel.sourceDestination
                        showFolderPicker = true
                    }
                    .disabled(!viewModel.canChangeSources)
                    Text(
                        "Ensu reads and indexes markdown files in the selected folder. Source files are never modified."
                    )
                    .font(EnsuTypography.small)
                    .foregroundStyle(EnsuColor.textMuted)
                    if let error = notesStore.operationError {
                        Text(error)
                            .font(EnsuTypography.small)
                            .foregroundStyle(EnsuColor.error)
                    }
                }
                .padding(EnsuSpacing.lg)
            }
            .background(EnsuColor.backgroundBase)
            .navigationTitle("Sources")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .sheet(isPresented: $showFolderPicker) {
            NotesFolderPicker { url in
                if let destination = folderDestination {
                    viewModel.addNotesFolderForChat(url, destination: destination)
                }
            }
        }
    }
}
