enum TwoFactorType { totp, passkey }

// ToString for TwoFactorType
String twoFactorTypeToString(TwoFactorType type) {
  switch (type) {
    case TwoFactorType.totp:
      return "totp";
    case TwoFactorType.passkey:
      return "passkey";
  }
}
