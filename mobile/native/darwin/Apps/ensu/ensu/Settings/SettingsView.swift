#if canImport(EnteCore)
import SwiftUI
import Foundation

struct SettingsView: View {
    let isLoggedIn: Bool
    let email: String?
    let showsSignInOption: Bool
    let onSignOut: () -> Void
    let onSignIn: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var query: String = ""
    @State private var showSignOutConfirm = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: EnsuSpacing.lg) {
                    if let email, isLoggedIn, trimmedQuery.isEmpty {
                        signedInCard(email: email)
                    }

                    if let aboutItem = filteredAboutItem {
                        Button(action: aboutItem.action) {
                            settingsCard(title: aboutItem.title, iconName: aboutItem.iconName, showsChevron: true)
                        }
                        .buttonStyle(.plain)
                    }

                    ForEach(filteredItems) { item in
                        NavigationLink {
                            item.destination
                        } label: {
                            settingsCard(title: item.title, iconName: item.iconName, showsChevron: true)
                        }
                        .buttonStyle(.plain)
                    }

                    ForEach(filteredAccountItems) { item in
                        Button(action: item.action) {
                            settingsCard(title: item.title, iconName: item.iconName, showsChevron: true)
                        }
                        .buttonStyle(.plain)
                    }

                    if shouldShowSignInRow {
                        Button(action: onSignIn) {
                            settingsCard(title: signInTitle, iconName: "Settings01Icon", showsChevron: true)
                        }
                        .buttonStyle(.plain)
                    }

                    ForEach(filteredLegalLinkItems) { item in
                        Button(action: item.action) {
                            settingsCard(title: item.title, iconName: item.iconName, showsChevron: true)
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
                    }
                }
                .padding(EnsuSpacing.lg)
            }
            .background(EnsuColor.backgroundBase)
            #if os(iOS)
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always))
            .navigationBarTitleDisplayMode(.inline)
            #else
            .searchable(text: $query)
            #endif
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Settings")
                        .font(EnsuTypography.large)
                        .foregroundStyle(EnsuColor.textPrimary)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Close") { dismiss() }
                }
            }
            .alert("Sign out of Ensu?", isPresented: $showSignOutConfirm) {
                Button("Sign Out", role: .destructive) {
                    onSignOut()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Signing out will remove your online chats from this device. Offline chats stay available.")
            }
        }
    }

    private var filteredItems: [SettingsItem] {
        guard !trimmedQuery.isEmpty else { return allItems }
        let q = trimmedQuery.lowercased()
        return allItems.filter { item in
            item.title.lowercased().contains(q)
        }
    }

    private var aboutItem: SettingsActionItem {
        SettingsActionItem(
            title: "About",
            iconName: "InformationCircleIcon",
            action: { openExternalLink("https://ente.io/blog/ensu/") }
        )
    }

    private var legalLinkItems: [SettingsActionItem] {
        [
            SettingsActionItem(
                title: "Privacy Policy",
                iconName: "ViewOffSlashIcon",
                action: { openExternalLink("https://ente.io/privacy") }
            ),
            SettingsActionItem(
                title: "Terms of Service",
                iconName: "Copy01Icon",
                action: { openExternalLink("https://ente.io/terms") }
            )
        ]
    }

    private var accountItems: [SettingsActionItem] {
        guard isLoggedIn else { return [] }
        return [
            SettingsActionItem(
                title: "Delete Account",
                iconName: "Delete01Icon",
                action: { openDeleteAccountEmail() }
            ),
            SettingsActionItem(
                title: "Sign Out",
                iconName: "Cancel01Icon",
                action: { showSignOutConfirm = true }
            )
        ]
    }

    private var filteredAccountItems: [SettingsActionItem] {
        guard !trimmedQuery.isEmpty else { return accountItems }
        let q = trimmedQuery.lowercased()
        return accountItems.filter { item in
            item.title.lowercased().contains(q)
        }
    }

    private var filteredAboutItem: SettingsActionItem? {
        guard !trimmedQuery.isEmpty else { return aboutItem }
        let q = trimmedQuery.lowercased()
        return aboutItem.title.lowercased().contains(q) ? aboutItem : nil
    }

    private var filteredLegalLinkItems: [SettingsActionItem] {
        guard !trimmedQuery.isEmpty else { return legalLinkItems }
        let q = trimmedQuery.lowercased()
        return legalLinkItems.filter { item in
            item.title.lowercased().contains(q)
        }
    }

    private var shouldShowSignInRow: Bool {
        guard showsSignInOption else { return false }
        guard !isLoggedIn else { return false }
        guard !trimmedQuery.isEmpty else { return true }
        let q = trimmedQuery.lowercased()
        return signInTitle.lowercased().contains(q)
    }

    private var signInTitle: String { "Sign In to Backup" }

    private var allItems: [SettingsItem] {
        [
            SettingsItem(
                title: "Logs",
                iconName: "Bug01Icon",
                destination: AnyView(LogsView(embeddedInNavigation: true))
            )
        ]
    }

    private var endpointInfoText: String? {
        guard trimmedQuery.isEmpty else { return nil }

        let defaultEndpoint = "https://api.ente.io"
        let endpoint = EnsuDeveloperSettings.currentEndpointString
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        guard !endpoint.isEmpty, endpoint != defaultEndpoint else { return nil }
        return "Endpoint: \(endpoint)"
    }

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func openDeleteAccountEmail() {
        let subject = "Request Deletion for Ente Account"
        let encoded = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? subject
        guard let url = URL(string: "mailto:support@ente.io?subject=\(encoded)") else { return }
        openURL(url)
    }

    private func openExternalLink(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        openURL(url)
    }

    private func signedInCard(email: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Signed in as")
                .font(EnsuTypography.small)
                .foregroundStyle(EnsuColor.textMuted)
            Text(email)
                .font(EnsuTypography.body)
                .foregroundStyle(EnsuColor.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(EnsuSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(EnsuColor.fillFaint)
        .clipShape(RoundedRectangle(cornerRadius: EnsuCornerRadius.card, style: .continuous))
    }

    private func settingsCard(title: String, iconName: String, showsChevron: Bool) -> some View {
        HStack(spacing: EnsuSpacing.md) {
            Image(iconName)
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .foregroundStyle(EnsuColor.textPrimary)

            Text(title)
                .font(EnsuTypography.body)
                .foregroundStyle(EnsuColor.textPrimary)
            Spacer()
            if showsChevron {
                Image("ArrowRight01Icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                    .foregroundStyle(EnsuColor.textMuted)
            }
        }
        .padding(EnsuSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(EnsuColor.fillFaint)
        .clipShape(RoundedRectangle(cornerRadius: EnsuCornerRadius.card, style: .continuous))
    }
}

private struct SettingsItem: Identifiable {
    let id = UUID()
    let title: String
    let iconName: String
    let destination: AnyView
}

private struct SettingsActionItem: Identifiable {
    let id = UUID()
    let title: String
    let iconName: String
    let action: () -> Void
}
#else
import SwiftUI

struct SettingsView: View {
    let isLoggedIn: Bool
    let email: String?
    let showsSignInOption: Bool
    let onSignOut: () -> Void
    let onSignIn: () -> Void

    var body: some View {
        Text("Settings unavailable")
    }
}
#endif
