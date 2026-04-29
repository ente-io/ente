/// Describes which photo library the app is centered around.
///
/// [enteGallery] is the signed-in Ente account experience, focused on photos
/// backed up to Ente.
///
/// [localGallery] is the no-account local-device experience, focused on photos
/// currently available on the device. This mode may still use the network for
/// account setup, updates, model downloads, or other non-account-gallery flows.
enum AppMode { enteGallery, localGallery }
