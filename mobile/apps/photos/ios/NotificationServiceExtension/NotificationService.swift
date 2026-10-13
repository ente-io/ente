import Foundation
import UserNotifications

final class NotificationService: UNNotificationServiceExtension {
  override func didReceive(_ request: UNNotificationRequest,
    withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
    guard request.content.userInfo["notificationVersion"] != nil else {
      contentHandler(request.content)
      return
    }
    guard let content = request.content.mutableCopy() as? UNMutableNotificationContent else {
      contentHandler(request.content)
      return
    }
    content.title = "Ente Photos"
    content.subtitle = ""
    content.body = NSLocalizedString("notification.new_activity", value: "New activity", comment: "Generic notification fallback")
    let enabled = NotificationKeyStore.preferences.object(forKey: NotificationKeyStore.preferenceKey) as? Bool ?? false
    if enabled, request.content.userInfo["notificationVersion"] as? Int == 1,
      let ciphertext = request.content.userInfo["notificationCiphertext"] as? String,
      let recipient = try? NotificationKeyStore.read(),
      let payload = NotificationPayload.decrypt(ciphertext, recipient: recipient) {
      switch payload.eventType {
      case "album_shared":
        content.body = NSLocalizedString("notification.album_shared", value: "Someone shared an album with you", comment: "Album share notification")
      default:
        break
      }
    }
    contentHandler(content)
  }
}

struct NotificationPayload: Decodable {
  let version: Int
  let eventType: String

  static func decrypt(_ ciphertext: String, recipient: NotificationRecipient) -> Self? {
    guard recipient.isValid, sodium_init() >= 0,
      let ciphertext = Data(base64Encoded: ciphertext), ciphertext.count >= 48,
      let publicKeyString = recipient.publicKey,
      let publicKey = Data(base64Encoded: publicKeyString),
      let privateKey = Data(base64Encoded: recipient.privateKey)
    else { return nil }
    var plaintext = [UInt8](repeating: 0, count: ciphertext.count - 48)
    guard crypto_box_seal_open(&plaintext, Array(ciphertext), UInt64(ciphertext.count),
      Array(publicKey), Array(privateKey)) == 0,
      let payload = try? JSONDecoder().decode(Self.self, from: Data(plaintext)),
      payload.version == 1
    else { return nil }
    return payload
  }
}
