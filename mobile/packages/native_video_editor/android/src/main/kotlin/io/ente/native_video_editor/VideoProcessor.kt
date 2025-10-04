package io.ente.native_video_editor

import android.media.*
import android.opengl.*
import android.os.Build
import android.view.Surface
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.FloatBuffer
import javax.microedition.khronos.egl.EGL10
import javax.microedition.khronos.egl.EGLConfig
import javax.microedition.khronos.egl.EGLContext
import javax.microedition.khronos.egl.EGLDisplay
import javax.microedition.khronos.egl.EGLSurface

class VideoProcessor {
    private var egl: EGL10? = null
    private var eglDisplay: EGLDisplay? = null
    private var eglContext: EGLContext? = null
    private var eglSurface: EGLSurface? = null
    private var surface: Surface? = null

    private var textureId: Int = 0
    private var shaderProgram: Int = 0

    companion object {
        private const val FLOAT_SIZE_BYTES = 4

        // Vertex shader with transform matrix for cropping
        private const val VERTEX_SHADER = """
            attribute vec4 aPosition;
            attribute vec2 aTexCoord;
            uniform mat4 uTransform;
            varying vec2 vTexCoord;
            void main() {
                gl_Position = uTransform * aPosition;
                vTexCoord = aTexCoord;
            }
        """

        // Fragment shader for texture sampling
        private const val FRAGMENT_SHADER = """
            #extension GL_OES_EGL_image_external : require
            precision mediump float;
            varying vec2 vTexCoord;
            uniform samplerExternalOES uTexture;
            void main() {
                gl_FragColor = texture2D(uTexture, vTexCoord);
            }
        """
    }

    fun processVideoWithCrop(
        inputPath: String,
        outputPath: String,
        cropX: Int,
        cropY: Int,
        cropWidth: Int,
        cropHeight: Int
    ) {
        val extractor = MediaExtractor()
        extractor.setDataSource(inputPath)

        // Find video track
        var videoTrackIndex = -1
        var videoFormat: MediaFormat? = null

        for (i in 0 until extractor.trackCount) {
            val format = extractor.getTrackFormat(i)
            val mime = format.getString(MediaFormat.KEY_MIME)
            if (mime?.startsWith("video/") == true) {
                videoTrackIndex = i
                videoFormat = format
                extractor.selectTrack(i)
                break
            }
        }

        if (videoTrackIndex == -1 || videoFormat == null) {
            throw Exception("No video track found")
        }

        // Get original dimensions
        val originalWidth = videoFormat.getInteger(MediaFormat.KEY_WIDTH)
        val originalHeight = videoFormat.getInteger(MediaFormat.KEY_HEIGHT)
        val rotation = if (videoFormat.containsKey(MediaFormat.KEY_ROTATION)) {
            videoFormat.getInteger(MediaFormat.KEY_ROTATION)
        } else {
            0
        }

        // Handle rotation for display dimensions
        val (displayWidth, displayHeight) = when (rotation) {
            90, 270 -> originalHeight to originalWidth
            else -> originalWidth to originalHeight
        }

        // Validate crop parameters
        if (cropX < 0 || cropY < 0 ||
            cropX + cropWidth > displayWidth ||
            cropY + cropHeight > displayHeight) {
            throw IllegalArgumentException("Invalid crop parameters")
        }

        // Setup decoder
        val mime = videoFormat.getString(MediaFormat.KEY_MIME)!!
        val decoder = MediaCodec.createDecoderByType(mime)

        // Create surface texture for decoder output
        val surfaceTexture = createSurfaceTexture()
        val decoderSurface = Surface(surfaceTexture)

        // Setup encoder
        val outputFormat = MediaFormat.createVideoFormat("video/avc", cropWidth, cropHeight).apply {
            setInteger(MediaFormat.KEY_COLOR_FORMAT, MediaCodecInfo.CodecCapabilities.COLOR_FormatSurface)
            setInteger(MediaFormat.KEY_BIT_RATE, videoFormat.getInteger(MediaFormat.KEY_BIT_RATE))
            setInteger(MediaFormat.KEY_FRAME_RATE, 30)
            setInteger(MediaFormat.KEY_I_FRAME_INTERVAL, 1)
        }

        val encoder = MediaCodec.createEncoderByType("video/avc")
        encoder.configure(outputFormat, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
        val encoderSurface = encoder.createInputSurface()
        encoder.start()

        // Initialize OpenGL
        initOpenGL(encoderSurface)

        // Configure decoder
        decoder.configure(videoFormat, decoderSurface, null, 0)
        decoder.start()

        // Setup muxer
        val muxer = MediaMuxer(outputPath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
        var muxerTrackIndex = -1
        var muxerStarted = false

        // Process audio
        val audioExtractor = MediaExtractor()
        audioExtractor.setDataSource(inputPath)
        var audioMuxerTrackIndex = -1

        for (i in 0 until audioExtractor.trackCount) {
            val format = audioExtractor.getTrackFormat(i)
            val mime = format.getString(MediaFormat.KEY_MIME)
            if (mime?.startsWith("audio/") == true) {
                audioExtractor.selectTrack(i)
                audioMuxerTrackIndex = muxer.addTrack(format)
                break
            }
        }

        // Calculate crop transform matrix
        val cropMatrix = calculateCropMatrix(
            originalWidth.toFloat(), originalHeight.toFloat(),
            cropX.toFloat(), cropY.toFloat(),
            cropWidth.toFloat(), cropHeight.toFloat(),
            rotation
        )

        // Process video
        processFrames(
            decoder, encoder, extractor, muxer,
            surfaceTexture, cropMatrix,
            { index -> muxerTrackIndex = index; muxerStarted = true },
            muxerStarted
        )

        // Process audio
        if (audioMuxerTrackIndex >= 0 && muxerStarted) {
            processAudioTrack(audioExtractor, muxer, audioMuxerTrackIndex)
        }

        // Cleanup
        decoder.stop()
        decoder.release()
        encoder.stop()
        encoder.release()
        extractor.release()
        audioExtractor.release()
        muxer.stop()
        muxer.release()
        decoderSurface.release()
        surfaceTexture.release()
        cleanupOpenGL()
    }

    private fun createSurfaceTexture(): android.graphics.SurfaceTexture {
        val textures = IntArray(1)
        GLES20.glGenTextures(1, textures, 0)
        textureId = textures[0]

        GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, textureId)
        GLES20.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_LINEAR)
        GLES20.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_LINEAR)
        GLES20.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GLES20.GL_TEXTURE_WRAP_S, GLES20.GL_CLAMP_TO_EDGE)
        GLES20.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GLES20.GL_TEXTURE_WRAP_T, GLES20.GL_CLAMP_TO_EDGE)

        return android.graphics.SurfaceTexture(textureId)
    }

    private fun initOpenGL(surface: Surface) {
        egl = EGLContext.getEGL() as EGL10
        eglDisplay = egl!!.eglGetDisplay(EGL10.EGL_DEFAULT_DISPLAY)

        val version = IntArray(2)
        egl!!.eglInitialize(eglDisplay, version)

        val attribList = intArrayOf(
            EGL10.EGL_RED_SIZE, 8,
            EGL10.EGL_GREEN_SIZE, 8,
            EGL10.EGL_BLUE_SIZE, 8,
            EGL10.EGL_ALPHA_SIZE, 8,
            EGL10.EGL_RENDERABLE_TYPE, 4, // EGL_OPENGL_ES2_BIT
            EGL10.EGL_NONE
        )

        val configs = arrayOfNulls<EGLConfig>(1)
        val numConfig = IntArray(1)
        egl!!.eglChooseConfig(eglDisplay, attribList, configs, configs.size, numConfig)

        val contextAttribs = intArrayOf(
            0x3098, 2, // EGL_CONTEXT_CLIENT_VERSION, 2
            EGL10.EGL_NONE
        )

        eglContext = egl!!.eglCreateContext(eglDisplay, configs[0], EGL10.EGL_NO_CONTEXT, contextAttribs)
        eglSurface = egl!!.eglCreateWindowSurface(eglDisplay, configs[0], surface, null)

        egl!!.eglMakeCurrent(eglDisplay, eglSurface, eglSurface, eglContext)

        // Setup shaders
        setupShaders()
    }

    private fun setupShaders() {
        val vertexShader = loadShader(GLES20.GL_VERTEX_SHADER, VERTEX_SHADER)
        val fragmentShader = loadShader(GLES20.GL_FRAGMENT_SHADER, FRAGMENT_SHADER)

        shaderProgram = GLES20.glCreateProgram()
        GLES20.glAttachShader(shaderProgram, vertexShader)
        GLES20.glAttachShader(shaderProgram, fragmentShader)
        GLES20.glLinkProgram(shaderProgram)

        val linkStatus = IntArray(1)
        GLES20.glGetProgramiv(shaderProgram, GLES20.GL_LINK_STATUS, linkStatus, 0)
        if (linkStatus[0] != GLES20.GL_TRUE) {
            throw RuntimeException("Could not link program: ${GLES20.glGetProgramInfoLog(shaderProgram)}")
        }
    }

    private fun loadShader(type: Int, shaderCode: String): Int {
        val shader = GLES20.glCreateShader(type)
        GLES20.glShaderSource(shader, shaderCode)
        GLES20.glCompileShader(shader)

        val compileStatus = IntArray(1)
        GLES20.glGetShaderiv(shader, GLES20.GL_COMPILE_STATUS, compileStatus, 0)
        if (compileStatus[0] != GLES20.GL_TRUE) {
            throw RuntimeException("Could not compile shader $type: ${GLES20.glGetShaderInfoLog(shader)}")
        }

        return shader
    }

    private fun calculateCropMatrix(
        videoWidth: Float,
        videoHeight: Float,
        cropX: Float,
        cropY: Float,
        cropWidth: Float,
        cropHeight: Float,
        rotation: Int
    ): FloatArray {
        // Calculate normalized crop coordinates (0 to 1)
        val normalizedCropX = cropX / videoWidth
        val normalizedCropY = cropY / videoHeight
        val normalizedCropWidth = cropWidth / videoWidth
        val normalizedCropHeight = cropHeight / videoHeight

        // Create transform matrix
        val matrix = FloatArray(16)
        Matrix.setIdentityM(matrix, 0)

        // Scale to crop size
        Matrix.scaleM(matrix, 0, normalizedCropWidth, normalizedCropHeight, 1f)

        // Translate to crop position
        Matrix.translateM(matrix, 0,
            -normalizedCropX * 2f - normalizedCropWidth + 1f,
            -normalizedCropY * 2f - normalizedCropHeight + 1f,
            0f)

        // Apply rotation if needed
        if (rotation != 0) {
            Matrix.rotateM(matrix, 0, rotation.toFloat(), 0f, 0f, 1f)
        }

        return matrix
    }

    private fun processFrames(
        decoder: MediaCodec,
        encoder: MediaCodec,
        extractor: MediaExtractor,
        muxer: MediaMuxer,
        surfaceTexture: android.graphics.SurfaceTexture,
        cropMatrix: FloatArray,
        onEncoderFormatChanged: (Int) -> Unit,
        isMuxerStarted: Boolean
    ) {
        val bufferInfo = MediaCodec.BufferInfo()
        var inputDone = false
        var outputDone = false
        var muxerStarted = isMuxerStarted
        var encoderTrackIndex = -1

        while (!outputDone) {
            // Feed input to decoder
            if (!inputDone) {
                val inputBufferIndex = decoder.dequeueInputBuffer(10000)
                if (inputBufferIndex >= 0) {
                    val inputBuffer = decoder.getInputBuffer(inputBufferIndex)!!
                    val sampleSize = extractor.readSampleData(inputBuffer, 0)

                    if (sampleSize < 0) {
                        decoder.queueInputBuffer(inputBufferIndex, 0, 0, 0, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
                        inputDone = true
                    } else {
                        val sampleTime = extractor.sampleTime
                        decoder.queueInputBuffer(inputBufferIndex, 0, sampleSize, sampleTime, 0)
                        extractor.advance()
                    }
                }
            }

            // Process decoder output
            val decoderOutputIndex = decoder.dequeueOutputBuffer(bufferInfo, 10000)
            if (decoderOutputIndex >= 0) {
                val doRender = bufferInfo.size != 0
                decoder.releaseOutputBuffer(decoderOutputIndex, doRender)

                if (doRender) {
                    // Wait for new frame
                    surfaceTexture.updateTexImage()

                    // Render to encoder surface with crop transform
                    renderFrame(cropMatrix)

                    // Present to encoder
                    // Note: We skip presentation time setting as it requires EGL14
                    egl!!.eglSwapBuffers(eglDisplay, eglSurface)
                }

                if (bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) {
                    encoder.signalEndOfInputStream()
                }
            }

            // Process encoder output
            val encoderOutputIndex = encoder.dequeueOutputBuffer(bufferInfo, 10000)
            when {
                encoderOutputIndex == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                    if (!muxerStarted) {
                        val newFormat = encoder.outputFormat
                        encoderTrackIndex = muxer.addTrack(newFormat)
                        onEncoderFormatChanged(encoderTrackIndex)
                        muxer.start()
                        muxerStarted = true
                    }
                }
                encoderOutputIndex >= 0 -> {
                    val outputBuffer = encoder.getOutputBuffer(encoderOutputIndex)!!

                    if (bufferInfo.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG != 0) {
                        bufferInfo.size = 0
                    }

                    if (bufferInfo.size != 0 && muxerStarted) {
                        outputBuffer.position(bufferInfo.offset)
                        outputBuffer.limit(bufferInfo.offset + bufferInfo.size)
                        muxer.writeSampleData(encoderTrackIndex, outputBuffer, bufferInfo)
                    }

                    encoder.releaseOutputBuffer(encoderOutputIndex, false)

                    if (bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) {
                        outputDone = true
                    }
                }
            }
        }
    }

    private fun renderFrame(transformMatrix: FloatArray) {
        GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT)
        GLES20.glUseProgram(shaderProgram)

        // Set vertex positions
        val vertices = floatArrayOf(
            -1f, -1f, 0f,
            1f, -1f, 0f,
            -1f, 1f, 0f,
            1f, 1f, 0f
        )
        val vertexBuffer = createFloatBuffer(vertices)

        val positionHandle = GLES20.glGetAttribLocation(shaderProgram, "aPosition")
        GLES20.glEnableVertexAttribArray(positionHandle)
        GLES20.glVertexAttribPointer(positionHandle, 3, GLES20.GL_FLOAT, false, 0, vertexBuffer)

        // Set texture coordinates
        val texCoords = floatArrayOf(
            0f, 0f,
            1f, 0f,
            0f, 1f,
            1f, 1f
        )
        val texBuffer = createFloatBuffer(texCoords)

        val texCoordHandle = GLES20.glGetAttribLocation(shaderProgram, "aTexCoord")
        GLES20.glEnableVertexAttribArray(texCoordHandle)
        GLES20.glVertexAttribPointer(texCoordHandle, 2, GLES20.GL_FLOAT, false, 0, texBuffer)

        // Set transform matrix
        val transformHandle = GLES20.glGetUniformLocation(shaderProgram, "uTransform")
        GLES20.glUniformMatrix4fv(transformHandle, 1, false, transformMatrix, 0)

        // Set texture
        val textureHandle = GLES20.glGetUniformLocation(shaderProgram, "uTexture")
        GLES20.glActiveTexture(GLES20.GL_TEXTURE0)
        GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, textureId)
        GLES20.glUniform1i(textureHandle, 0)

        // Draw
        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4)

        // Cleanup
        GLES20.glDisableVertexAttribArray(positionHandle)
        GLES20.glDisableVertexAttribArray(texCoordHandle)
    }

    private fun createFloatBuffer(array: FloatArray): FloatBuffer {
        val buffer = ByteBuffer.allocateDirect(array.size * FLOAT_SIZE_BYTES)
            .order(ByteOrder.nativeOrder())
            .asFloatBuffer()
        buffer.put(array).position(0)
        return buffer
    }

    private fun processAudioTrack(
        audioExtractor: MediaExtractor,
        muxer: MediaMuxer,
        audioTrackIndex: Int
    ) {
        val audioBuffer = ByteBuffer.allocate(256 * 1024)
        val bufferInfo = MediaCodec.BufferInfo()

        while (true) {
            val sampleSize = audioExtractor.readSampleData(audioBuffer, 0)
            if (sampleSize < 0) break

            bufferInfo.offset = 0
            bufferInfo.size = sampleSize
            bufferInfo.presentationTimeUs = audioExtractor.sampleTime
            bufferInfo.flags = audioExtractor.sampleFlags

            muxer.writeSampleData(audioTrackIndex, audioBuffer, bufferInfo)
            audioExtractor.advance()
        }
    }

    private fun cleanupOpenGL() {
        egl?.eglMakeCurrent(eglDisplay, EGL10.EGL_NO_SURFACE, EGL10.EGL_NO_SURFACE, EGL10.EGL_NO_CONTEXT)
        egl?.eglDestroySurface(eglDisplay, eglSurface)
        egl?.eglDestroyContext(eglDisplay, eglContext)
        egl?.eglTerminate(eglDisplay)

        eglSurface = null
        eglContext = null
        eglDisplay = null
        egl = null
    }
}