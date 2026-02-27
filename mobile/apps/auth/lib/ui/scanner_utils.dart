bool shouldHandleScanResult({
  required bool hasHandledResult,
  required String? scannedCode,
}) {
  if (hasHandledResult) {
    return false;
  }
  return scannedCode != null && scannedCode.trim().isNotEmpty;
}
