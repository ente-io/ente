package io.ente.photos.screensaver.setup

import android.content.Intent
import android.os.Bundle
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.isVisible
import fi.iki.elonen.NanoHTTPD
import io.ente.photos.screensaver.R
import io.ente.photos.screensaver.databinding.ActivitySetupBinding
import io.ente.photos.screensaver.diagnostics.AppLog
import io.ente.photos.screensaver.ente.EntePublicAlbumRepository
import io.ente.photos.screensaver.main.MainActivity
import java.security.SecureRandom
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

class SetupActivity : AppCompatActivity() {

    companion object {
        const val EXTRA_AUTO_RETURN_TO_PREVIEW = "auto_return_to_preview"
    }

    private lateinit var binding: ActivitySetupBinding
    private val scope = MainScope()

    private val portCandidates = listOf(5843, 8080, 8899)
    private val secureRandom = SecureRandom()
    private val pairingCode: String = generatePairingCode()
    private val setupEncryptionKeyBytes: ByteArray = ByteArray(32).also { secureRandom.nextBytes(it) }

    private var server: EnteSetupServer? = null
    private var activePort: Int? = null
    private var serverStatus: String? = null

    private lateinit var repo: EntePublicAlbumRepository
    private var remoteConfigHandled = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        AppLog.initialize(this)
        binding = ActivitySetupBinding.inflate(layoutInflater)
        setContentView(binding.root)

        repo = EntePublicAlbumRepository.get(this)
    }

    private fun startServer() {
        if (server != null) return

        for (candidate in portCandidates) {
            val started = runCatching {
                EnteSetupServer(
                    appContext = applicationContext,
                    port = candidate,
                    pairingCode = pairingCode,
                    encryptionKey = setupEncryptionKeyBytes,
                    onConfigUpdated = { scope.launch { handleRemoteConfigUpdated() } },
                ).also { it.start(NanoHTTPD.SOCKET_READ_TIMEOUT, false) }
            }.getOrNull()

            if (started != null) {
                server = started
                activePort = candidate
                break
            }
        }

        serverStatus = if (server != null && activePort != null) {
            getString(R.string.setup_server_running, activePort)
        } else {
            getString(R.string.setup_server_failed)
        }

        if (server == null) {
            Toast.makeText(this, serverStatus, Toast.LENGTH_LONG).show()
        }
    }

    private suspend fun handleRemoteConfigUpdated() {
        if (repo.getConfig() == null) return
        if (remoteConfigHandled || isFinishing || isDestroyed) return

        remoteConfigHandled = true
        AppLog.info("Setup", "Album configured from phone; closing setup screen")
        Toast.makeText(this@SetupActivity, getString(R.string.setup_configured_from_phone), Toast.LENGTH_LONG).show()

        if (intent.getBooleanExtra(EXTRA_AUTO_RETURN_TO_PREVIEW, false)) {
            startActivity(
                Intent(this, MainActivity::class.java).addFlags(
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP,
                ),
            )
        }
        finish()
    }

    private fun updateSetupLinks() {
        val port = activePort
        val addresses = NetworkUtils.getLocalIpv4Addresses()

        if (port == null || addresses.isEmpty()) {
            binding.textSetupHint.isVisible = true
            binding.textSetupHint.text = getString(R.string.setup_no_network)
            binding.imageQr.setImageDrawable(null)
            return
        }

        val primaryUrl = addresses.firstOrNull()?.let { buildSetupUrl(it.address, port) }
        if (primaryUrl == null) {
            binding.textSetupHint.isVisible = true
            binding.textSetupHint.text = getString(R.string.setup_no_network)
            binding.imageQr.setImageDrawable(null)
            return
        }

        binding.textSetupHint.isVisible = false
        binding.imageQr.post {
            val qrSize = minOf(binding.imageQr.width, binding.imageQr.height).takeIf { it > 0 } ?: 520
            binding.imageQr.setImageBitmap(
                QrCodeUtils.renderQrCode(
                    context = this,
                    text = primaryUrl,
                    sizePx = qrSize,
                ),
            )
        }
    }

    private fun generatePairingCode(): String {
        val code = secureRandom.nextInt(1_000_000)
        return String.format("%06d", code)
    }

    private fun buildSetupUrl(address: String, port: Int): String {
        return "http://$address:$port/?code=$pairingCode"
    }

    override fun onStart() {
        super.onStart()
        startServer()
        updateSetupLinks()
    }

    override fun onStop() {
        server?.stop()
        server = null
        activePort = null
        super.onStop()
    }

    override fun onDestroy() {
        super.onDestroy()
        server?.stop()
        server = null
        scope.cancel()
    }
}
