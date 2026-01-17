import SwiftUI

struct DeveloperSettingsView: View {
    @Environment(\.dismiss) private var dismiss

    var onSaved: ((String) -> Void)? = nil

    @State private var endpoint: String = ""
    @State private var currentEndpoint: String = EnsuDeveloperSettings.currentEndpointString
    @State private var isSaving = false
    @State private var alert: DeveloperSettingsAlert?

    var body: some View {
        Group {
            #if os(iOS)
            NavigationStack {
                content
                    .navigationTitle("Developer settings")
                    .toolbar {
                        ToolbarItem(placement: .primaryAction) {
                            Button("Close") {
                                dismiss()
                            }
                        }
                    }
            }
            #else
            content
            #endif
        }
        .background(EnsuColor.backgroundBase.ignoresSafeArea())
        .alert(item: $alert) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text("OK"))
            )
        }
        #if os(macOS)
        .safeAreaInset(edge: .top) {
            MacSheetHeader(
                leading: {
                    EmptyView()
                },
                center: {
                    Text("Developer settings")
                        .font(EnsuTypography.large)
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

    private var content: some View {
        VStack(alignment: .leading, spacing: EnsuSpacing.xxl) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Server endpoint")
                    .font(EnsuTypography.small)
                    .foregroundStyle(EnsuColor.textMuted)

                TextField(currentEndpoint, text: $endpoint)
                    .font(EnsuTypography.body)
                    .platformKeyboardType(.URL)
                    .platformTextInputAutocapitalization(.never)
                    .foregroundStyle(EnsuColor.textPrimary)
                    .platformTextFieldStyle()
                    .autocorrectionDisabled()
                    .padding(.horizontal, EnsuSpacing.inputHorizontal)
                    .padding(.vertical, EnsuSpacing.inputVertical)
                    .background(EnsuColor.fillFaint)
                    .clipShape(RoundedRectangle(cornerRadius: EnsuCornerRadius.input, style: .continuous))

                Text("Current endpoint: \(currentEndpoint)")
                    .font(EnsuTypography.mini)
                    .foregroundStyle(EnsuColor.textMuted)
            }

            PrimaryButton(text: "Save", isLoading: isSaving, isEnabled: isSavable) {
                Task { await saveTapped() }
            }

            Spacer()
        }
        .padding(EnsuSpacing.lg)
    }

    private var isSavable: Bool {
        !endpoint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSaving
    }

    @MainActor
    private func saveTapped() async {
        guard !isSaving else { return }
        let normalized = EnsuDeveloperSettings.normalize(endpoint)
        guard let url = URL(string: normalized),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https" else {
            alert = DeveloperSettingsAlert(
                title: "Invalid endpoint",
                message: "Please enter a valid server endpoint."
            )
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            try await ping(endpoint: url)
            EnsuAuthService.shared.updateEndpoint(url)
            onSaved?("Endpoint updated")
            dismiss()
        } catch {
            alert = DeveloperSettingsAlert(
                title: "Invalid endpoint",
                message: "Unable to reach the server at the provided endpoint."
            )
        }
    }

    private func ping(endpoint: URL) async throws {
        let pingURL = endpoint.appendingPathComponent("ping")
        let (data, response) = try await URLSession.shared.data(from: pingURL)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        let json = try JSONSerialization.jsonObject(with: data)
        guard let payload = json as? [String: Any],
              payload["message"] as? String == "pong" else {
            throw URLError(.cannotParseResponse)
        }
    }
}

private struct DeveloperSettingsAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}
