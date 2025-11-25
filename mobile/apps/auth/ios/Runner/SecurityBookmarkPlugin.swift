import Flutter
import Foundation
import UIKit
import UniformTypeIdentifiers

public class SecurityBookmarkPlugin: NSObject, FlutterPlugin {
    private var pendingResult: FlutterResult?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "io.ente.auth/security_bookmark",
            binaryMessenger: registrar.messenger()
        )
        let instance = SecurityBookmarkPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "pickDirectoryAndCreateBookmark":
            handlePickDirectoryAndCreateBookmark(result: result)
        case "createBookmark":
            handleCreateBookmark(call: call, result: result)
        case "resolveBookmark":
            handleResolveBookmark(call: call, result: result)
        case "startAccessingBookmark":
            handleStartAccessingBookmark(call: call, result: result)
        case "stopAccessingBookmark":
            handleStopAccessingBookmark(call: call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    /// Pick a directory using native iOS picker and create a bookmark immediately
    /// while we still have the security-scoped URL.
    private func handlePickDirectoryAndCreateBookmark(result: @escaping FlutterResult) {
        guard let viewController = UIApplication.shared.windows.first?.rootViewController else {
            result(FlutterError(code: "NO_VIEW_CONTROLLER", message: "Could not find root view controller", details: nil))
            return
        }

        pendingResult = result

        let picker: UIDocumentPickerViewController
        if #available(iOS 14.0, *) {
            picker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder])
        } else {
            // Fallback for iOS 13
            picker = UIDocumentPickerViewController(documentTypes: ["public.folder"], in: .open)
        }
        picker.delegate = self
        picker.allowsMultipleSelection = false

        viewController.present(picker, animated: true)
    }

    private func handleCreateBookmark(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let path = args["path"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing 'path' argument", details: nil))
            return
        }

        let url = URL(fileURLWithPath: path, isDirectory: true)

        // Check if path exists
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false
        let exists = fileManager.fileExists(atPath: path, isDirectory: &isDirectory)

        NSLog("SecurityBookmarkPlugin: Creating bookmark for path: \(path)")
        NSLog("SecurityBookmarkPlugin: URL: \(url.absoluteString)")
        NSLog("SecurityBookmarkPlugin: Path exists: \(exists), isDirectory: \(isDirectory.boolValue)")

        // Must start accessing the security-scoped resource before creating a bookmark
        let didStartAccessing = url.startAccessingSecurityScopedResource()
        NSLog("SecurityBookmarkPlugin: startAccessingSecurityScopedResource returned: \(didStartAccessing)")

        defer {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        do {
            // Create a minimal bookmark that can be persisted
            let bookmarkData = try url.bookmarkData(
                options: .minimalBookmark,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )

            // Return as base64 string for easy storage
            let base64String = bookmarkData.base64EncodedString()
            NSLog("SecurityBookmarkPlugin: Bookmark created successfully, length: \(base64String.count)")
            result(base64String)
        } catch {
            NSLog("SecurityBookmarkPlugin: Failed to create bookmark: \(error)")
            result(FlutterError(
                code: "BOOKMARK_ERROR",
                message: "Failed to create bookmark: \(error.localizedDescription)",
                details: "path=\(path), exists=\(exists), didStartAccessing=\(didStartAccessing)"
            ))
        }
    }

    private func handleResolveBookmark(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let base64Bookmark = args["bookmark"] as? String,
              let bookmarkData = Data(base64Encoded: base64Bookmark) else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing or invalid 'bookmark' argument", details: nil))
            return
        }

        do {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: bookmarkData,
                options: [],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )

            // Return both the path and stale status
            result([
                "path": url.path,
                "isStale": isStale
            ])
        } catch {
            result(FlutterError(
                code: "RESOLVE_ERROR",
                message: "Failed to resolve bookmark: \(error.localizedDescription)",
                details: nil
            ))
        }
    }

    private func handleStartAccessingBookmark(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let base64Bookmark = args["bookmark"] as? String,
              let bookmarkData = Data(base64Encoded: base64Bookmark) else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing or invalid 'bookmark' argument", details: nil))
            return
        }

        do {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: bookmarkData,
                options: [],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )

            let success = url.startAccessingSecurityScopedResource()
            result([
                "success": success,
                "path": url.path,
                "isStale": isStale
            ])
        } catch {
            result(FlutterError(
                code: "ACCESS_ERROR",
                message: "Failed to start accessing bookmark: \(error.localizedDescription)",
                details: nil
            ))
        }
    }

    private func handleStopAccessingBookmark(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let base64Bookmark = args["bookmark"] as? String,
              let bookmarkData = Data(base64Encoded: base64Bookmark) else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing or invalid 'bookmark' argument", details: nil))
            return
        }

        do {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: bookmarkData,
                options: [],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )

            url.stopAccessingSecurityScopedResource()
            result(true)
        } catch {
            result(FlutterError(
                code: "ACCESS_ERROR",
                message: "Failed to stop accessing bookmark: \(error.localizedDescription)",
                details: nil
            ))
        }
    }
}

// MARK: - UIDocumentPickerDelegate
extension SecurityBookmarkPlugin: UIDocumentPickerDelegate {
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let result = pendingResult else { return }
        pendingResult = nil

        guard let url = urls.first else {
            result(FlutterError(code: "NO_SELECTION", message: "No directory selected", details: nil))
            return
        }

        NSLog("SecurityBookmarkPlugin: Picked directory URL: \(url.absoluteString)")

        // Start accessing the security-scoped resource
        let didStartAccessing = url.startAccessingSecurityScopedResource()
        NSLog("SecurityBookmarkPlugin: startAccessingSecurityScopedResource: \(didStartAccessing)")

        defer {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        do {
            // Create bookmark while we have security-scoped access
            let bookmarkData = try url.bookmarkData(
                options: .minimalBookmark,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )

            let base64Bookmark = bookmarkData.base64EncodedString()
            NSLog("SecurityBookmarkPlugin: Bookmark created successfully, length: \(base64Bookmark.count)")

            result([
                "path": url.path,
                "bookmark": base64Bookmark
            ])
        } catch {
            NSLog("SecurityBookmarkPlugin: Failed to create bookmark: \(error)")
            result(FlutterError(
                code: "BOOKMARK_ERROR",
                message: "Failed to create bookmark: \(error.localizedDescription)",
                details: nil
            ))
        }
    }

    public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        guard let result = pendingResult else { return }
        pendingResult = nil
        result(nil) // User cancelled
    }
}
