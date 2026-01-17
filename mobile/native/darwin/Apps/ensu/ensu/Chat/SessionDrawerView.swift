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
    let onShowLogs: () -> Void
    let onShowModelSettings: () -> Void
    let onDeveloperTap: () -> Void
    let onDeveloperSettings: () -> Void
    let onSignOut: () -> Void
    let onSignIn: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            drawerHeader

            ScrollView {
                VStack(alignment: .leading, spacing: EnsuSpacing.lg) {
                    newChatTile

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
                Text("ensu")
                    .font(EnsuTypography.h2)
                    .tracking(1)
                    .foregroundStyle(EnsuColor.textPrimary)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onDeveloperTap()
                    }
                Spacer()
            }

            HStack(spacing: EnsuSpacing.sm) {
                if isLoggedIn {
                    iconButton(symbol: "arrow.clockwise", action: onSync)
                }
                iconButton(symbol: "ladybug", action: onShowLogs)
                iconButton(symbol: "wrench.and.screwdriver", action: onDeveloperSettings)
                iconButton(symbol: "slider.horizontal.3", action: onShowModelSettings)
                Spacer()
            }

            if isLoggedIn, let email {
                HStack(spacing: EnsuSpacing.sm) {
                    Image(systemName: "cloud")
                    Text(email)
                        .font(EnsuTypography.small)
                        .foregroundStyle(EnsuColor.textMuted)
                        .lineLimit(1)
                }
                .padding(.horizontal, EnsuSpacing.md)
                .padding(.vertical, EnsuSpacing.sm)
                .background(EnsuColor.fillFaint)
                .clipShape(RoundedRectangle(cornerRadius: EnsuCornerRadius.card, style: .continuous))
            }
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

    private var newChatTile: some View {
        Button(action: onNewChat) {
            HStack(spacing: EnsuSpacing.sm) {
                Image(systemName: "plus")
                Text("New Chat")
                    .font(EnsuTypography.body)
            }
            .foregroundStyle(EnsuColor.textPrimary)
            .padding(.horizontal, EnsuSpacing.lg)
            .padding(.vertical, EnsuSpacing.sm)
        }
        .buttonStyle(.plain)
    }

    private func sessionTile(_ session: ChatSession) -> some View {
        Button {
            onSelectSession(session)
        } label: {
            HStack(alignment: .center, spacing: EnsuSpacing.sm) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.title)
                        .font(session.id == currentSessionId ? EnsuFont.ui(size: 16, weight: .semibold) : EnsuTypography.small)
                        .foregroundStyle(EnsuColor.textPrimary)
                    Text(session.lastMessage)
                        .font(EnsuTypography.mini)
                        .foregroundStyle(EnsuColor.textMuted)
                        .lineLimit(1)
                }
                Spacer()
                ActionButton(icon: "trash", color: EnsuColor.textMuted) {
                    onDeleteSession(session)
                }
            }
            .padding(.horizontal, EnsuSpacing.lg)
            .padding(.vertical, EnsuSpacing.sm)
        }
        .buttonStyle(.plain)
    }

    private var footer: some View {
        HStack {
            if isLoggedIn {
                Button("Sign Out", action: onSignOut)
                    .font(EnsuTypography.body)
                    .foregroundStyle(EnsuColor.textPrimary)
            } else {
                Button("Sign In to Backup", action: onSignIn)
                    .font(EnsuTypography.body)
                    .foregroundStyle(EnsuColor.textPrimary)
            }
            Spacer()
        }
        .padding(EnsuSpacing.lg)
    }

    private func iconButton(symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 18))
                .frame(width: 40, height: 40)
                .foregroundStyle(EnsuColor.textPrimary)
        }
        .buttonStyle(.plain)
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
