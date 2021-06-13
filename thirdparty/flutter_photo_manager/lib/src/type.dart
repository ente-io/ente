/// asset type
///
/// 用于资源类型属性
enum AssetType {
  /// not image or video
  ///
  /// 不是图片 也不是视频
  other,

  /// image
  image,

  /// video
  video,

  /// audio
  audio,
}

class RequestType {
  final int value;

  int get index => value;

  static const _imageValue = 1;
  static const _videoValue = 1 << 1;
  static const _audioValue = 1 << 2;

  static const image = RequestType(_imageValue);
  static const video = RequestType(_videoValue);
  static const audio = RequestType(_audioValue);
  static const all = RequestType(_imageValue | _videoValue | _audioValue);
  static const common = RequestType(_imageValue | _videoValue);

  const RequestType(this.value);

  bool containsImage() {
    return value & _imageValue == _imageValue;
  }

  bool containsVideo() {
    return value & _videoValue == _videoValue;
  }

  bool containsAudio() {
    return value & _audioValue == _audioValue;
  }

  bool containsType(RequestType type) {
    return this.value & type.value == type.value;
  }

  RequestType operator +(RequestType type) {
    return this | type;
  }

  RequestType operator -(RequestType type) {
    return this ^ type;
  }

  RequestType operator |(RequestType type) {
    return RequestType(this.value | type.value);
  }

  RequestType operator ^(RequestType type) {
    return RequestType(this.value ^ type.value);
  }

  RequestType operator >>(int bit) {
    return RequestType(this.value >> bit);
  }

  RequestType operator <<(int bit) {
    return RequestType(this.value << bit);
  }

  @override
  String toString() {
    return "Request type = $value";
  }
}

/// For generality, only support jpg and png.
enum ThumbFormat { jpeg, png }

enum DeliveryMode { opportunistic, highQualityFormat, fastFormat }

/// Resize strategy, useful when need exact image size. It's must be used only for iOS
/// [Apple resize mode documentation](https://developer.apple.com/documentation/photokit/phimagerequestoptions/1616988-resizemode?language=swift)
enum ResizeMode { none, fast, exact }

/// Resize content mode
enum ResizeContentMode { fit, fill, def }

/// Android: The effective values are [authorized] or [denied].
///
/// iOS/macOS: All values are valid.
///
/// See [document of Apple](https://developer.apple.com/documentation/photokit/phauthorizationstatus?language=objc)
enum PermissionState {
  /// The user hasn’t set the app’s authorization status.
  notDetermined,

  /// The app isn’t authorized to access the photo library, and the user can’t grant such permission.
  restricted,

  /// The user explicitly denied this app access to the photo library.
  denied,

  /// The user explicitly granted this app access to the photo library.
  authorized,

  /// The user authorized this app for limited photo library access.
  ///
  /// The state is only support iOS 14 or higher.
  limited,
}

/// See [PermissionState].
extension PermissionStateExt on PermissionState {
  /// Whether authorized or not.
  bool get isAuth {
    return this == PermissionState.authorized;
  }
}

class PermisstionRequestOption {
  final IosAccessLevel iosAccessLevel;

  const PermisstionRequestOption({
    this.iosAccessLevel = IosAccessLevel.readWrite,
  });

  Map toMap() {
    return {
      'iosAccessLevel': iosAccessLevel.getValue(),
    };
  }
}

enum IosAccessLevel {
  addOnly,
  readWrite,
}

extension on IosAccessLevel {
  int getValue() {
    switch (this) {
      case IosAccessLevel.addOnly:
        return 1;
      case IosAccessLevel.readWrite:
        return 2;
    }
  }
}
