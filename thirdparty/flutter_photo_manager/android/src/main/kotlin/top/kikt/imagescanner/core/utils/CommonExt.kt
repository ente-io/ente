package top.kikt.imagescanner.core.utils

import android.os.Build
import android.os.Environment

fun belowSdk(int: Int): Boolean {
  return Build.VERSION.SDK_INT < int
}

/**
 * Whether to read the file path directly.
 *
 * When the sdk is 28 or lower, use file path
 *
 * When the sdk is 30,
 */
fun useFilePath(): Boolean {
  return if (Build.VERSION.SDK_INT <= 28) {
    true
  } else if (Build.VERSION.SDK_INT == 29) {
    Environment.isExternalStorageLegacy()
  } else {
    true
  }
}