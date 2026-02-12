#if canImport(EnteCore)
import SwiftUI

struct SessionDrawerView: View {
    let sessions: [ChatSession]
    let currentSessionId: UUID?
    let isLoggedIn: Bool
    let email: String?
    let onNewChat: () -> Void
    let onSelectSession: (ChatSession) -> Void
    let onDeleteSession: (ChatSession) -> Void
    let onSync: () -> Void
    let onOpenSettings: () -> Void

    @State private var searchQuery: String = ""

    var body: some View {
        VStack(spacing: 0) {
            drawerHeader

            ScrollView {
                VStack(alignment: .leading, spacing: EnsuSpacing.lg) {
                    ForEach(sectionedSessions) { section in
                        VStack(alignment: .leading, spacing: EnsuSpacing.sm) {
                            Text(section.title)
                                .font(EnsuTypography.tiny)
                                .foregroundStyle(EnsuColor.textMuted)
                                .tracking(1)
                                .padding(.horizontal, EnsuSpacing.lg)

                            ForEach(section.sessions) { session in
                                sessionTile(session)
                            }
                        }
                    }
                }
                .padding(.vertical, EnsuSpacing.lg)
            }

            Divider()
                .background(EnsuColor.border)

            footer
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(EnsuColor.backgroundBase)
    }

    private var drawerHeader: some View {
        VStack(alignment: .leading, spacing: 0) {
            if isLoggedIn {
                HStack {
                    Spacer()

                    drawerPrimaryTile(
                        icon: "ArrowReloadHorizontalIcon",
                        title: "Sync",
                        action: onSync,
                        expands: false
                    )
                }
                .padding(.bottom, EnsuSpacing.md)
            }

            headerControls
        }
        .padding(EnsuSpacing.lg)
        .background(EnsuColor.backgroundBase)
    }

    private var headerControls: some View {
        HStack(alignment: .center, spacing: EnsuSpacing.sm) {
            searchField
                .frame(maxWidth: .infinity, alignment: .leading)

            newChatButton
        }
    }

    private var searchField: some View {
        HStack(spacing: EnsuSpacing.sm) {
            Image("Search01Icon")
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .foregroundStyle(EnsuColor.textMuted)

            TextField("Search chats", text: $searchQuery)
                .font(EnsuTypography.body)
                .platformTextInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .platformTextFieldStyle()
                .foregroundStyle(EnsuColor.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, EnsuSpacing.inputHorizontal)
        .padding(.vertical, EnsuSpacing.inputVertical)
        .background(EnsuColor.fillFaint)
        .clipShape(RoundedRectangle(cornerRadius: EnsuCornerRadius.card, style: .continuous))
    }

    private var hasSearchQuery: Bool {
        !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var newChatButton: some View {
        Button(action: {
            hapticTap()
            if hasSearchQuery {
                searchQuery = ""
            } else {
                onNewChat()
            }
        }) {
            Image(hasSearchQuery ? "Cancel01Icon" : "PlusSignIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .foregroundStyle(EnsuColor.textPrimary)
                .frame(width: 36, height: 36)
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
    }

    private func sessionTile(_ session: ChatSession) -> some View {
        let title = ChatViewModel.sessionTitle(from: session.title, fallback: "New chat")

        return HStack(alignment: .center, spacing: EnsuSpacing.sm) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(EnsuTypography.small)
                    .foregroundStyle(EnsuColor.textPrimary)
                Text(session.lastMessage.isEmpty ? "Nothing here" : session.lastMessage)
                    .font(EnsuTypography.mini)
                    .foregroundStyle(EnsuColor.textMuted)
                    .lineLimit(1)
            }
            Spacer()
            ActionButton(icon: "Delete01Icon", color: EnsuColor.textMuted) {
                onDeleteSession(session)
            }
        }
        .padding(.horizontal, EnsuSpacing.lg)
        .padding(.vertical, EnsuSpacing.sm)
        .contentShape(Rectangle())
        .onTapGesture {
            hapticTap()
            onSelectSession(session)
        }
    }

    private var footer: some View {
        HStack {
            if isLoggedIn {
                Button {
                    hapticTap()
                    onOpenSettings()
                } label: {
                    HStack(spacing: EnsuSpacing.md) {
                        Text(email ?? "")
                            .font(EnsuTypography.body)
                            .foregroundStyle(EnsuColor.textPrimary)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Image("ArrowRight01Icon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                            .foregroundStyle(EnsuColor.textMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    hapticTap()
                    onOpenSettings()
                } label: {
                    HStack(spacing: EnsuSpacing.md) {
                        Text("Settings")
                            .font(EnsuTypography.body)
                            .foregroundStyle(EnsuColor.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Image("ArrowRight01Icon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                            .foregroundStyle(EnsuColor.textMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 0)
        }
        .padding(EnsuSpacing.lg)
    }

    private func drawerPrimaryTile(icon: String, title: String, action: @escaping () -> Void, expands: Bool = true) -> some View {
        Button(action: {
            hapticTap()
            action()
        }) {
            HStack(spacing: EnsuSpacing.sm) {
                Image(icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)

                Text(title)
                    .font(EnsuTypography.body)
            }
            .foregroundStyle(EnsuColor.textPrimary)
            .frame(maxWidth: expands ? .infinity : nil)
            .padding(.horizontal, EnsuSpacing.lg)
            .padding(.vertical, EnsuSpacing.md)
            .background(EnsuColor.fillFaint)
            .clipShape(RoundedRectangle(cornerRadius: EnsuCornerRadius.card, style: .continuous))
        }
        .buttonStyle(.plain)
        .frame(maxWidth: expands ? .infinity : nil)
    }

    private var filteredSessions: [ChatSession] {
        let trimmed = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return sessions }
        let lower = trimmed.lowercased()
        return sessions.filter { session in
            let title = ChatViewModel.sessionTitle(from: session.title, fallback: "New chat")
            return title.lowercased().contains(lower)
                || session.lastMessage.lowercased().contains(lower)
        }
    }

    private var sectionedSessions: [SessionSection] {
        let grouped = Dictionary(grouping: filteredSessions) { session in
            sectionTitle(for: session.updatedAt)
        }

        let order = ["TODAY", "YESTERDAY", "THIS WEEK", "LAST WEEK", "THIS MONTH", "OLDER"]
        return order.compactMap { title in
            guard let items = grouped[title], !items.isEmpty else { return nil }
            return SessionSection(title: title, sessions: items.sorted { $0.updatedAt > $1.updatedAt })
        }
    }

    private func sectionTitle(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "TODAY" }
        if calendar.isDateInYesterday(date) { return "YESTERDAY" }
        if calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) { return "THIS WEEK" }

        let lastWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: Date()) ?? Date()
        if calendar.isDate(date, equalTo: lastWeek, toGranularity: .weekOfYear) { return "LAST WEEK" }
        if calendar.isDate(date, equalTo: Date(), toGranularity: .month) { return "THIS MONTH" }
        return "OLDER"
    }
}

private struct SessionSection: Identifiable {
    let id = UUID()
    let title: String
    let sessions: [ChatSession]
}

#else
import SwiftUI

struct SessionDrawerView: View {
    var body: some View {
        Text("Sessions unavailable")
    }
}
#endif
