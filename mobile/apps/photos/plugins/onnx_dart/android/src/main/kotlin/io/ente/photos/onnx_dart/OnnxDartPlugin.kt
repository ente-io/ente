package io.ente.photos.onnx_dart

import android.content.Context
import java.nio.IntBuffer
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
    ClipTextEncoder, ClipImageEncoder, YOLOv5Face, MobileFaceNet
  }
  companion object {
    const val DEFAULT_SESSION_COUNT = 1
    const val FACENET_SINGLE_INPUT_SIZE = 112*112*3
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
    when (call.method) {
      "getPlatformVersion" -> {
        var env = OrtEnvironment.getEnvironment()
        var OrtVersion = env.getVersion()
        Log.d(TAG, "Android: ${android.os.Build.VERSION.RELEASE}, OrtVersion: $OrtVersion")
        result.success("Android: ${android.os.Build.VERSION.RELEASE}, OrtVersion: $OrtVersion")
      }
      "init" -> {
        val modelType = call.argument<String>("modelType")
        val modelPath = call.argument<String>("modelPath")
        val sessionsCount = call.argument<Int>("sessionsCount") ?: DEFAULT_SESSION_COUNT

        if (modelType == null || modelPath == null) {
          result.error("INVALID_ARGUMENT", "Model type or path is missing", null)
          return
        }

        init(ModelType.valueOf(modelType), modelPath, sessionsCount, result)
      }
      "release" -> {
        val modelType = call.argument<String>("modelType")
        if (modelType == null) {
          result.error("INVALID_ARGUMENT", "Model type is missing", null)
          return
        }
        release(ModelType.valueOf(modelType), result)
      }
      "predict" -> {
        val sessionAddress = call.argument<Int>("sessionAddress")
        val modelType = call.argument<String>("modelType")
        val inputDataArray = call.argument<FloatArray>("inputData")
        val inputIntDataArray = call.argument<IntArray>("inputDataInt")
        val inputUint8DataArray = call.argument<ByteArray>("inputDataUint8")
        val inputShapeArray = call.argument<IntArray>("inputShapeList")

        if (sessionAddress == null || modelType == null || (inputDataArray == null && inputIntDataArray == null && inputUint8DataArray == null)) {
          result.error("INVALID_ARGUMENT", "Session address, model type, or input data is missing", null)
          return
        }

        predict(ModelType.valueOf(modelType), sessionAddress, inputDataArray, inputIntDataArray, inputUint8DataArray, inputShapeArray, result)
      }
      else -> {
        result.notImplemented()
      }
    }
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
          Log.d(TAG, "Model initialized: $modelType")
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

  private fun predict(modelType: ModelType, sessionAddress: Int, inputDataFloat: FloatArray? = null, inputDataInt: IntArray? = null, inputUint8DataArray: ByteArray? = null, inputShapeArray: IntArray? = null, result: Result) {
    assert((inputDataFloat != null).xor((inputDataInt != null).xor(inputUint8DataArray != null))) { "Exactly one of inputDataFloat, inputDataInt or inputUint8DataArray must be provided" }

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
        var inputTensorShape: LongArray = longArrayOf(1, 3, 640, 640)
        when (modelType) {
          ModelType.MobileFaceNet -> {
            val totalSize = inputDataFloat!!.size.toLong() / FACENET_SINGLE_INPUT_SIZE
            inputTensorShape = longArrayOf(totalSize, 112, 112, 3)
          }
          ModelType.ClipImageEncoder -> {
            inputTensorShape = longArrayOf(1, 3, 256, 256)
          }
          ModelType.ClipTextEncoder -> {
            inputTensorShape = longArrayOf(1, 77)
          }
          ModelType.YOLOv5Face -> {
            inputTensorShape = longArrayOf(1, 3, 640, 640)
          }
        }

        val inputTensor = when {
          inputDataFloat != null -> OnnxTensor.createTensor(env, FloatBuffer.wrap(inputDataFloat), inputTensorShape)
          inputDataInt != null -> OnnxTensor.createTensor(env, IntBuffer.wrap(inputDataInt), inputTensorShape)
          inputUint8DataArray != null -> OnnxTensor.createTensor(env, ByteBuffer.wrap(inputUint8DataArray), inputTensorShape, OnnxJavaType.UINT8)
          else -> throw IllegalArgumentException("No input data provided")
        }
        val inputs = mutableMapOf<String, OnnxTensor>()
        if (modelType == ModelType.MobileFaceNet) {
         inputs["img_inputs"] = inputTensor
        } else {
            inputs["input"] = inputTensor
        }
        val outputs = session.run(inputs)
        if (modelType == ModelType.YOLOv5Face) {
          val outputTensor = (outputs[0].value as Array<Array<FloatArray>>).get(0)
          val flatList = outputTensor.flattenToFloatArray()
          withContext(Dispatchers.Main) {
            result.success(flatList)
          }
        } else {
          val outputTensor = (outputs[0].value as Array<FloatArray>)
          val flatList = outputTensor.flattenToFloatArray()
          withContext(Dispatchers.Main) {
            result.success(flatList)
          }
        }

        outputs.close()
        inputTensor.close()
      } catch (e: OrtException) {
        withContext(Dispatchers.Main) {
          result.error("PREDICTION_ERROR", "Error during prediction: ${e.message} ${e.stackTraceToString()}", null)
        }
      } catch (e: Exception) {
        Log.e(TAG, "Error during prediction: ${e.message}", e)
        withContext(Dispatchers.Main) {
          result.error("UNHANDLED_ERROR", "Error during prediction: ${e.message}", null)
        }
      }
    }
  }

  private fun createSession(env: OrtEnvironment, modalPath: String): OrtSession? {
    val sessionOptions = OrtSession.SessionOptions()
    sessionOptions.setInterOpNumThreads(1)
    sessionOptions.setIntraOpNumThreads(1)
    sessionOptions.setOptimizationLevel(OrtSession.SessionOptions.OptLevel.ALL_OPT)
    return env.createSession(modalPath, sessionOptions)
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

  private fun Array<FloatArray>.flattenToFloatArray(): FloatArray {
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
