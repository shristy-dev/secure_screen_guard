/// Security modes for [SecureScreenGuard].
enum SecurityMode {
  /// Always protected — FLAG_SECURE on Android, constant monitoring on iOS.
  strict,

  /// Only protects widgets explicitly wrapped with [SecureScreen].
  balanced,

  /// Disabled entirely.
  off,
}
