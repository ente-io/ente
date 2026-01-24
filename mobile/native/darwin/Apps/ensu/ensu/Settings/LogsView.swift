#if canImport(EnteCore)
import SwiftUI

struct LogsView: View {
    @Environment(\.dismiss) private var dismiss
    let embeddedInNavigation: Bool

    @State private var selectedFile: URL?
    @State private var entries: [EnsuLogEntry] = []
    @State private var query: String = ""
    @State private var selectedEntry: EnsuLogEntry?

    @State private var presentingShare = false
    @State private var presentingExport = false
    @State private var archiveURL: URL?

    @ObservedObject private var logStore = EnsuLogStore.shared

    private let logger = EnsuLogging.shared.logger("LogsView")

    init(embeddedInNavigation: Bool = false) {
        self.embeddedInNavigation = embeddedInNavigation
    }

    var body: some View {
        Group {
            if embeddedInNavigation {
                VStack(spacing: 0) {
                    content
                }
                .background(EnsuColor.backgroundBase)
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .toolbar {
                    toolbarContent
                }
            } else {
                NavigationStack {
                    VStack(spacing: 0) {
                        content
                    }
                    .background(EnsuColor.backgroundBase)
                    #if os(iOS)
                    .navigationBarTitleDisplayMode(.inline)
                    #endif
                    .toolbar {
                        toolbarContent
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") { dismiss() }
                        }
                    }
                }
            }
        }
        .task {
            selectedFile = EnsuLogging.shared.todayLogFileURL()
            refreshEntries()
        }
        .onChange(of: logStore.entries) { _ in
            refreshEntries()
        }
        #if os(iOS)
        .sheet(isPresented: $presentingShare) {
            if let archiveURL {
                ActivityView(activityItems: [archiveURL])
            }
        }
        .sheet(isPresented: $presentingExport) {
            if let archiveURL {
                ExportDocumentPicker(urls: [archiveURL])
            }
        }
        #endif
        .sheet(item: $selectedEntry) { entry in
            LogDetailView(entry: entry)
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text("Logs")
                .font(EnsuTypography.large)
                .foregroundStyle(EnsuColor.textPrimary)
        }
        ToolbarItem(placement: .primaryAction) {
            Menu {
                Button("Share") { shareTapped() }
                Button("Export") { exportTapped() }
            } label: {
                Image(systemName: "square.and.arrow.up")
            }
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: EnsuSpacing.lg) {
            searchField

            if filteredEntries.isEmpty {
                Text("No logs available")
                    .font(EnsuTypography.body)
                    .foregroundStyle(EnsuColor.textMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ScrollView {
                    LazyVStack(spacing: EnsuSpacing.sm) {
                        ForEach(filteredEntries) { entry in
                            LogCard(entry: entry) {
                                selectedEntry = entry
                            }
                        }
                    }
                    .padding(.bottom, EnsuSpacing.lg)
                }
            }
        }
        .padding(EnsuSpacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var searchField: some View {
        TextField("Search logs", text: $query)
            .font(EnsuTypography.body)
            .platformTextInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .platformTextFieldStyle()
            .padding(.horizontal, EnsuSpacing.inputHorizontal)
            .padding(.vertical, EnsuSpacing.inputVertical)
            .background(EnsuColor.fillFaint)
            .clipShape(RoundedRectangle(cornerRadius: EnsuCornerRadius.input, style: .continuous))
    }

    private var filteredEntries: [EnsuLogEntry] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return entries }
        let lower = trimmed.lowercased()
        return entries.filter { entry in
            entry.message.lowercased().contains(lower)
                || entry.tag.lowercased().contains(lower)
                || entry.level.rawValue.lowercased().contains(lower)
                || (entry.details?.lowercased().contains(lower) == true)
        }
    }

    private func refreshEntries() {
        let text = EnsuLogging.shared.readLogText(fileURL: selectedFile)
        let parsed = parseLogText(text)
        if parsed.isEmpty {
            entries = logStore.entries
        } else {
            entries = parsed
        }
    }

    private func parseLogText(_ text: String) -> [EnsuLogEntry] {
        let lines = text.components(separatedBy: .newlines)
        var parsedEntries: [EnsuLogEntry] = []
        var currentIndex: Int?

        for line in lines {
            guard !line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { continue }
            guard let match = logLineRegex.firstMatch(in: line, options: [], range: NSRange(location: 0, length: line.count)) else {
                continue
            }

            guard let tagRange = Range(match.range(at: 1), in: line),
                  let levelRange = Range(match.range(at: 2), in: line),
                  let timestampRange = Range(match.range(at: 3), in: line),
                  let messageRange = Range(match.range(at: 4), in: line) else {
                continue
            }

            let tag = String(line[tagRange])
            let levelString = String(line[levelRange])
            let timestampString = String(line[timestampRange])
            let message = String(line[messageRange])

            if message.hasPrefix("⤷ ") {
                guard let index = currentIndex else { continue }
                let detailLine = String(message.dropFirst(2))
                let current = parsedEntries[index]
                let existing = current.details ?? ""
                let combined = existing.isEmpty ? detailLine : "\n" + detailLine
                parsedEntries[index] = EnsuLogEntry(
                    timestamp: current.timestamp,
                    level: current.level,
                    tag: current.tag,
                    message: current.message,
                    details: combined
                )
                continue
            }

            let timestamp = logLineFormatter.date(from: timestampString) ?? Date()
            let level = EnsuLogLevel(rawValue: levelString) ?? .info
            let entry = EnsuLogEntry(
                timestamp: timestamp,
                level: level,
                tag: tag,
                message: message,
                details: nil
            )
            parsedEntries.append(entry)
            currentIndex = parsedEntries.count - 1
        }

        return parsedEntries.reversed()
    }

    private func shareTapped() {
        do {
            archiveURL = try EnsuLogging.shared.createLogsArchive()
        } catch {
            logger.error("Failed to create logs archive", error)
            return
        }

        #if os(iOS)
        presentingShare = true
        #elseif os(macOS)
        if let archiveURL {
            MacShareSheet(items: [archiveURL]).present()
        }
        #endif
    }

    private func exportTapped() {
        do {
            archiveURL = try EnsuLogging.shared.createLogsArchive()
        } catch {
            logger.error("Failed to create logs archive", error)
            return
        }

        #if os(iOS)
        presentingExport = true
        #elseif os(macOS)
        exportOnMac()
        #endif
    }

    #if os(macOS)
    private func exportOnMac() {
        guard let archiveURL else { return }
        let panel = NSSavePanel()
        panel.nameFieldStringValue = archiveURL.lastPathComponent
        panel.begin { response in
            guard response == .OK, let dest = panel.url else { return }
            do {
                if FileManager.default.fileExists(atPath: dest.path) {
                    try FileManager.default.removeItem(at: dest)
                }
                try FileManager.default.copyItem(at: archiveURL, to: dest)
            } catch {
                logger.error("Failed to export logs", error)
            }
        }
    }
    #endif
}

private struct LogCard: View {
    let entry: EnsuLogEntry
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: EnsuSpacing.xs) {
                HStack(spacing: EnsuSpacing.sm) {
                    Text(entry.level.rawValue)
                        .font(EnsuTypography.mini)
                        .foregroundStyle(levelColor(entry.level))

                    Text(entry.tag)
                        .font(EnsuTypography.mini)
                        .foregroundStyle(EnsuColor.textMuted)

                    Text(logTimestampFormatter.string(from: entry.timestamp))
                        .font(EnsuTypography.mini)
                        .foregroundStyle(EnsuColor.textMuted)
                }

                Text(entry.message)
                    .font(EnsuTypography.body)
                    .foregroundStyle(EnsuColor.textPrimary)
                    .lineLimit(3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(EnsuSpacing.lg)
            .background(EnsuColor.fillFaint)
            .clipShape(RoundedRectangle(cornerRadius: EnsuCornerRadius.card, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func levelColor(_ level: EnsuLogLevel) -> Color {
        switch level {
        case .info:
            return EnsuColor.textMuted
        case .warning:
            return EnsuColor.accent
        case .error:
            return EnsuColor.error
        }
    }
}

private struct LogDetailView: View {
    let entry: EnsuLogEntry
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: EnsuSpacing.md) {
                    Text("Level: \(entry.level.rawValue)")
                        .font(EnsuTypography.small)
                        .foregroundStyle(EnsuColor.textMuted)

                    Text("Tag: \(entry.tag)")
                        .font(EnsuTypography.small)
                        .foregroundStyle(EnsuColor.textMuted)

                    Text("Time: \(logTimestampFormatter.string(from: entry.timestamp))")
                        .font(EnsuTypography.small)
                        .foregroundStyle(EnsuColor.textMuted)

                    Divider()

                    Text(entry.message)
                        .font(EnsuTypography.body)
                        .foregroundStyle(EnsuColor.textPrimary)

                    if let details = entry.details, !details.isEmpty {
                        Text("Details")
                            .font(EnsuTypography.small)
                            .foregroundStyle(EnsuColor.textMuted)

                        Text(details)
                            .font(.system(size: 12, weight: .regular, design: .monospaced))
                            .foregroundStyle(EnsuColor.textPrimary)
                            .textSelection(.enabled)
                    }
                }
                .padding(EnsuSpacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle("Log details")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

private let logTimestampFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale.current
    formatter.dateFormat = "MMM d, h:mm:ss a"
    return formatter
}()

private let logLineFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
    return formatter
}()

private let logLineRegex: NSRegularExpression = {
    let pattern = "^\\[(.+?)\\]\\[(.+?)\\] \\[(.+?)\\] (.+)$"
    return try! NSRegularExpression(pattern: pattern, options: [])
}()

#if os(iOS)
import UIKit

struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct ExportDocumentPicker: UIViewControllerRepresentable {
    let urls: [URL]

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forExporting: urls, asCopy: true)
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
}
#endif

#if os(macOS)
import AppKit

private final class MacShareSheet: NSObject {
    private let items: [Any]

    init(items: [Any]) {
        self.items = items
    }

    func present() {
        guard let keyWindow = NSApplication.shared.keyWindow,
              let contentView = keyWindow.contentView else { return }
        let picker = NSSharingServicePicker(items: items)
        picker.show(relativeTo: .zero, of: contentView, preferredEdge: .minY)
    }
}
#endif

#else
import SwiftUI

struct LogsView: View {
    var body: some View {
        Text("Logs unavailable")
    }
}
#endif
