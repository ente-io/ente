import SwiftUI

struct KnowledgeSettingsView: View {
    @ObservedObject var store: KnowledgeStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: EnsuSpacing.md) {
                ForEach(store.packs) { pack in
                    KnowledgePackCard(store: store, pack: pack)
                }
                Text("Choose sources for each chat using Sources in the message composer.")
                    .font(EnsuTypography.small)
                    .foregroundStyle(EnsuColor.textMuted)
            }
            .padding(EnsuSpacing.lg)
        }
        .background(EnsuColor.backgroundBase)
        .navigationTitle("Ensu Packs")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct KnowledgePackCard: View {
    @ObservedObject var store: KnowledgeStore
    let pack: KnowledgePackState
    var selection: Binding<Bool>? = nil
    var controlsDisabled = false
    var onDownload: (() -> Void)? = nil
    @State private var showAttribution = false

    var body: some View {
        let attribution = pack.config.attribution
        EnsuCard {
            HStack {
                VStack(alignment: .leading, spacing: EnsuSpacing.xs) {
                    Text(pack.config.label)
                        .font(EnsuTypography.large)
                        .foregroundStyle(EnsuColor.textPrimary)
                    HStack(spacing: EnsuSpacing.xs) {
                        Text(pack.config.downloadSizeBytes.formattedFileSize)
                            .font(EnsuTypography.mini)
                            .foregroundStyle(EnsuColor.textMuted)
                        Text("·")
                            .font(EnsuTypography.mini)
                            .foregroundStyle(EnsuColor.textMuted)
                        Button {
                            showAttribution = true
                        } label: {
                            HStack(spacing: EnsuSpacing.xs) {
                                Text(attribution.licenseLabel)
                                    .font(EnsuTypography.mini)
                                Image(systemName: "info.circle")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundStyle(EnsuColor.accent)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("View attribution for \(pack.config.label)")
                    }
                }
                Spacer()
                if pack.activeIdentity != nil, let selection {
                    Toggle("Use \(pack.config.label) in this chat", isOn: selection)
                        .labelsHidden()
                        .tint(EnsuColor.accent)
                        .disabled(controlsDisabled || pack.isMutating)
                } else if store.downloadsAllowed && pack.status == .download && !pack.isMutating {
                    CompactButton(text: "Download") {
                        download()
                    }
                    .disabled(controlsDisabled)
                }

            }

            if pack.isMutating {
                HStack(spacing: EnsuSpacing.sm) {
                    ProgressView(value: Double(pack.progressPercent ?? 0), total: 100)
                        .tint(EnsuColor.action)
                    Button {
                        store.cancel(stableId: pack.id)
                    } label: {
                        Image("Cancel01Icon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 12, height: 12)
                            .foregroundStyle(EnsuColor.textMuted)
                    }
                    .buttonStyle(.plain)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
                    .accessibilityLabel("Cancel download")
                }
            } else if store.downloadsAllowed && pack.status == .updateAvailable {
                CompactButton(text: "Update") { download() }
                    .disabled(controlsDisabled)
            } else if pack.activeIdentity != nil && selection == nil {
                Text("Downloaded")
                    .font(EnsuTypography.small)
                    .foregroundStyle(EnsuColor.textMuted)
            }

            if pack.isMutating, let progress = pack.progressLabel {
                Text(progress)
                    .font(EnsuTypography.small)
                    .foregroundStyle(EnsuColor.textMuted)
            }

            if let error = pack.errorMessage {
                Text(error)
                    .font(EnsuTypography.small)
                    .foregroundStyle(EnsuColor.error)
            }
        }
        .sheet(isPresented: $showAttribution) {
            PackAttributionSheet(config: pack.config)
        }
    }

    private func download() {
        if let onDownload { onDownload() } else { store.downloadOrUpdate(stableId: pack.id) }
    }
}

private struct PackAttributionSheet: View {
    let config: KnowledgeDatasetConfig

    var body: some View {
        let attribution = config.attribution
        AttributionSheet(title: "Attribution") {
            EnsuCard(padding: EnsuSpacing.md) {
                Text(config.label)
                    .font(EnsuTypography.large)
                    .foregroundStyle(EnsuColor.textPrimary)

                Divider()

                Text("From \(attribution.credit)")
                    .font(EnsuTypography.body)
                    .foregroundStyle(EnsuColor.textPrimary)

                Text(attribution.modificationNotice)
                    .font(EnsuTypography.body)
                    .foregroundStyle(EnsuColor.textPrimary)

                HStack(spacing: EnsuSpacing.md) {
                    if let sourceUrl = URL(string: attribution.publicPackUrl) {
                        Link(destination: sourceUrl) {
                            Label("Source", systemImage: "arrow.up.right.square")
                                .frame(minHeight: 44)
                        }
                    }
                    if let licenseUrl = URL(string: attribution.licenseUrl) {
                        Link(destination: licenseUrl) {
                            Label("License", systemImage: "doc.text")
                                .frame(minHeight: 44)
                        }
                    }
                }
                .font(EnsuTypography.mini)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider()

                Text(
                    "Wikimedia and Ensu are not affiliated. Wikimedia project names identify the source material only."
                )
                .font(EnsuTypography.small)
                .foregroundStyle(EnsuColor.textMuted)
            }
        }
    }
}
