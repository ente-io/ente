package top.kikt.imagescanner

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry.RequestPermissionsResultListener
import top.kikt.imagescanner.core.PhotoManagerPlugin
import top.kikt.imagescanner.permission.PermissionsUtils

class ImageScannerPlugin : FlutterPlugin, ActivityAware {
  private var plugin: PhotoManagerPlugin? = null
  private val permissionsUtils = PermissionsUtils()

  private var binding: ActivityPluginBinding? = null

  private var requestPermissionsResultListener: RequestPermissionsResultListener? = null

  companion object {
    fun register(plugin: PhotoManagerPlugin, messenger: BinaryMessenger) {
      val newChannel = MethodChannel(messenger, "top.kikt/photo_manager")
      newChannel.setMethodCallHandler(plugin)
    }

    fun createAddRequestPermissionsResultListener(permissionsUtils: PermissionsUtils): RequestPermissionsResultListener {
      return RequestPermissionsResultListener { id, permissions, grantResults ->
        permissionsUtils.dealResult(id, permissions, grantResults)
        false
      }
    }
  }

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    plugin = PhotoManagerPlugin(binding.applicationContext, binding.binaryMessenger, null, permissionsUtils)
    register(plugin!!, binding.binaryMessenger)
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    plugin = null
  }

  override fun onDetachedFromActivity() {
    binding?.let {
      onRemoveRequestPermissionResultListener(it)
    }
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activityAttached(binding)
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activityAttached(binding)
  }

  override fun onDetachedFromActivityForConfigChanges() {
    plugin?.bindActivity(null)
  }

  private fun activityAttached(binding: ActivityPluginBinding) {
    if (this.binding != null) {
      onRemoveRequestPermissionResultListener(this.binding!!)
    }

    this.binding = binding
    plugin?.bindActivity(binding.activity)
    addRequestPermissionsResultListener(binding)
  }

  private fun addRequestPermissionsResultListener(binding: ActivityPluginBinding) {
    val listener = createAddRequestPermissionsResultListener(permissionsUtils)
    requestPermissionsResultListener = listener
    binding.addRequestPermissionsResultListener(listener)
    plugin?.let {
      binding.addActivityResultListener(it.deleteManager)
    }
  }

  private fun onRemoveRequestPermissionResultListener(oldBinding: ActivityPluginBinding) {
    requestPermissionsResultListener?.let { listener ->
      oldBinding.removeRequestPermissionsResultListener(listener)
    }
    plugin?.let { p ->
      oldBinding.removeActivityResultListener(p.deleteManager)
    }
  }
}

enum class AssetType {
  Image,
  Video,
  Audio,
}