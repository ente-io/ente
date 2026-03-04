import ExtensionFoundation
import Foundation
import Photos
import SQLite3

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

private enum IOS26NativeUploadState: String {
  case queued
  case inProgress = "in_progress"
  case uploaded
  case failed
}

private struct IOS26UploadQueueCandidate {
  let localID: String
  let collectionID: Int64
}

private struct IOS26UploadConfiguration {
  let baseURL: URL
  let authToken: String
  let userID: Int64?
}

private enum IOS26UploadConfigurationStore {
  static let appGroupIdentifier = "group.io.ente.frame.ShareExtension"
  static let baseURLKey = "ios26_bg_upload_base_url"
  static let authTokenKey = "ios26_bg_upload_auth_token"
  static let userIDKey = "ios26_bg_upload_user_id"

  static func load() -> IOS26UploadConfiguration? {
    guard let defaults = UserDefaults(suiteName: appGroupIdentifier) else {
      return nil
    }
    guard
      let baseURLValue = defaults.string(forKey: baseURLKey),
      let baseURL = URL(string: baseURLValue),
      let authToken = defaults.string(forKey: authTokenKey),
      !authToken.isEmpty
    else {
      return nil
    }

    let userID: Int64?
    if let number = defaults.object(forKey: userIDKey) as? NSNumber {
      userID = number.int64Value
    } else {
      userID = nil
    }

    return IOS26UploadConfiguration(
      baseURL: baseURL,
      authToken: authToken,
      userID: userID
    )
  }
}

private final class IOS26BackgroundUploadQueueDB {
  static let shared = IOS26BackgroundUploadQueueDB()

  private let queue = DispatchQueue(label: "io.ente.photos.ios26-bg-upload-extension-queue")
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

  func getQueuedCandidates(limit: Int = 50) -> [IOS26UploadQueueCandidate] {
    return queue.sync {
      guard let db else {
        return []
      }
      let safeLimit = max(1, min(500, limit))
      let sql = """
        SELECT local_id, collection_id
        FROM \(tableName)
        WHERE state = ?
        ORDER BY updated_at ASC
        LIMIT ?
      """
      var statement: OpaquePointer?
      defer { sqlite3_finalize(statement) }

      guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
        return []
      }

      bindText(statement, index: 1, value: IOS26NativeUploadState.queued.rawValue)
      sqlite3_bind_int64(statement, 2, Int64(safeLimit))

      var candidates: [IOS26UploadQueueCandidate] = []
      while sqlite3_step(statement) == SQLITE_ROW {
        guard let localIDPtr = sqlite3_column_text(statement, 0) else {
          continue
        }
        let localID = String(cString: localIDPtr)
        let collectionID = sqlite3_column_int64(statement, 1)
        candidates.append(
          IOS26UploadQueueCandidate(localID: localID, collectionID: collectionID)
        )
      }
      return candidates
    }
  }

  func markInProgress(localID: String, collectionID: Int64) {
    updateState(
      localID: localID,
      collectionID: collectionID,
      state: .inProgress,
      errorMessage: nil
    )
  }

  func markUploaded(localID: String) {
    queue.sync {
      guard let db else {
        return
      }
      let sql = """
        UPDATE \(tableName)
        SET state = ?, error_message = NULL, updated_at = ?
        WHERE local_id = ?
      """
      var statement: OpaquePointer?
      defer { sqlite3_finalize(statement) }
      guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
        return
      }
      bindText(statement, index: 1, value: IOS26NativeUploadState.uploaded.rawValue)
      sqlite3_bind_int64(statement, 2, Int64(Date().timeIntervalSince1970 * 1000))
      bindText(statement, index: 3, value: localID)
      _ = sqlite3_step(statement)
    }
  }

  func markFailed(localID: String, collectionID: Int64, errorMessage: String) {
    updateState(
      localID: localID,
      collectionID: collectionID,
      state: .failed,
      errorMessage: errorMessage
    )
  }

  func markInProgressAsFailed(errorMessage: String) {
    queue.sync {
      guard let db else {
        return
      }
      let sql = """
        UPDATE \(tableName)
        SET state = ?, error_message = ?, updated_at = ?
        WHERE state = ?
      """
      var statement: OpaquePointer?
      defer { sqlite3_finalize(statement) }
      guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
        return
      }
      bindText(statement, index: 1, value: IOS26NativeUploadState.failed.rawValue)
      bindText(statement, index: 2, value: errorMessage)
      sqlite3_bind_int64(statement, 3, Int64(Date().timeIntervalSince1970 * 1000))
      bindText(statement, index: 4, value: IOS26NativeUploadState.inProgress.rawValue)
      _ = sqlite3_step(statement)
    }
  }

  private func updateState(
    localID: String,
    collectionID: Int64,
    state: IOS26NativeUploadState,
    errorMessage: String?
  ) {
    queue.sync {
      guard let db else {
        return
      }
      let sql = """
        UPDATE \(tableName)
        SET state = ?, error_message = ?, updated_at = ?
        WHERE local_id = ? AND collection_id = ?
      """
      var statement: OpaquePointer?
      defer { sqlite3_finalize(statement) }
      guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
        return
      }
      bindText(statement, index: 1, value: state.rawValue)
      if let errorMessage {
        bindText(statement, index: 2, value: errorMessage)
      } else {
        sqlite3_bind_null(statement, 2)
      }
      sqlite3_bind_int64(statement, 3, Int64(Date().timeIntervalSince1970 * 1000))
      bindText(statement, index: 4, value: localID)
      sqlite3_bind_int64(statement, 5, collectionID)
      _ = sqlite3_step(statement)
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
    }

    guard sqlite3_open(dbPath, &db) == SQLITE_OK else {
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
        return false
      }
      guard sqlite3_step(statement) == SQLITE_DONE else {
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
      guard sqlite3_prepare_v2(db, alterSQL, -1, &alterStatement, nil) == SQLITE_OK else {
        return
      }
      _ = sqlite3_step(alterStatement)
    }
  }

  private func bindText(_ statement: OpaquePointer?, index: Int32, value: String) {
    value.withCString { cString in
      sqlite3_bind_text(statement, index, cString, -1, SQLITE_TRANSIENT)
    }
  }
}

@main
@available(iOS 26.1, *)
final class IOS26BackgroundUploadExtension: PHBackgroundResourceUploadExtension {
  private let queueDB = IOS26BackgroundUploadQueueDB.shared
  private let cancellationLock = NSLock()
  private var cancelled = false

  required init() {}

  func process() -> PHBackgroundResourceUploadProcessingResult {
    guard !isCancelled else {
      return .processing
    }

    guard let configuration = IOS26UploadConfigurationStore.load() else {
      return .completed
    }

    do {
      try retryFailedJobs(configuration: configuration)
      guard !isCancelled else {
        return .processing
      }

      try acknowledgeCompletedJobs()
      guard !isCancelled else {
        return .processing
      }

      try createQueuedJobs(configuration: configuration)
      return .completed
    } catch let error as NSError
      where error.domain == PHPhotosErrorDomain
        && error.code == PHPhotosError.limitExceeded.rawValue
    {
      return .processing
    } catch {
      queueDB.markInProgressAsFailed(errorMessage: error.localizedDescription)
      return .failure
    }
  }

  func notifyTermination() {
    cancellationLock.lock()
    cancelled = true
    cancellationLock.unlock()
  }

  private var isCancelled: Bool {
    cancellationLock.lock()
    let value = cancelled
    cancellationLock.unlock()
    return value
  }

  private func retryFailedJobs(configuration: IOS26UploadConfiguration) throws {
    let library = PHPhotoLibrary.shared()
    let jobs = PHAssetResourceUploadJob.fetchJobs(action: .retry, options: nil)
    guard jobs.count > 0 else {
      return
    }

    for i in 0..<jobs.count {
      guard !isCancelled else {
        return
      }
      let job = jobs.object(at: i)
      guard let destination = buildDestination(for: job.resource, configuration: configuration) else {
        continue
      }
      try library.performChangesAndWait {
        PHAssetResourceUploadJobChangeRequest(for: job)?.retry(destination: destination)
      }
    }
  }

  private func acknowledgeCompletedJobs() throws {
    let library = PHPhotoLibrary.shared()
    let jobs = PHAssetResourceUploadJob.fetchJobs(action: .acknowledge, options: nil)
    guard jobs.count > 0 else {
      return
    }

    for i in 0..<jobs.count {
      guard !isCancelled else {
        return
      }
      let job = jobs.object(at: i)
      let localID = job.resource.assetLocalIdentifier
      queueDB.markUploaded(localID: localID)
      try library.performChangesAndWait {
        PHAssetResourceUploadJobChangeRequest(for: job)?.acknowledge()
      }
    }
  }

  private func createQueuedJobs(configuration: IOS26UploadConfiguration) throws {
    let library = PHPhotoLibrary.shared()
    let candidates = queueDB.getQueuedCandidates(limit: 60)
    guard !candidates.isEmpty else {
      return
    }

    for candidate in candidates {
      guard !isCancelled else {
        return
      }

      guard
        let resource = resolvePrimaryImageResource(localID: candidate.localID),
        let destination = buildDestination(for: resource, configuration: configuration)
      else {
        queueDB.markFailed(
          localID: candidate.localID,
          collectionID: candidate.collectionID,
          errorMessage: "Unable to resolve image resource or destination URL"
        )
        continue
      }

      do {
        try library.performChangesAndWait {
          PHAssetResourceUploadJobChangeRequest.createJob(
            destination: destination,
            resource: resource
          )
        }
        queueDB.markInProgress(localID: candidate.localID, collectionID: candidate.collectionID)
      } catch {
        queueDB.markFailed(
          localID: candidate.localID,
          collectionID: candidate.collectionID,
          errorMessage: error.localizedDescription
        )
      }
    }
  }

  private func resolvePrimaryImageResource(localID: String) -> PHAssetResource? {
    let assets = PHAsset.fetchAssets(withLocalIdentifiers: [localID], options: nil)
    guard let asset = assets.firstObject else {
      return nil
    }

    let resources = PHAssetResource.assetResources(for: asset)
    if let fullSize = resources.first(where: { $0.type == .fullSizePhoto }) {
      return fullSize
    }
    if let primary = resources.first(where: { $0.type == .photo }) {
      return primary
    }
    return resources.first(where: {
      switch $0.type {
      case .alternatePhoto, .adjustmentBasePhoto, .adjustmentData:
        return true
      default:
        return false
      }
    })
  }

  private func buildDestination(
    for resource: PHAssetResource,
    configuration: IOS26UploadConfiguration
  ) -> URLRequest? {
    let uploadURL = configuration.baseURL.appending(path: "/files/background-upload-resource")
    var request = URLRequest(url: uploadURL)
    request.httpMethod = "POST"
    request.setValue("Bearer \(configuration.authToken)", forHTTPHeaderField: "Authorization")
    request.setValue(resource.assetLocalIdentifier, forHTTPHeaderField: "X-Ente-Local-ID")
    request.setValue(resource.originalFilename, forHTTPHeaderField: "X-Ente-Filename")
    request.setValue("\(resource.type.rawValue)", forHTTPHeaderField: "X-Ente-Resource-Type")
    if let userID = configuration.userID {
      request.setValue("\(userID)", forHTTPHeaderField: "X-Ente-User-ID")
    }
    return request
  }
}
