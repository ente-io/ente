package io.ente.photos.screensaver.setup

import android.os.Bundle
import android.util.Base64
import android.view.View
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import fi.iki.elonen.NanoHTTPD
import io.ente.photos.screensaver.R
import io.ente.photos.screensaver.databinding.ActivitySetupBinding
import io.ente.photos.screensaver.diagnostics.AppLog
import io.ente.photos.screensaver.ente.EntePublicAlbumRepository
import io.ente.photos.screensaver.ente.toDisplayMessage
import java.security.SecureRandom
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

class SetupActivity : AppCompatActivity() {

    private lateinit var binding: ActivitySetupBinding
    private val scope = MainScope()

    private val portCandidates = listOf(5843, 8080, 8899)
    private val secureRandom = SecureRandom()
    private val pairingCode: String = generatePairingCode()
    private val setupEncryptionKeyBytes: ByteArray = ByteArray(32).also { secureRandom.nextBytes(it) }
    private val setupEncryptionKeyB64Url: String = Base64.encodeToString(
        setupEncryptionKeyBytes,
        Base64.URL_SAFE or Base64.NO_WRAP or Base64.NO_PADDING,
    )

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

        binding.buttonToggleManual.setOnClickListener {
            toggleManualEntry()
        }

        binding.buttonSave.setOnClickListener {
            val url = binding.editPublicAlbumUrl.text?.toString().orEmpty()
            val password = binding.editPublicAlbumPassword.text?.toString().orEmpty()
            scope.launch {
                val result = repo.setConfigFromUrl(url, password)
                when (result) {
                    is io.ente.photos.screensaver.ente.EntePublicAlbumUrlParser.ParseResult.Success -> {
                        repo.refreshIfNeeded(force = true)
                        binding.editPublicAlbumUrl.text?.clear()
                        binding.editPublicAlbumPassword.text?.clear()
                        Toast.makeText(this@SetupActivity, getString(R.string.setup_saved), Toast.LENGTH_LONG).show()
                    }
                    is io.ente.photos.screensaver.ente.EntePublicAlbumUrlParser.ParseResult.Error -> {
                        Toast.makeText(this@SetupActivity, result.toDisplayMessage(this@SetupActivity), Toast.LENGTH_LONG).show()
                    }
                }
                refreshUi()
            }
        }

        scope.launch { refreshUi() }
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

    private fun toggleManualEntry() {
        val isVisible = binding.cardManualEntry.visibility == View.VISIBLE
        if (isVisible) {
            binding.cardManualEntry.visibility = View.GONE
            binding.buttonToggleManual.text = getString(R.string.setup_button_manual)
            binding.buttonToggleManual.requestFocus()
            return
        }

        binding.cardManualEntry.visibility = View.VISIBLE
        binding.buttonToggleManual.text = getString(R.string.setup_button_hide_manual)
        binding.editPublicAlbumUrl.text?.clear()
        binding.editPublicAlbumPassword.text?.clear()

        binding.cardManualEntry.post {
            binding.editPublicAlbumUrl.requestFocus()
            binding.scrollSetup.smoothScrollTo(0, binding.cardManualEntry.top)
        }
    }

    private suspend fun refreshUi() {
        val config = repo.getConfig()
        if (config == null) {
            binding.textStatus.text = getString(R.string.setup_status_not_configured)
        } else {
            binding.textStatus.text = getString(R.string.setup_status_configured)
        }
    }

    private suspend fun handleRemoteConfigUpdated() {
        refreshUi()
        if (repo.getConfig() == null) return
        if (remoteConfigHandled || isFinishing || isDestroyed) return

        remoteConfigHandled = true
        AppLog.info("Setup", "Album configured from phone; closing setup screen")
        Toast.makeText(this@SetupActivity, getString(R.string.setup_configured_from_phone), Toast.LENGTH_LONG).show()
        finish()
    }

    private fun updateSetupLinks() {
        val port = activePort
        val addresses = NetworkUtils.getLocalIpv4Addresses()

        if (port == null) {
            binding.textSetupUrl.text = getString(R.string.setup_server_failed)
            binding.textPairingCode.visibility = View.GONE
            binding.textSetupHint.visibility = View.GONE
            Toast.makeText(this, getString(R.string.setup_server_failed), Toast.LENGTH_LONG).show()
            return
        }

        val primaryUrl = addresses.firstOrNull()?.let { buildSetupUrl(it.address, port) }

        if (primaryUrl != null) {
            binding.textSetupUrl.text = buildSetupUrlList(addresses, port)
            binding.textPairingCode.text = getString(R.string.setup_pairing_code, pairingCode)
            binding.textSetupHint.text = getString(R.string.setup_wifi_hint)
            binding.textPairingCode.visibility = View.VISIBLE
            binding.textSetupHint.visibility = View.VISIBLE
            binding.imageQr.setImageBitmap(QrCodeUtils.renderQrCode(primaryUrl, 360))
        } else {
            binding.textSetupUrl.text = getString(R.string.setup_no_network)
            binding.textPairingCode.visibility = View.GONE
            binding.textSetupHint.visibility = View.GONE
        }
    }

    private fun generatePairingCode(): String {
        val code = secureRandom.nextInt(1_000_000)
        return String.format("%06d", code)
    }

    private fun buildSetupUrl(address: String, port: Int): String {
        return "http://$address:$port/?code=$pairingCode#ek=$setupEncryptionKeyB64Url"
    }

    private fun buildSetupUrlList(addresses: List<NetworkUtils.LocalAddress>, port: Int): String {
        val prefix = getString(R.string.setup_open_on_phone_prefix)
        val lines = addresses.map { formatAddressLabel(it, port) }
        return buildString {
            append(prefix)
            lines.forEach { line ->
                append("\n")
                append(line)
            }
        }
    }

    private fun formatAddressLabel(address: NetworkUtils.LocalAddress, port: Int): String {
        val lower = address.interfaceName.lowercase()
        val label = when {
            lower.startsWith("wlan") || lower.startsWith("wifi") -> getString(R.string.setup_network_label_wifi)
            lower.startsWith("eth") || lower.startsWith("en") -> getString(R.string.setup_network_label_ethernet)
            else -> address.interfaceName
        }
        val url = buildSetupUrl(address.address, port)
        return if (label.isBlank()) {
            url
        } else {
            getString(R.string.setup_network_label_format, label, url)
        }
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
