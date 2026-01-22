import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    let onOpenModelSettings: () -> Void
    let onOpenLogs: () -> Void

    @State private var query: String = ""

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredItems) { item in
                    Button {
                        item.action()
                        dismiss()
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.title)
                                .font(EnsuTypography.body)
                                .foregroundStyle(EnsuColor.textPrimary)
                            if let subtitle = item.subtitle {
                                Text(subtitle)
                                    .font(EnsuTypography.small)
                                    .foregroundStyle(EnsuColor.textMuted)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                }

                if let endpointInfoText {
                    Text(endpointInfoText)
                        .font(EnsuTypography.small)
                        .foregroundStyle(EnsuColor.textMuted)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                        .listRowBackground(EnsuColor.backgroundBase)
                }
            }
            .scrollContentBackground(.hidden)
            .background(EnsuColor.backgroundBase)
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always))
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private var filteredItems: [SettingsItem] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return allItems }
        let q = trimmed.lowercased()
        return allItems.filter { item in
            item.title.lowercased().contains(q) || (item.subtitle?.lowercased().contains(q) == true)
        }
    }

    private var allItems: [SettingsItem] {
        [
            SettingsItem(
                title: "Model settings",
                subtitle: "Model URL, mmproj, context length",
                action: onOpenModelSettings
            ),
            SettingsItem(
                title: "Logs",
                subtitle: "View, export, and share logs",
                action: onOpenLogs
            )
        ]
    }

    private var endpointInfoText: String? {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedQuery.isEmpty else { return nil }

        let defaultEndpoint = "https://api.ente.io"
        let endpoint = EnsuDeveloperSettings.currentEndpointString
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        guard !endpoint.isEmpty, endpoint != defaultEndpoint else { return nil }
        return "Endpoint: \(endpoint)"
    }
}

private struct SettingsItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String?
    let action: () -> Void
}
