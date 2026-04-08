import "package:ente_contacts/contacts.dart" as contacts;
import "package:flutter/foundation.dart";
import "package:logging/logging.dart";
import "package:photos/core/configuration.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/contacts_changed_event.dart";
import "package:photos/service_locator.dart";

class PhotosContactsService {
  PhotosContactsService._privateConstructor()
      : _contacts = contacts.ContactsService(
          preferences: ServiceLocator.instance.prefs,
        );

  @visibleForTesting
  PhotosContactsService.forTesting({
    required contacts.ContactsService contactsService,
  }) : _contacts = contactsService;

  static final PhotosContactsService instance =
      PhotosContactsService._privateConstructor();

  final contacts.ContactsService _contacts;
  final _logger = Logger("PhotosContactsService");
  final Map<int, contacts.ContactRecord> _contactsByUserId = {};
  final Map<int, Uint8List?> _profilePictureBytesByUserId = {};
  final Set<int> _resolvedProfilePictureUserIds = {};
  final Map<int, Future<Uint8List?>> _profilePictureLoadsByUserId = {};

  Future<void>? _readyFuture;
  String? _sessionKey;
  String? _sessionAuthToken;
  bool _hasHydratedCache = false;

  bool get hasHydratedCache => _hasHydratedCache;

  Future<void> ensureReady() async {
    if (!flagService.enableContact) {
      _resetSessionState(notify: true);
      return;
    }
    final session = _buildSession();
    if (session == null) {
      _resetSessionState(notify: true);
      return;
    }
    final sessionKey = _buildSessionKey(session);
    if (_readyFuture != null && _sessionKey == sessionKey) {
      await _readyFuture;
      if (_sessionAuthToken != session.authToken) {
        await _contacts.updateAuthToken(session.authToken);
        _sessionAuthToken = session.authToken;
      }
      return;
    }
    if (_sessionKey != sessionKey) {
      _resetSessionState(notify: true);
    }
    _sessionKey = sessionKey;
    _sessionAuthToken = session.authToken;
    late final Future<void> readyFuture;
    readyFuture =
        _openAndSync(session).catchError((Object error, StackTrace stackTrace) {
      if (identical(_readyFuture, readyFuture)) {
        _readyFuture = null;
      }
      throw error;
    });
    _readyFuture = readyFuture;
    return readyFuture;
  }

  Future<contacts.ContactRecord?> getContactByUserId(int contactUserId) async {
    final cached = getCachedContactByUserId(contactUserId);
    if (cached != null) {
      return cached;
    }
    return _runReadSafely(
      () async {
        await ensureReady();
        final contact = await _contacts.getContactByUserId(contactUserId);
        if (contact == null || contact.isDeleted) {
          return null;
        }
        _cacheContact(contact);
        return contact;
      },
      description: "load contact for user $contactUserId",
    );
  }

  contacts.ContactRecord? getCachedContactByUserId(int? contactUserId) {
    if (contactUserId == null) {
      return null;
    }
    final contact = _contactsByUserId[contactUserId];
    if (contact == null || contact.isDeleted) {
      return null;
    }
    return contact;
  }

  String? getCachedSavedNameByUserId(int? contactUserId) {
    return getCachedContactByUserId(contactUserId)?.data?.name;
  }

  String? getCachedResolvedEmailByUserId(int? contactUserId) {
    return getCachedContactByUserId(contactUserId)?.email;
  }

  Uint8List? getCachedProfilePictureBytesByUserId(int? contactUserId) {
    if (contactUserId == null ||
        !_resolvedProfilePictureUserIds.contains(contactUserId)) {
      return null;
    }
    return _profilePictureBytesByUserId[contactUserId];
  }

  bool hasResolvedProfilePictureByUserId(int? contactUserId) {
    return contactUserId != null &&
        _resolvedProfilePictureUserIds.contains(contactUserId);
  }

  Future<Uint8List?> getProfilePictureBytesByUserId(int? contactUserId) async {
    if (contactUserId == null) {
      return null;
    }
    if (_resolvedProfilePictureUserIds.contains(contactUserId)) {
      return _profilePictureBytesByUserId[contactUserId];
    }
    final inflightLoad = _profilePictureLoadsByUserId[contactUserId];
    if (inflightLoad != null) {
      return inflightLoad;
    }
    final load = _loadProfilePictureBytesByUserId(contactUserId);
    _profilePictureLoadsByUserId[contactUserId] = load;
    return load.whenComplete(() {
      _profilePictureLoadsByUserId.remove(contactUserId);
    });
  }

  Future<Uint8List?> _loadProfilePictureBytesByUserId(int contactUserId) async {
    final contact = await getContactByUserId(contactUserId);
    final attachmentId = contact?.profilePictureAttachmentId;
    if (contact == null || attachmentId == null) {
      _profilePictureBytesByUserId.remove(contactUserId);
      _resolvedProfilePictureUserIds.add(contactUserId);
      return null;
    }
    final contactId = contact.id;
    try {
      final bytes = await _contacts.getProfilePicture(contactId);
      final latestContact = _contactsByUserId[contactUserId];
      if (latestContact == null ||
          latestContact.isDeleted ||
          latestContact.id != contactId ||
          latestContact.profilePictureAttachmentId != attachmentId) {
        return _profilePictureBytesByUserId[contactUserId];
      }
      _profilePictureBytesByUserId[contactUserId] = bytes;
      _resolvedProfilePictureUserIds.add(contactUserId);
      return bytes;
    } catch (e, s) {
      _logger.warning(
        "Failed to load contact profile picture for user $contactUserId",
        e,
        s,
      );
      return null;
    }
  }

  Future<contacts.ContactRecord> createOrUpdateContact({
    required int contactUserId,
    required String name,
    String? birthDate,
  }) async {
    await ensureReady();
    final trimmedName = name.trim();
    final trimmedBirthDate = birthDate?.trim();
    final normalizedBirthDate =
        trimmedBirthDate == null || trimmedBirthDate.isEmpty
            ? null
            : trimmedBirthDate;
    final existing = await _contacts.getContactByUserId(
      contactUserId,
      includeDeleted: true,
    );
    final data = contacts.ContactData(
      contactUserId: contactUserId,
      name: trimmedName,
      birthDate: normalizedBirthDate,
    );
    final contact = existing == null
        ? await _contacts.createContact(data)
        : await _contacts.updateContact(existing.id, data);
    _cacheContact(contact);
    _notifyChanged(contact);
    return contact;
  }

  Future<contacts.ContactRecord> setProfilePicture({
    required String contactId,
    required Uint8List bytes,
  }) async {
    await ensureReady();
    final contact = await _contacts.setProfilePicture(contactId, bytes);
    _cacheContact(contact);
    _profilePictureBytesByUserId[contact.contactUserId] = bytes;
    _resolvedProfilePictureUserIds.add(contact.contactUserId);
    _notifyChanged(contact);
    return contact;
  }

  @visibleForTesting
  Future<void> debugOpenAndSync(contacts.ContactsSession session) async {
    _sessionKey = _buildSessionKey(session);
    _sessionAuthToken = session.authToken;
    await _openAndSync(session);
  }

  @visibleForTesting
  void debugHydrateContacts(
    List<contacts.ContactRecord> contacts, {
    bool markHydrated = false,
  }) {
    for (final contact in contacts) {
      _cacheContact(contact);
    }
    if (markHydrated) {
      _hasHydratedCache = true;
    }
  }

  @visibleForTesting
  void debugReset({bool notify = false}) {
    _resetSessionState(notify: notify);
  }

  contacts.ContactsSession? _buildSession() {
    final config = Configuration.instance;
    final userId = config.getUserID();
    final accountKey = config.getKey();
    final token = config.getToken();
    if (token == null || userId == null || accountKey == null) {
      return null;
    }
    final packageInfo = ServiceLocator.instance.packageInfo;
    return contacts.ContactsSession(
      baseUrl: config.getHttpEndpoint(),
      authToken: token,
      userId: userId,
      accountKey: accountKey,
      clientPackage: packageInfo.packageName,
      clientVersion: packageInfo.version,
    );
  }

  String _buildSessionKey(contacts.ContactsSession session) {
    return "${session.baseUrl}|${session.userId}";
  }

  Future<void> _openAndSync(contacts.ContactsSession session) async {
    await _contacts.open(session);
    final cachedUserIdsBeforeHydration = _contactsByUserId.keys.toSet();
    final localContacts = await _hydrateCacheFromLocalDb();
    _hasHydratedCache = true;
    final newlyHydratedLocalUserIds = localContacts
        .map((contact) => contact.contactUserId)
        .where((userId) => !cachedUserIdsBeforeHydration.contains(userId))
        .toSet();
    final changedUserIds = <int>{...newlyHydratedLocalUserIds};
    var shouldRetrySync = false;
    try {
      final contactsDiff = await _contacts.sync();
      for (final contact in contactsDiff) {
        _invalidateProfilePictureCache(contact.contactUserId);
        _cacheContact(contact);
      }
      changedUserIds.addAll(
        contactsDiff.map((contact) => contact.contactUserId),
      );
    } catch (e, s) {
      shouldRetrySync = true;
      _logger.warning(
        "Failed to sync contacts after hydrating local cache",
        e,
        s,
      );
    }
    if (changedUserIds.isNotEmpty) {
      _notifyContactsChanged(changedUserIds);
    }
    if (shouldRetrySync && _sessionKey == _buildSessionKey(session)) {
      _readyFuture = null;
    }
  }

  void _notifyChanged(contacts.ContactRecord contact) {
    _notifyContactsChanged({contact.contactUserId});
  }

  void _notifyContactsChanged(Set<int>? contactUserIds) {
    Bus.instance.fire(ContactsChangedEvent(contactUserIds: contactUserIds));
  }

  Future<T?> _runReadSafely<T>(
    Future<T?> Function() task, {
    required String description,
  }) async {
    try {
      return await task();
    } on StateError catch (e, s) {
      if (_isRustInitializationError(e)) {
        _logger.warning(
          "Contacts integration unavailable while Rust bindings are not initialized during $description. Photos initializes EntePhotosRust in main.dart, but ente_contacts calls into package:ente_rust.",
          e,
          s,
        );
        return null;
      }
      rethrow;
    } catch (e, s) {
      _logger.warning("Failed to $description", e, s);
      return null;
    }
  }

  bool _isRustInitializationError(StateError error) {
    return error.message
        .contains("flutter_rust_bridge has not been initialized");
  }

  void _cacheContact(contacts.ContactRecord contact) {
    final userId = contact.contactUserId;
    if (contact.isDeleted) {
      _contactsByUserId.remove(userId);
      _invalidateProfilePictureCache(userId);
      return;
    }
    _contactsByUserId[userId] = contact;
  }

  Future<List<contacts.ContactRecord>> _hydrateCacheFromLocalDb() async {
    final localContacts = await _contacts.getContacts();
    for (final contact in localContacts) {
      _cacheContact(contact);
    }
    return localContacts;
  }

  void _resetSessionState({required bool notify}) {
    final hadCachedContacts = _contactsByUserId.isNotEmpty;
    _contactsByUserId.clear();
    _profilePictureBytesByUserId.clear();
    _resolvedProfilePictureUserIds.clear();
    _profilePictureLoadsByUserId.clear();
    _readyFuture = null;
    _sessionKey = null;
    _sessionAuthToken = null;
    _hasHydratedCache = false;
    if (notify && hadCachedContacts) {
      _notifyContactsChanged(null);
    }
  }

  void _invalidateProfilePictureCache(int contactUserId) {
    _profilePictureBytesByUserId.remove(contactUserId);
    _resolvedProfilePictureUserIds.remove(contactUserId);
    _profilePictureLoadsByUserId.remove(contactUserId);
  }
}
