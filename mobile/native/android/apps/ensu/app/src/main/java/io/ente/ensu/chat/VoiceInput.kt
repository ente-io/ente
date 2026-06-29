package io.ente.ensu.chat

import android.annotation.SuppressLint
import android.content.Context
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.util.Log
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import io.ente.ensu.bindings.TranscriptionException
import io.ente.ensu.bindings.TranscriptionModelEvent
import io.ente.ensu.bindings.TranscriptionModelEventCallback
import io.ente.ensu.bindings.downloadTranscriptionModel
import io.ente.ensu.bindings.isTranscriptionModelDownloaded
import io.ente.ensu.bindings.loadTranscriptionModel
import io.ente.ensu.bindings.transcribePcm16
import io.ente.ensu.bindings.uniffiEnsureInitialized
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.ByteArrayOutputStream
import java.io.IOException
import kotlin.coroutines.coroutineContext
import kotlin.math.roundToInt

internal sealed interface VoiceInputState {
    data object Idle : VoiceInputState
    data object Recording : VoiceInputState
    data class Downloading(val percent: Int?) : VoiceInputState
    data object Transcribing : VoiceInputState
    data class Error(val message: String) : VoiceInputState
}

internal val VoiceInputState.isRecording: Boolean
    get() = this is VoiceInputState.Recording

internal val VoiceInputState.isWorking: Boolean
    get() = this is VoiceInputState.Recording ||
        this is VoiceInputState.Downloading ||
        this is VoiceInputState.Transcribing

internal val VoiceInputState.blocksSend: Boolean
    get() = this is VoiceInputState.Recording ||
        this is VoiceInputState.Transcribing

internal fun VoiceInputState.statusText(): String? = when (this) {
    VoiceInputState.Idle -> null
    VoiceInputState.Recording -> "Listening..."
    is VoiceInputState.Downloading -> {
        val suffix = percent?.let { " ($it%)" } ?: ""
        "Downloading voice model...$suffix"
    }
    VoiceInputState.Transcribing -> null
    is VoiceInputState.Error -> message
}

@Composable
internal fun rememberVoiceTranscriptionController(
    onTranscript: (String) -> Unit
): VoiceTranscriptionController {
    val context = LocalContext.current.applicationContext
    val lifecycleOwner = LocalLifecycleOwner.current
    val controller = remember(context) {
        VoiceTranscriptionController(context, onTranscript)
    }
    DisposableEffect(controller, lifecycleOwner) {
        val observer = LifecycleEventObserver { _, event ->
            if (event == Lifecycle.Event.ON_PAUSE) {
                controller.cancelActiveVoiceInput()
            }
        }
        lifecycleOwner.lifecycle.addObserver(observer)
        onDispose {
            lifecycleOwner.lifecycle.removeObserver(observer)
        }
    }
    DisposableEffect(controller) {
        onDispose { controller.dispose() }
    }
    return controller
}

internal class VoiceTranscriptionController(
    private val appContext: Context,
    private val onTranscript: (String) -> Unit
) {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    private val bufferLock = Any()
    private val modelsDir = appContext.getDir("ensu_transcription_models", Context.MODE_PRIVATE)

    private var audioRecord: AudioRecord? = null
    private var preparingRecordingJob: Job? = null
    private var recordingJob: Job? = null
    private var transcriptionPreloadJob: Job? = null
    private var transientErrorJob: Job? = null
    private var recordedPcm = ByteArrayOutputStream()
    private var recordingSampleRate = preferredSampleRate

    var state: VoiceInputState by mutableStateOf(VoiceInputState.Idle)
        private set

    fun onPermissionDenied() {
        state = VoiceInputState.Error("Microphone permission is required for voice input.")
    }

    @SuppressLint("MissingPermission")
    fun startRecording(canStartRecording: () -> Boolean = { true }) {
        transientErrorJob?.cancel()
        if (state.isWorking || preparingRecordingJob?.isActive == true) {
            return
        }

        preparingRecordingJob = scope.launch {
            try {
                ensureTranscriptionModelDownloaded()
                if (!isActive || !canStartRecording()) {
                    if (state is VoiceInputState.Downloading) {
                        state = VoiceInputState.Idle
                    }
                    return@launch
                }
                beginRecording()
                preloadTranscriptionModel()
            } catch (error: CancellationException) {
                throw error
            } catch (error: UnsatisfiedLinkError) {
                Log.w(TAG, "Voice transcription is not available on this device", error)
                state = VoiceInputState.Error("Voice transcription is not available on this device.")
            } catch (error: TranscriptionException) {
                Log.w(TAG, "Voice model preparation failed: ${error.message}", error)
                state = VoiceInputState.Error(transcriptionErrorMessage(error.message))
            } catch (error: Throwable) {
                Log.w(
                    TAG,
                    "Voice model preparation failed: ${error.javaClass.simpleName}: ${error.message}",
                    error
                )
                state = VoiceInputState.Error(transcriptionErrorMessage(error.message))
            }
        }
    }

    @SuppressLint("MissingPermission")
    private fun beginRecording() {
        if (state is VoiceInputState.Recording || state is VoiceInputState.Transcribing) {
            return
        }

        synchronized(bufferLock) {
            recordedPcm = ByteArrayOutputStream()
        }
        recordingSampleRate = preferredSampleRate
        state = VoiceInputState.Recording

        recordingJob = scope.launch(Dispatchers.IO) {
            var recorder: AudioRecord? = null
            try {
                val activeRecorder = createRecorder(recordingSampleRate)
                recorder = activeRecorder
                audioRecord = activeRecorder
                recordingSampleRate = activeRecorder.sampleRate.takeIf { it > 0 } ?: preferredSampleRate
                activeRecorder.startRecording()
                val buffer = ByteArray(readBufferSize(recordingSampleRate))
                while (coroutineContext.isActive) {
                    val read = activeRecorder.read(buffer, 0, buffer.size)
                    when {
                        read > 0 -> synchronized(bufferLock) {
                            recordedPcm.write(buffer, 0, read)
                        }
                        read < 0 -> throw IOException("Audio recorder failed with code $read")
                    }
                }
            } catch (error: Throwable) {
                if (error is CancellationException) {
                    throw error
                }
                Log.w(TAG, "Could not record microphone audio", error)
                withContext(Dispatchers.Main.immediate) {
                    if (state is VoiceInputState.Recording) {
                        state = VoiceInputState.Error("Could not record microphone audio.")
                    }
                }
            } finally {
                runCatching {
                    if (recorder?.recordingState == AudioRecord.RECORDSTATE_RECORDING) {
                        recorder.stop()
                    }
                }
                recorder?.release()
                if (audioRecord === recorder) {
                    audioRecord = null
                }
            }
        }
    }

    fun stopAndTranscribe() {
        if (state !is VoiceInputState.Recording) {
            return
        }

        state = VoiceInputState.Transcribing
        preparingRecordingJob?.cancel()
        preparingRecordingJob = null
        scope.launch {
            recordingJob?.cancelAndJoin()
            recordingJob = null

            val pcm = synchronized(bufferLock) { recordedPcm.toByteArray() }
            if (pcm.size < minimumRecordingBytes(recordingSampleRate)) {
                showTransientError("No speech captured.")
                return@launch
            }

            transcribeRecording(pcm, recordingSampleRate)
        }
    }

    fun cancelActiveVoiceInput() {
        val wasPreparingRecording = preparingRecordingJob?.isActive == true
        preparingRecordingJob?.cancel()
        preparingRecordingJob = null

        if (state !is VoiceInputState.Recording) {
            if (wasPreparingRecording && state is VoiceInputState.Downloading) {
                state = VoiceInputState.Idle
            }
            return
        }

        state = VoiceInputState.Idle
        recordingJob?.cancel()
        recordingJob = null
        stopActiveRecorder()
        synchronized(bufferLock) {
            recordedPcm.reset()
        }
    }

    fun dispose() {
        transientErrorJob?.cancel()
        preparingRecordingJob?.cancel()
        scope.cancel()
        runCatching {
            audioRecord?.release()
        }
        audioRecord = null
    }

    private suspend fun transcribeRecording(pcm: ByteArray, sampleRate: Int) {
        try {
            ensureTranscriptionModelDownloaded()
            awaitTranscriptionModelPreload()
            val transcript = withContext(Dispatchers.IO) {
                uniffiEnsureInitialized()

                withContext(Dispatchers.Main.immediate) {
                    state = VoiceInputState.Transcribing
                }
                transcribePcm16(
                    modelsDir.absolutePath,
                    modelsDir.absolutePath,
                    sampleRate.toUInt(),
                    pcm
                )
            }.trim()

            if (transcript.isBlank()) {
                showTransientError("No speech detected.")
            } else {
                onTranscript(transcript)
                state = VoiceInputState.Idle
            }
        } catch (error: CancellationException) {
            throw error
        } catch (error: UnsatisfiedLinkError) {
            Log.w(TAG, "Voice transcription is not available on this device", error)
            state = VoiceInputState.Error("Voice transcription is not available on this device.")
        } catch (error: TranscriptionException) {
            Log.w(TAG, "Voice transcription failed: ${error.message}", error)
            state = VoiceInputState.Error(transcriptionErrorMessage(error.message))
        } catch (error: Throwable) {
            Log.w(
                TAG,
                "Voice transcription failed: ${error.javaClass.simpleName}: ${error.message}",
                error
            )
            state = VoiceInputState.Error(transcriptionErrorMessage(error.message))
        }
    }

    private fun preloadTranscriptionModel() {
        transcriptionPreloadJob?.cancel()
        transcriptionPreloadJob = scope.launch(Dispatchers.IO) {
            try {
                uniffiEnsureInitialized()
                loadTranscriptionModel(modelsDir.absolutePath)
            } catch (error: CancellationException) {
                throw error
            } catch (error: Throwable) {
                Log.w(TAG, "Voice model preload failed", error)
            }
        }
    }

    private suspend fun awaitTranscriptionModelPreload() {
        val preloadJob = transcriptionPreloadJob ?: return
        try {
            preloadJob.join()
        } finally {
            if (transcriptionPreloadJob == preloadJob) {
                transcriptionPreloadJob = null
            }
        }
    }

    private suspend fun ensureTranscriptionModelDownloaded() {
        withContext(Dispatchers.IO) {
            val activeJob = coroutineContext[Job]
            uniffiEnsureInitialized()

            if (isTranscriptionModelDownloaded(modelsDir.absolutePath)) {
                return@withContext
            }

            setStateIfJobActive(activeJob, VoiceInputState.Downloading(null))
            downloadTranscriptionModel(
                modelsDir.absolutePath,
                object : TranscriptionModelEventCallback {
                    override fun onEvent(event: TranscriptionModelEvent) {
                        when (event) {
                            is TranscriptionModelEvent.DownloadProgress -> {
                                val percent = event.percentage
                                    .roundToInt()
                                    .coerceIn(0, 100)
                                postStateIfJobActive(
                                    activeJob,
                                    VoiceInputState.Downloading(percent)
                                )
                            }
                            TranscriptionModelEvent.ExtractionStarted -> {
                                postStateIfJobActive(
                                    activeJob,
                                    VoiceInputState.Downloading(100)
                                )
                            }
                            TranscriptionModelEvent.ExtractionCompleted,
                            TranscriptionModelEvent.DownloadComplete -> Unit
                            is TranscriptionModelEvent.DownloadError -> {
                                Log.w(
                                    TAG,
                                    "Voice model download failed: ${event.message}"
                                )
                                postStateIfJobActive(
                                    activeJob,
                                    VoiceInputState.Error(downloadErrorMessage())
                                )
                            }
                        }
                    }
                }
            )
        }
    }

    private suspend fun setStateIfJobActive(activeJob: Job?, nextState: VoiceInputState) {
        if (activeJob?.isActive == false) {
            return
        }
        withContext(Dispatchers.Main.immediate) {
            if (activeJob?.isActive != false) {
                state = nextState
            }
        }
    }

    private fun postStateIfJobActive(activeJob: Job?, nextState: VoiceInputState) {
        if (activeJob?.isActive == false) {
            return
        }
        scope.launch(Dispatchers.Main.immediate) {
            if (activeJob?.isActive != false) {
                state = nextState
            }
        }
    }

    private fun stopActiveRecorder() {
        val recorder = audioRecord ?: return
        runCatching {
            if (recorder.recordingState == AudioRecord.RECORDSTATE_RECORDING) {
                recorder.stop()
            }
        }
    }

    @SuppressLint("MissingPermission")
    private fun createRecorder(sampleRate: Int): AudioRecord {
        val minBufferSize = AudioRecord.getMinBufferSize(
            sampleRate,
            AudioFormat.CHANNEL_IN_MONO,
            AudioFormat.ENCODING_PCM_16BIT
        )
        if (minBufferSize <= 0) {
            throw IOException("Audio recorder buffer unavailable")
        }

        return AudioRecord.Builder()
            .setAudioSource(MediaRecorder.AudioSource.VOICE_RECOGNITION)
            .setAudioFormat(
                AudioFormat.Builder()
                    .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                    .setSampleRate(sampleRate)
                    .setChannelMask(AudioFormat.CHANNEL_IN_MONO)
                    .build()
            )
            .setBufferSizeInBytes(minBufferSize * 2)
            .build()
            .also { recorder ->
                if (recorder.state != AudioRecord.STATE_INITIALIZED) {
                    recorder.release()
                    throw IOException("Audio recorder failed to initialize")
                }
            }
    }

    private fun readBufferSize(sampleRate: Int): Int {
        val minBufferSize = AudioRecord.getMinBufferSize(
            sampleRate,
            AudioFormat.CHANNEL_IN_MONO,
            AudioFormat.ENCODING_PCM_16BIT
        )
        return maxOf(minBufferSize, 4096)
    }

    private fun minimumRecordingBytes(sampleRate: Int): Int = sampleRate / 4 * bytesPerSample

    private fun downloadErrorMessage(): String =
        "Voice model download failed. Check your connection and try again."

    private fun transcriptionErrorMessage(message: String?): String {
        val lowerMessage = message.orEmpty().lowercase()
        return when {
            lowerMessage.contains("download") ||
                lowerMessage.contains("http") ||
                lowerMessage.contains("request") ||
                lowerMessage.contains("connection") ||
                lowerMessage.contains("network") ||
                lowerMessage.contains("dns") ||
                lowerMessage.contains("certificate") ||
                lowerMessage.contains("tls") -> downloadErrorMessage()
            lowerMessage.contains("model") -> "Voice model could not be loaded."
            lowerMessage.contains("vad") -> "Could not detect speech in this recording."
            else -> "Could not transcribe voice input."
        }
    }

    private fun showTransientError(message: String) {
        val errorState = VoiceInputState.Error(message)
        transientErrorJob?.cancel()
        state = errorState
        transientErrorJob = scope.launch {
            delay(transientErrorMillis)
            if (state == errorState) {
                state = VoiceInputState.Idle
            }
        }
    }

    private companion object {
        const val TAG = "VoiceInput"
        const val preferredSampleRate = 16_000
        const val bytesPerSample = 2
        const val transientErrorMillis = 10_000L
    }
}
