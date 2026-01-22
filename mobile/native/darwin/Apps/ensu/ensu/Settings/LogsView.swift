import SwiftUI

struct LogsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedFile: URL?
    @State private var logText: String = ""

    @State private var presentingShare = false
    @State private var presentingExport = false
    @State private var archiveURL: URL?

    private let logger = EnsuLogging.shared.logger("LogsView")

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                content
            }
            .background(EnsuColor.backgroundBase)
            .navigationTitle("Logs")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
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
        }
        .task {
            selectedFile = EnsuLogging.shared.todayLogFileURL()
            loadSelectedFile()
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
    }

    private var content: some View {
        ScrollView {
            Text(logText.isEmpty ? "No logs available" : logText)
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundStyle(logText.isEmpty ? EnsuColor.textMuted : EnsuColor.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(EnsuSpacing.lg)
                .textSelection(.enabled)
        }
    }

    private func loadSelectedFile() {
        let url = selectedFile
        logText = EnsuLogging.shared.readLogText(fileURL: url)
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
