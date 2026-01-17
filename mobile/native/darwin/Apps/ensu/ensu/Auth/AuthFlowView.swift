import SwiftUI

enum AuthRoute: Hashable {
    case otp(email: String, srp: SrpAttributes)
    case password(email: String, srp: SrpAttributes)

    case twoFactor(email: String, srp: SrpAttributes, sessionId: String, password: String?)
    case passkey(email: String, srp: SrpAttributes, sessionId: String, accountsUrl: String, twoFactorSessionId: String?, password: String?)

    case passwordAfterMfa(email: String, srp: SrpAttributes, userId: Int64, keyAttributes: KeyAttributes, encryptedToken: String?, token: String?)
    case passkeyPasswordReentry(email: String, srp: SrpAttributes, auth: AuthResponsePayload)
}

struct AuthFlowView: View {
    @EnvironmentObject private var appState: EnsuAppState
    @Environment(\.dismiss) private var dismiss

    @State private var path: [AuthRoute] = []

    private var backButtonInset: CGFloat {
        EnsuSpacing.md
    }

    private var leadingPlacement: ToolbarItemPlacement {
        #if os(iOS)
        .navigationBarLeading
        #else
        .navigation
        #endif
    }

    private var trailingPlacement: ToolbarItemPlacement {
        #if os(iOS)
        .navigationBarTrailing
        #else
        .primaryAction
        #endif
    }

    var body: some View {
        Group {
            #if os(iOS)
            NavigationStack(path: $path) {
                rootView
            }
            #else
            macContent
            #endif
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(EnsuColor.backgroundBase.ignoresSafeArea())
        #if os(macOS)
        .safeAreaInset(edge: .top) {
            MacSheetHeader(
                leading: {
                    if !path.isEmpty {
                        Button {
                            path.removeLast()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Back")
                            }
                            .font(EnsuTypography.small)
                            .foregroundStyle(EnsuColor.textMuted)
                        }
                        .buttonStyle(.plain)
                    }
                },
                center: {
                    Text("ensu")
                        .font(EnsuTypography.h3)
                        .foregroundStyle(EnsuColor.textPrimary)
                },
                trailing: {
                    Button("Close") {
                        dismiss()
                    }
                    .font(EnsuTypography.small)
                    .foregroundStyle(EnsuColor.textMuted)
                    .buttonStyle(.plain)
                }
            )
        }
        #endif
    }

    @ViewBuilder
    private var rootView: some View {
        EmailEntryView { route in
            path.append(route)
        }
        .navigationDestination(for: AuthRoute.self) { route in
            destinationView(for: route)
        }
        .navigationTitle("")
        .platformNavigationBarStyle()
        #if os(iOS)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("ensu")
                    .font(EnsuTypography.h3)
                    .foregroundStyle(EnsuColor.textPrimary)
            }

            ToolbarItem(placement: trailingPlacement) {
                Button("Close") {
                    dismiss()
                }
                .font(EnsuTypography.small)
                .foregroundStyle(EnsuColor.textMuted)
            }
        }
        #endif
    }

    @ViewBuilder
    private var macContent: some View {
        if let route = path.last {
            destinationView(for: route)
        } else {
            EmailEntryView { route in
                path.append(route)
            }
        }
    }

    @ViewBuilder
    private func destinationView(for route: AuthRoute) -> some View {
        switch route {
        case let .otp(email, srp):
            authDestination {
                OtpVerificationView(email: email, srpAttributes: srp) { next in
                    path.append(next)
                }
            }

        case let .password(email, srp):
            authDestination {
                PasswordView(email: email, srpAttributes: srp) { next in
                    path.append(next)
                } onLoggedIn: {
                    appState.refreshLoginState()
                }
            }

        case let .twoFactor(email, srp, sessionId, password):
            authDestination {
                TwoFactorView(email: email, srpAttributes: srp, sessionId: sessionId, password: password) { next in
                    path.append(next)
                } onLoggedIn: {
                    appState.refreshLoginState()
                }
            }

        case let .passkey(email, srp, sessionId, accountsUrl, twoFactorSessionId, password):
            authDestination {
                PasskeyView(
                    email: email,
                    srpAttributes: srp,
                    sessionId: sessionId,
                    accountsUrl: accountsUrl,
                    twoFactorSessionId: twoFactorSessionId,
                    password: password
                ) { next in
                    path.append(next)
                } onLoggedIn: {
                    appState.refreshLoginState()
                }
            }

        case let .passwordAfterMfa(email, srp, userId, keyAttrs, encryptedToken, token):
            authDestination {
                PasswordAfterMfaView(
                    email: email,
                    srpAttributes: srp,
                    userId: userId,
                    keyAttributes: keyAttrs,
                    encryptedToken: encryptedToken,
                    token: token
                ) {
                    appState.refreshLoginState()
                }
            }

        case let .passkeyPasswordReentry(email, srp, auth):
            authDestination {
                PasskeyPasswordReentryView(email: email, srpAttributes: srp, auth: auth) {
                    appState.refreshLoginState()
                }
            }
        }
    }

    @ViewBuilder
    private func authDestination<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .platformBackButtonHidden(true)
            #if os(iOS)
            .toolbar {
                ToolbarItem(placement: leadingPlacement) {
                    Button {
                        guard !path.isEmpty else { return }
                        path.removeLast()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Back")
                        }
                        .font(EnsuTypography.small)
                        .foregroundStyle(EnsuColor.textMuted)
                    }
                    .padding(.leading, backButtonInset)
                }

                ToolbarItem(placement: .principal) {
                    Text("ensu")
                        .font(EnsuTypography.h3)
                        .foregroundStyle(EnsuColor.textPrimary)
                }

                ToolbarItem(placement: trailingPlacement) {
                    Button("Close") {
                        dismiss()
                    }
                    .font(EnsuTypography.small)
                    .foregroundStyle(EnsuColor.textMuted)
                }
            }
            #endif
    }
}
