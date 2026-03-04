import AVFoundation
import Flutter
import Photos
import SQLite3
import UIKit
import app_links
import workmanager_apple

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

private enum IOS26NativeUploadState: String {
  case queued
  case inProgress = "in_progress"
  case uploaded
  case failed
}

private struct IOS26UploadCandidate {
  let localID: String
  let collectionID: Int64
  let generatedID: Int64?
  let fileType: String?

  init?(map: [String: Any]) {
    guard
      let localID = map["localID"] as? String,
      !localID.isEmpty,
      let collectionID = IOS26UploadCandidate.toInt64(map["collectionID"])
    else {
      return nil
    }
    self.localID = localID
    self.collectionID = collectionID
    self.generatedID = IOS26UploadCandidate.toInt64(map["generatedID"])
    self.fileType = map["fileType"] as? String
  }

  private static func toInt64(_ value: Any?) -> Int64? {
    if let intValue = value as? Int {
      return Int64(intValue)
    }
    if let int64Value = value as? Int64 {
      return int64Value
    }
    if let numberValue = value as? NSNumber {
      return numberValue.int64Value
    }
    if let stringValue = value as? String {
      return Int64(stringValue)
    }
    return nil
  }
}

private final class IOS26BackgroundUploadQueueDB {
  static let shared = IOS26BackgroundUploadQueueDB()

  private let queue = DispatchQueue(label: "io.ente.photos.ios26-bg-queue")
  private let appGroupIdentifier = "group.io.ente.frame.ShareExtension"
  private let dbFileName = "ente.ios26.bg_upload.sqlite"
  private let tableName = "ios26_bg_upload_queue"
  private let uploadedFileIDColumn = "uploaded_file_id"

  private var db: OpaquePointer?

  private init() {
    openDatabase()
    createTableIfNeeded()
    ensureUploadedFileIDColumn()
  }

  deinit {
    if db != nil {
      sqlite3_close(db)
      db = nil
    }
  }

  func enqueue(candidates: [IOS26UploadCandidate]) -> Bool {
    guard !candidates.isEmpty else {
      return false
    }
    return queue.sync {
      guard let db else {
        return false
      }
      let now = Int64(Date().timeIntervalSince1970 * 1000)
      let sql = """
        INSERT INTO \(tableName)
          (local_id, collection_id, generated_id, file_type, \(uploadedFileIDColumn), state, error_message, created_at, updated_at)
        VALUES (?, ?, ?, ?, NULL, ?, NULL, ?, ?)
        ON CONFLICT(local_id, collection_id) DO UPDATE SET
          generated_id = excluded.generated_id,
          file_type = excluded.file_type,
          \(uploadedFileIDColumn) = excluded.\(uploadedFileIDColumn),
          state = excluded.state,
          error_message = NULL,
          updated_at = excluded.updated_at
      """
      var statement: OpaquePointer?
      defer { sqlite3_finalize(statement) }

      guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
        logLastSQLiteError(prefix: "enqueue prepare failed")
        return false
      }

      var wroteAnyRow = false
      for candidate in candidates {
        sqlite3_reset(statement)
        sqlite3_clear_bindings(statement)

        bindText(statement, index: 1, value: candidate.localID)
        sqlite3_bind_int64(statement, 2, candidate.collectionID)
        if let generatedID = candidate.generatedID {
          sqlite3_bind_int64(statement, 3, generatedID)
        } else {
          sqlite3_bind_null(statement, 3)
        }
        if let fileType = candidate.fileType {
          bindText(statement, index: 4, value: fileType)
        } else {
          sqlite3_bind_null(statement, 4)
        }
        bindText(statement, index: 5, value: IOS26NativeUploadState.queued.rawValue)
        sqlite3_bind_int64(statement, 6, now)
        sqlite3_bind_int64(statement, 7, now)

        if sqlite3_step(statement) == SQLITE_DONE {
          wroteAnyRow = true
        } else {
          logLastSQLiteError(prefix: "enqueue step failed")
        }
      }

      return wroteAnyRow
    }
  }

  func updateState(
    localID: String,
    collectionID: Int64,
    state: IOS26NativeUploadState,
    errorMessage: String?,
    uploadedFileID: Int64?
  ) -> Bool {
    return queue.sync {
      guard let db else {
        return false
      }
      let sql = """
        UPDATE \(tableName)
        SET state = ?, error_message = ?, \(uploadedFileIDColumn) = COALESCE(?, \(uploadedFileIDColumn)), updated_at = ?
        WHERE local_id = ? AND collection_id = ?
      """
      var statement: OpaquePointer?
      defer { sqlite3_finalize(statement) }

      guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
        logLastSQLiteError(prefix: "updateState prepare failed")
        return false
      }

      bindText(statement, index: 1, value: state.rawValue)
      if let errorMessage {
        bindText(statement, index: 2, value: errorMessage)
      } else {
        sqlite3_bind_null(statement, 2)
      }
      if let uploadedFileID {
        sqlite3_bind_int64(statement, 3, uploadedFileID)
      } else {
        sqlite3_bind_null(statement, 3)
      }
      sqlite3_bind_int64(statement, 4, Int64(Date().timeIntervalSince1970 * 1000))
      bindText(statement, index: 5, value: localID)
      sqlite3_bind_int64(statement, 6, collectionID)

      if sqlite3_step(statement) != SQLITE_DONE {
        logLastSQLiteError(prefix: "updateState step failed")
        return false
      }
      return sqlite3_changes(db) > 0
    }
  }

  func getUploadStates(limit: Int = 500) -> [[String: Any]] {
    return queue.sync {
      guard let db else {
        return []
      }
      let safeLimit = max(1, min(2000, limit))
      let sql = """
        SELECT local_id, collection_id, generated_id, file_type, \(uploadedFileIDColumn), state, error_message, updated_at
        FROM \(tableName)
        ORDER BY updated_at DESC
        LIMIT ?
      """
      var statement: OpaquePointer?
      defer { sqlite3_finalize(statement) }

      guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
        logLastSQLiteError(prefix: "getUploadStates prepare failed")
        return []
      }
      sqlite3_bind_int64(statement, 1, Int64(safeLimit))

      var output: [[String: Any]] = []
      while sqlite3_step(statement) == SQLITE_ROW {
        guard let localIDPtr = sqlite3_column_text(statement, 0) else {
          continue
        }
        let localID = String(cString: localIDPtr)
        let collectionID = sqlite3_column_int64(statement, 1)
        let generatedID = sqlite3_column_type(statement, 2) == SQLITE_NULL
          ? nil
          : Int64(sqlite3_column_int64(statement, 2))
        let fileType = sqlite3_column_type(statement, 3) == SQLITE_NULL
          ? nil
          : String(cString: sqlite3_column_text(statement, 3))
        let uploadedFileID = sqlite3_column_type(statement, 4) == SQLITE_NULL
          ? nil
          : Int64(sqlite3_column_int64(statement, 4))
        let state = sqlite3_column_type(statement, 5) == SQLITE_NULL
          ? IOS26NativeUploadState.queued.rawValue
          : String(cString: sqlite3_column_text(statement, 5))
        let errorMessage = sqlite3_column_type(statement, 6) == SQLITE_NULL
          ? nil
          : String(cString: sqlite3_column_text(statement, 6))
        let updatedAt = sqlite3_column_int64(statement, 7)

        output.append([
          "localID": localID,
          "collectionID": collectionID,
          "generatedID": generatedID as Any,
          "fileType": fileType as Any,
          "uploadedFileID": uploadedFileID as Any,
          "state": state,
          "errorMessage": errorMessage as Any,
          "updatedAt": updatedAt,
        ])
      }
      return output
    }
  }

  func clearQueue() -> Bool {
    return queue.sync {
      guard let db else {
        return false
      }
      let sql = "DELETE FROM \(tableName)"
      var statement: OpaquePointer?
      defer { sqlite3_finalize(statement) }
      guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
        logLastSQLiteError(prefix: "clearQueue prepare failed")
        return false
      }
      if sqlite3_step(statement) != SQLITE_DONE {
        logLastSQLiteError(prefix: "clearQueue step failed")
        return false
      }
      return true
    }
  }

  private func openDatabase() {
    let dbPath: String
    if let appGroupURL = FileManager.default.containerURL(
      forSecurityApplicationGroupIdentifier: appGroupIdentifier
    ) {
      dbPath = appGroupURL.appendingPathComponent(dbFileName).path
    } else {
      let documentsPath =
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.path
        ?? NSTemporaryDirectory()
      dbPath = (documentsPath as NSString).appendingPathComponent(dbFileName)
      print(
        "[IOS26BackgroundUploadQueueDB] App group unavailable, using fallback path: \(dbPath)")
    }

    guard sqlite3_open(dbPath, &db) == SQLITE_OK else {
      logLastSQLiteError(prefix: "openDatabase failed")
      db = nil
      return
    }

    _ = exec("PRAGMA journal_mode=WAL;")
    _ = exec("PRAGMA synchronous=NORMAL;")
  }

  private func createTableIfNeeded() {
    let sql = """
      CREATE TABLE IF NOT EXISTS \(tableName) (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        local_id TEXT NOT NULL,
        collection_id INTEGER NOT NULL,
        generated_id INTEGER,
        file_type TEXT,
        \(uploadedFileIDColumn) INTEGER,
        state TEXT NOT NULL,
        error_message TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        UNIQUE(local_id, collection_id)
      )
    """
    _ = exec(sql)
  }

  @discardableResult
  private func exec(_ sql: String) -> Bool {
    return queue.sync {
      guard let db else {
        return false
      }
      var statement: OpaquePointer?
      defer { sqlite3_finalize(statement) }
      guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
        logLastSQLiteError(prefix: "exec prepare failed")
        return false
      }
      guard sqlite3_step(statement) == SQLITE_DONE else {
        logLastSQLiteError(prefix: "exec step failed")
        return false
      }
      return true
    }
  }

  private func ensureUploadedFileIDColumn() {
    queue.sync {
      guard let db else {
        return
      }

      let tableInfoQuery = "PRAGMA table_info(\(tableName))"
      var statement: OpaquePointer?
      defer { sqlite3_finalize(statement) }

      guard sqlite3_prepare_v2(db, tableInfoQuery, -1, &statement, nil) == SQLITE_OK else {
        logLastSQLiteError(prefix: "table info prepare failed")
        return
      }

      var hasColumn = false
      while sqlite3_step(statement) == SQLITE_ROW {
        guard let columnNamePtr = sqlite3_column_text(statement, 1) else {
          continue
        }
        let columnName = String(cString: columnNamePtr)
        if columnName == uploadedFileIDColumn {
          hasColumn = true
          break
        }
      }

      if hasColumn {
        return
      }

      var alterStatement: OpaquePointer?
      defer { sqlite3_finalize(alterStatement) }
      let alterSQL = "ALTER TABLE \(tableName) ADD COLUMN \(uploadedFileIDColumn) INTEGER"
      if sqlite3_prepare_v2(db, alterSQL, -1, &alterStatement, nil) != SQLITE_OK {
        logLastSQLiteError(prefix: "alter table prepare failed")
        return
      }
      if sqlite3_step(alterStatement) != SQLITE_DONE {
        logLastSQLiteError(prefix: "alter table step failed")
      }
    }
  }

  private func bindText(_ statement: OpaquePointer?, index: Int32, value: String) {
    value.withCString { cString in
      sqlite3_bind_text(statement, index, cString, -1, SQLITE_TRANSIENT)
    }
  }

  private func logLastSQLiteError(prefix: String) {
    guard let db else {
      print("[IOS26BackgroundUploadQueueDB] \(prefix): db unavailable")
      return
    }
    let message = String(cString: sqlite3_errmsg(db))
    print("[IOS26BackgroundUploadQueueDB] \(prefix): \(message)")
  }
}

private enum IOS26UploadConfigurationStore {
  static let appGroupIdentifier = "group.io.ente.frame.ShareExtension"
  private static let baseURLKey = "ios26_bg_upload_base_url"
  private static let authTokenKey = "ios26_bg_upload_auth_token"
  private static let userIDKey = "ios26_bg_upload_user_id"
  private static let updatedAtKey = "ios26_bg_upload_updated_at"

  static func hasConfiguration() -> Bool {
    guard let defaults = UserDefaults(suiteName: appGroupIdentifier) else {
      return false
    }
    let baseURL = defaults.string(forKey: baseURLKey) ?? ""
    let authToken = defaults.string(forKey: authTokenKey) ?? ""
    return !baseURL.isEmpty && !authToken.isEmpty
  }

  static func save(baseURL: String, authToken: String, userID: Int64?) -> Bool {
    guard
      let parsedURL = URL(string: baseURL),
      let scheme = parsedURL.scheme?.lowercased(),
      scheme == "http" || scheme == "https"
    else {
      return false
    }
    guard !authToken.isEmpty else {
      return false
    }
    guard let defaults = UserDefaults(suiteName: appGroupIdentifier) else {
      return false
    }

    defaults.set(parsedURL.absoluteString, forKey: baseURLKey)
    defaults.set(authToken, forKey: authTokenKey)
    if let userID {
      defaults.set(NSNumber(value: userID), forKey: userIDKey)
    } else {
      defaults.removeObject(forKey: userIDKey)
    }
    defaults.set(Int64(Date().timeIntervalSince1970 * 1000), forKey: updatedAtKey)
    return true
  }
}

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let ios26BackgroundUploadChannelName = "io.ente.photos/ios26_bg_upload"
  private let ios26QueueDB = IOS26BackgroundUploadQueueDB.shared

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // Prevent interrupting background audio from other apps on launch
    do {
      try AVAudioSession.sharedInstance().setCategory(
        .ambient,
        mode: .default,
        options: [.mixWithOthers]
      )
    } catch {
      print("Failed to configure initial audio session: \(error)")
    }

    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }

    GeneratedPluginRegistrant.register(with: self)
    WorkmanagerPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: ios26BackgroundUploadChannelName,
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { call, result in
        self.handleIOS26BackgroundUploadMethodCall(call, result: result)
      }
    }

    var freqInMinutes = 30 * 60
    // Register a periodic task in iOS 13+
    WorkmanagerPlugin.registerPeriodicTask(
      withIdentifier: "io.ente.frame.iOSBackgroundAppRefresh",
      frequency: NSNumber(value: freqInMinutes))

    // Retrieve the link from parameters
    if let url = AppLinks.shared.getLink(launchOptions: launchOptions) {
      // only accept non-homewidget urls for AppLinks
      if !url.absoluteString.contains("&homeWidget") {
        AppLinks.shared.handleLink(url: url)
        // link is handled, stop propagation
        return true
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    signal(SIGPIPE, SIG_IGN)
  }

  override func applicationWillEnterForeground(_ application: UIApplication) {
    signal(SIGPIPE, SIG_IGN)
  }

  private func handleIOS26BackgroundUploadMethodCall(
    _ call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) {
    switch call.method {
    case "isNativeUploaderReady":
      result(isIOS26NativeUploaderReady())
    case "configureNativeUploader":
      guard
        let arguments = call.arguments as? [String: Any],
        let baseURL = arguments["baseURL"] as? String,
        let authToken = arguments["authToken"] as? String
      else {
        result(FlutterError(
          code: "invalid_arguments",
          message: "Expected baseURL and authToken",
          details: nil
        ))
        return
      }
      let userID = (arguments["userID"] as? NSNumber)?.int64Value
      let saved = IOS26UploadConfigurationStore.save(
        baseURL: baseURL,
        authToken: authToken,
        userID: userID
      )
      if saved {
        _ = maybeEnableIOS26UploadExtension()
      }
      result(saved && isIOS26NativeUploaderReady())
    case "enqueueUploadCandidates":
      guard
        let arguments = call.arguments as? [String: Any],
        let filesPayload = arguments["files"] as? [[String: Any]]
      else {
        result(FlutterError(
          code: "invalid_arguments",
          message: "Expected argument format: { files: List<Map> }",
          details: nil
        ))
        return
      }

      let candidates = filesPayload.compactMap(IOS26UploadCandidate.init)
      let queued = ios26QueueDB.enqueue(candidates: candidates)
      let ready = isIOS26NativeUploaderReady()
      if queued && ready {
        _ = maybeEnableIOS26UploadExtension()
      }
      result(queued && ready)
    case "getUploadStates":
      let limit: Int
      if
        let arguments = call.arguments as? [String: Any],
        let rawLimit = arguments["limit"] as? NSNumber
      {
        limit = rawLimit.intValue
      } else {
        limit = 500
      }
      result(ios26QueueDB.getUploadStates(limit: limit))
    case "updateUploadState":
      guard
        let arguments = call.arguments as? [String: Any],
        let localID = arguments["localID"] as? String,
        let collectionID = (arguments["collectionID"] as? NSNumber)?.int64Value,
        let rawState = arguments["state"] as? String,
        let state = IOS26NativeUploadState(rawValue: rawState)
      else {
        result(FlutterError(
          code: "invalid_arguments",
          message: "Expected localID, collectionID and valid state",
          details: nil
        ))
        return
      }
      let errorMessage = arguments["errorMessage"] as? String
      let uploadedFileID = (arguments["uploadedFileID"] as? NSNumber)?.int64Value
      result(ios26QueueDB.updateState(
        localID: localID,
        collectionID: collectionID,
        state: state,
        errorMessage: errorMessage,
        uploadedFileID: uploadedFileID
      ))
    case "clearUploadQueue":
      result(ios26QueueDB.clearQueue())
    case "verifyDecryptedFileHash":
      guard
        let arguments = call.arguments as? [String: Any],
        let filePath = arguments["filePath"] as? String,
        let expectedHash = arguments["expectedHash"] as? String,
        !filePath.isEmpty,
        !expectedHash.isEmpty
      else {
        result(FlutterError(
          code: "invalid_arguments",
          message: "Expected filePath and expectedHash",
          details: nil
        ))
        return
      }

      do {
        let isValid = try IOS26CoreCryptoBridge.shared.verifyBlake2bHash(
          filePath: filePath,
          expectedHash: expectedHash
        )
        result(isValid)
      } catch {
        result(FlutterError(
          code: "hash_verification_failed",
          message: "Native hash verification failed",
          details: error.localizedDescription
        ))
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func isIOS26NativeUploaderReady() -> Bool {
    guard #available(iOS 26.1, *) else {
      return false
    }
    guard hasIOS26UploadExtensionBundle() else {
      return false
    }
    guard IOS26UploadConfigurationStore.hasConfiguration() else {
      return false
    }

    let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    guard status == .authorized || status == .limited else {
      return false
    }

    if !PHPhotoLibrary.shared().uploadJobExtensionEnabled {
      _ = maybeEnableIOS26UploadExtension()
    }

    return PHPhotoLibrary.shared().uploadJobExtensionEnabled
  }

  private func maybeEnableIOS26UploadExtension() -> Bool {
    guard #available(iOS 26.1, *) else {
      return false
    }
    let library = PHPhotoLibrary.shared()
    if library.uploadJobExtensionEnabled {
      return true
    }
    do {
      try library.setUploadJobExtensionEnabled(true)
      return library.uploadJobExtensionEnabled
    } catch {
      print("[IOS26BackgroundUpload] Failed to enable upload extension: \(error)")
      return false
    }
  }

  private func hasIOS26UploadExtensionBundle() -> Bool {
    guard let pluginsURL = Bundle.main.builtInPlugInsURL else {
      return false
    }
    guard let pluginURLs = try? FileManager.default.contentsOfDirectory(
      at: pluginsURL,
      includingPropertiesForKeys: nil
    ) else {
      return false
    }

    for pluginURL in pluginURLs where pluginURL.pathExtension == "appex" {
      guard
        let bundle = Bundle(url: pluginURL),
        let info = bundle.infoDictionary,
        let exAttributes = info["EXAppExtensionAttributes"] as? [String: Any],
        let identifier = exAttributes["EXExtensionPointIdentifier"] as? String
      else {
        continue
      }
      if identifier == "com.apple.photos.background-upload" {
        return true
      }
    }
    return false
  }
}
