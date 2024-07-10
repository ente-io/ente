package io.ente.photos.onnx_dart

import android.content.Context
import androidx.annotation.NonNull
import ai.onnxruntime.*
import java.util.EnumMap
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.*
import java.nio.FloatBuffer
import java.util.concurrent.ConcurrentHashMap
import android.util.Log
import java.io.File
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.concurrent.ConcurrentLinkedQueue

/** OnnxDartPlugin */
class OnnxDartPlugin: FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel

  private val TAG = OnnxDartPlugin::class.java.name


  private var faceOrtEnv: OrtEnvironment = OrtEnvironment.getEnvironment()
  private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())
  private val sessionMap = ConcurrentHashMap<ModelType, ModelState>()
  private lateinit var context: Context

  enum class ModelType {
    CLIP_TEXT, ClipImageEncoder, YOLOv5Face, MobileFaceNet
  }
  companion object {
    const val DEFAULT_SESSION_COUNT = 1
  }



  data class ModelState(
    var isInitialized: Boolean = false,
    val sessionAddresses: ConcurrentHashMap<Int, OrtSession> = ConcurrentHashMap(),
    // number of sessions that should have been created for given model
    var sessionsCount: Int = DEFAULT_SESSION_COUNT
  )

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "onnx_dart")
    channel.setMethodCallHandler(this)
    context = flutterPluginBinding.applicationContext
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }


  override fun onMethodCall(call: MethodCall, result: Result) {
    if (call.method == "getPlatformVersion") {
      result.success("Android ${android.os.Build.VERSION.RELEASE}")
    }   else if  (call.method ==  "init") {
      val modelType = call.argument<String>("modelType") ?: run {
        result.error("INVALID_ARGUMENT", "Model type is missing", null)
        return
      }
      val modelPath = call.argument<String>("modelPath") ?: run {
        result.error("INVALID_ARGUMENT", "Model path is missing", null)
        return
      }
      val sessionsCount = call.argument<Int>("sessionsCount") ?: DEFAULT_SESSION_COUNT
      init(ModelType.valueOf(modelType), modelPath, sessionsCount, result)
    }
     else if  (call.method ==  "release" ) {
      val modelType = call.argument<String>("modelType") ?: run {
        result.error("INVALID_ARGUMENT", "Model type is missing", null)
        return
      }
      release(ModelType.valueOf(modelType), result)
    }
    else if  (call.method ==  "predict" ) {
      val sessionAddress = call.argument<Int>("sessionAddress")
      val modelType = call.argument<String>("modelType") ?: run {
        result.error("INVALID_ARGUMENT", "Model type is missing", null)
        return
      }
      val inputDataArray = call.argument<FloatArray>("inputData")

      if (sessionAddress == null || inputDataArray == null) {
        result.error("INVALID_ARGUMENT", "Session address or input data is missing", null)
        return
      }
//      val inputDataArray = inputData.map { it.toFloat() }.toFloatArray()
      predict(ModelType.valueOf(modelType), sessionAddress, inputDataArray, result)
    } else {
      result.notImplemented()
    }
  }


  private fun readModelFile(modelPath: String): ByteArray {
    return File(modelPath).readBytes()
  }

  private fun init(modelType: ModelType, modelPath: String, sessionsCount: Int, result: Result) {
    Log.d(TAG, " v: $modelType, path: $modelPath, sessionsCount: $sessionsCount")
    scope.launch {
      val modelState: ModelState
      if (sessionMap.containsKey(modelType)) {
        modelState = sessionMap[modelType]!!
      } else {
        modelState = ModelState()
        sessionMap[modelType] = modelState
      }
      if (!modelState.isInitialized) {
        for (i in 0 until sessionsCount) {
          val session = createSession(faceOrtEnv, modelPath)
          if (session != null) {
            modelState.sessionAddresses[i] = session
          }
        }
        modelState.isInitialized = true
        modelState.sessionsCount = sessionsCount
        withContext(Dispatchers.Main) {
          Log.d("OnnxFlutterPlugin", "Model initialized: $modelType")
          result.success(true)
        }
      } else {
        withContext(Dispatchers.Main) {
          result.success(false)
        }
      }
    }
  }

  private fun release(modelType: ModelType, result: Result) {
    scope.launch {
      val modelState = sessionMap[modelType]
      modelState?.let {
        it.sessionAddresses.forEach { entry: Map.Entry<Int, OrtSession> ->
          entry.value.close()
        }
        it.sessionAddresses.clear()
        it.isInitialized = false
      }
      withContext(Dispatchers.Main) {
        result.success(true)
      }
    }
  }

  private fun predict(modelType: ModelType, sessionAddress: Int, inputData: FloatArray, result: Result) {
    scope.launch {
      val modelState = sessionMap[modelType]
      val session = modelState?.sessionAddresses?.get(sessionAddress)
      if (session == null) {
        withContext(Dispatchers.Main) {
          result.error("SESSION_NOT_FOUND", "Session not found for address: $sessionAddress", null)
        }
        return@launch
      }

      try {
        val env = OrtEnvironment.getEnvironment()
        val inputTensorShape = longArrayOf(1, 3, 640, 640)
        val inputTensor = OnnxTensor.createTensor(env, FloatBuffer.wrap(inputData), inputTensorShape)
        val inputs = mapOf("input" to inputTensor)
        val outputs = session.run(inputs)
        Log.d(TAG, "Output shape: ${outputs.size()}")
        val outputTensor = (outputs[0].value as Array<Array<FloatArray>>).get(0)
        val flatList = outputTensor.flattenToFloatArray()
        withContext(Dispatchers.Main) {
          result.success(flatList)
        }
        outputs.close()
        inputTensor.close()
      } catch (e: OrtException) {
        withContext(Dispatchers.Main) {
          result.error("PREDICTION_ERROR", "Error during prediction: ${e.message}", null)
        }
      }
    }
  }

  private fun createSession(env: OrtEnvironment, modalPath: String): OrtSession? {
    return env.createSession(modalPath, OrtSession.SessionOptions())
  }

  private fun releaseAllSessions() {
    sessionMap.forEach { (_, modelState) ->
      modelState.sessionAddresses.forEach { entry ->
        entry.value.close()
      }
      modelState.sessionAddresses.clear()
    }
    sessionMap.clear()
  }

  fun Array<Array<FloatArray>>.flatMapToFloatArray(): FloatArray {
    val outputSize = this.sumOf { it.sumOf { it.size } }
    val result = FloatArray(outputSize)
    var index = 0
    for (outer in this) {
      for (inner in outer) {
        for (value in inner) {
          result[index++] = value
        }
      }
    }
    return result
  }
  fun Array<FloatArray>.flattenToFloatArray(): FloatArray {
    val outputSize = this.sumOf { it.size }
    val result = FloatArray(outputSize)
    var index = 0
    for (inner in this) {
      for (value in inner) {
        result[index++] = value
      }
    }
    return result
  }
}
