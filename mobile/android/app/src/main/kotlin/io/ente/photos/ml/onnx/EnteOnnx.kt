package io.ente.photos.ml.onnx

import android.content.Context
import androidx.annotation.NonNull
import ai.onnxruntime.*
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
import java.util.concurrent.ConcurrentLinkedQueue

object LongArrayPool {
    private val pool = ConcurrentLinkedQueue<LongArray>()

    fun get(size: Int): LongArray {
        return pool.poll() ?: LongArray(size)
    }

    fun release(array: LongArray) {
        pool.offer(array)
    }
}

class EnteOnnxFlutterPlugin : FlutterPlugin, MethodCallHandler {
    private var faceOrtEnv: OrtEnvironment = OrtEnvironment.getEnvironment()
    private lateinit var channel: MethodChannel
    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private val sessionMap = ConcurrentHashMap<ModelType, ModelState>()
    private lateinit var context: Context

    companion object {
        const val DEFAULT_SESSION_COUNT = 1
        const val K_INPUT_WIDTH = 640
        const val K_INPUT_HEIGHT = 640
        const val K_NUM_CHANNELS = 3
    }

    enum class ModelType {
        CLIP_TEXT, CLIP_VISUAL, YOLO_FACE, MOBILENET_FACE
    }

    data class ModelState(
        var isInitialized: Boolean = false,
        val sessionAddresses: ConcurrentHashMap<Int, OrtSession> = ConcurrentHashMap(),
        // number of sessions that should have been created for given model
        var sessionsCount: Int = DEFAULT_SESSION_COUNT
    )

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "ente_onnx_flutter_plugin")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        releaseAllSessions()
        scope.cancel()
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "init" -> {
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
            "release" -> {
                val modelType = call.argument<String>("modelType") ?: run {
                    result.error("INVALID_ARGUMENT", "Model type is missing", null)
                    return
                }
                release(ModelType.valueOf(modelType), result)
            }
            "predict" -> {
                val sessionAddress = call.argument<Int>("sessionAddress")
                val inputData = call.argument<List<Double>>("inputData")
                val modelType = call.argument<String>("modelType") ?: run {
                    result.error("INVALID_ARGUMENT", "Model type is missing", null)
                    return
                }
                if (sessionAddress == null || inputData == null) {
                    result.error("INVALID_ARGUMENT", "Session address or input data is missing", null)
                    return
                }
                val inputDataArray = inputData.map { it.toFloat() }.toFloatArray()
                predict(ModelType.valueOf(modelType), sessionAddress, inputDataArray, result)
            }
            else -> result.notImplemented()
        }
    }

    private fun readModelFile(modelPath: String): ByteArray {
        return File(modelPath).readBytes()
    }

    private fun init(modelType: ModelType, modelPath: String, sessionsCount: Int, result: Result) {
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
                val inputTensorShape = LongArrayPool.get(4).apply {
                    this[0] = 1
                    this[1] = K_NUM_CHANNELS.toLong()
                    this[2] = K_INPUT_HEIGHT.toLong()
                    this[3] = K_INPUT_WIDTH.toLong()
                }
                val inputTensor = OnnxTensor.createTensor(env, FloatBuffer.wrap(inputData), inputTensorShape)
                val inputs = mapOf("input" to inputTensor)
                val outputs = session.run(inputs)
                Log.d("OnnxFlutterPlugin", "Output shape: ${outputs.size()}")

                inputTensor.close()
                outputs.close()
                LongArrayPool.release(inputTensorShape)
                withContext(Dispatchers.Main) {
                    val dummyResult = listOf(0.1, 0.2) // Replace with actual result processing
                    result.success(dummyResult)
                }
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
}
