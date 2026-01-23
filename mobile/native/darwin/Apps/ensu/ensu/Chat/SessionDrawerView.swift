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
    let onDeveloperTap: () -> Void

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
        VStack(alignment: .leading, spacing: EnsuSpacing.md) {
            HStack {
                if isLoggedIn {
                    EnsuLogo(height: 28)
                } else {
                    EnsuLogo(height: 28)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onDeveloperTap()
                        }
                }

                Spacer()
            }

            newChatTile(horizontalPadding: 0)
        }
        .padding(EnsuSpacing.lg)
        .background(
            LinearGradient(
                colors: [EnsuColor.accent.opacity(0.2), EnsuColor.backgroundBase],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private func newChatTile(horizontalPadding: CGFloat = EnsuSpacing.lg) -> some View {
        HStack(spacing: EnsuSpacing.sm) {
            drawerPrimaryTile(
                icon: "PlusSignIcon",
                title: "New Chat",
                action: onNewChat
            )

            if isLoggedIn {
                drawerPrimaryTile(
                    icon: "ArrowReloadHorizontalIcon",
                    title: "Sync",
                    action: onSync
                )
            }
        }
        // Make the tiles take equal width (50/50) and keep some space between.
        .padding(.horizontal, horizontalPadding)
    }

    private func sessionTile(_ session: ChatSession) -> some View {
        let title = ChatViewModel.sessionTitle(from: session.title, fallback: "New chat")

        return HStack(alignment: .center, spacing: EnsuSpacing.sm) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(session.id == currentSessionId ? EnsuFont.ui(size: 16, weight: .semibold) : EnsuTypography.small)
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

    private func drawerPrimaryTile(icon: String, title: String, action: @escaping () -> Void) -> some View {
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
            .frame(maxWidth: .infinity)
            .padding(.horizontal, EnsuSpacing.lg)
            .padding(.vertical, EnsuSpacing.md)
            .background(EnsuColor.fillFaint)
            .clipShape(RoundedRectangle(cornerRadius: EnsuCornerRadius.card, style: .continuous))
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    private var sectionedSessions: [SessionSection] {
        let grouped = Dictionary(grouping: sessions) { session in
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
