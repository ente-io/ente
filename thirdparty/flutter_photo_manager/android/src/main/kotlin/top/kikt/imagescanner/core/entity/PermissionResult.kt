package top.kikt.imagescanner.core.entity

enum class PermissionResult(val value: Int) {
  NotDetermined(0),
  Denied(2),
  Authorized(3),
}