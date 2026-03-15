@file:Suppress("PackageDirectoryMismatch")

package io.ente.photos.screensaver.setup

import android.content.Context
import android.util.Base64
import androidx.annotation.StringRes
import fi.iki.elonen.NanoHTTPD
import io.ente.photos.screensaver.R
import io.ente.photos.screensaver.diagnostics.AppLog
import io.ente.photos.screensaver.ente.EnteCrypto
import io.ente.photos.screensaver.ente.EntePublicAlbumRepository
import io.ente.photos.screensaver.ente.toDisplayMessage
import kotlinx.coroutines.runBlocking
import org.json.JSONObject

class EnteSetupServer(
    private val appContext: Context,
    port: Int,
    private val pairingCode: String,
    private val encryptionKey: ByteArray,
    private val onConfigUpdated: () -> Unit,
) : NanoHTTPD("0.0.0.0", port) {

    companion object {
        private const val PAIRING_MISMATCH_DELAY_MS = 300L
        private const val PAIRING_MISMATCH_WINDOW_MS = 60_000L
        private const val MAX_PAIRING_MISMATCHES = 20
        private const val MAX_REQUEST_BODY_BYTES = 8 * 1024L
        private const val MAX_ENCRYPTED_FIELD_CHARS = 8 * 1024
        private const val MAX_URL_CHARS = 4096
        private const val MAX_PASSWORD_CHARS = 1024
        private const val MAX_CODE_CHARS = 32
    }

    private val repo = EntePublicAlbumRepository.get(appContext)

    private val pairingMismatchLock = Any()
    private var pairingMismatchCount = 0
    private var pairingMismatchWindowStartAtMs = 0L

    override fun serve(session: IHTTPSession): Response {
        val rawPath = session.uri.substringBefore("?")
        val decodedPath = runCatching {
            java.net.URLDecoder.decode(rawPath, Charsets.UTF_8.name())
        }.getOrDefault(rawPath)
        val path = decodedPath
            .replace("\"", "")
            .replace("\\", "")
            .trim()
            .trimEnd('/')
            .ifBlank { "/" }

        return when {
            session.method == Method.GET && path == "/" -> {
                newFixedLengthResponse(
                    Response.Status.OK,
                    MIME_PLAINTEXT,
                    "Scan the QR code on your TV to set up",
                )
            }
            session.method == Method.POST && path == "/set" -> serveSet(session)
            path == "/set" -> {
                newFixedLengthResponse(
                    Response.Status.METHOD_NOT_ALLOWED,
                    MIME_PLAINTEXT,
                    s(R.string.setup_server_method_not_allowed),
                )
            }

            else -> {
                newFixedLengthResponse(
                    Response.Status.NOT_FOUND,
                    MIME_PLAINTEXT,
                    s(R.string.setup_server_not_found),
                )
            }
        }
    }

    private fun serveSet(session: IHTTPSession): Response {
        return runCatching {
            val contentLength = session.headers["content-length"]?.toLongOrNull()
            if (contentLength == null || contentLength <= 0L || contentLength > MAX_REQUEST_BODY_BYTES) {
                return@runCatching payloadTooLargeResponse()
            }

            val files = HashMap<String, String>()
            session.parseBody(files)

            AppLog.info("Setup", "Setup request received")
            val encryptedPayload = session.parameters["payload"]?.firstOrNull().orEmpty().trim()
            val header = session.parameters["header"]?.firstOrNull().orEmpty().trim()
            if (encryptedPayload.length > MAX_ENCRYPTED_FIELD_CHARS || header.length > MAX_ENCRYPTED_FIELD_CHARS) {
                AppLog.error("Setup", "Encrypted setup fields too large")
                return@runCatching payloadTooLargeResponse()
            }
            if (encryptedPayload.isBlank() || header.isBlank()) {
                AppLog.error("Setup", "Missing encrypted setup payload")
                return@runCatching securePayloadInvalidResponse()
            }

            val hasPlaintextFields = listOf("code", "url", "password")
                .any { session.parameters[it]?.firstOrNull()?.trim()?.isNotBlank() == true }
            if (hasPlaintextFields) {
                AppLog.error("Setup", "Rejected request containing plaintext setup fields")
                return@runCatching securePayloadInvalidResponse()
            }

            val payload = decryptSetupPayload(encryptedPayload, header) ?: run {
                AppLog.error("Setup", "Encrypted setup payload invalid")
                return@runCatching securePayloadInvalidResponse()
            }

            val codeValidationResponse = validatePairingCode(payload.code.trim())
            if (codeValidationResponse != null) {
                AppLog.error("Setup", "Pairing code rejected")
                return@runCatching codeValidationResponse
            }

            val url = payload.url.trim()
            val password = payload.password
            if (
                payload.code.length > MAX_CODE_CHARS ||
                url.length > MAX_URL_CHARS ||
                password.length > MAX_PASSWORD_CHARS
            ) {
                AppLog.error("Setup", "Setup payload field too large")
                return@runCatching payloadTooLargeResponse()
            }
            if (url.isBlank()) {
                AppLog.error("Setup", "Missing album URL in setup request")
                return@runCatching missingUrlResponse()
            }

            val result = runBlocking { repo.setConfigFromUrl(url, password) }
            if (result is io.ente.photos.screensaver.ente.EntePublicAlbumUrlParser.ParseResult.Success) {
                runBlocking { repo.refreshIfNeeded(force = true) }
                onConfigUpdated()
            }

            val html = when (result) {
                is io.ente.photos.screensaver.ente.EntePublicAlbumUrlParser.ParseResult.Success -> {
                    AppLog.info("Setup", "Album configured from setup page")
                    renderPage(
                        s(R.string.setup_server_saved_title),
                        """
                            <div class="card">
                              <h1>${esc(R.string.setup_server_saved_heading)}</h1>
                              <p>${esc(R.string.setup_server_saved_body)}</p>
                              <p class="note">${esc(R.string.setup_server_saved_note)}</p>
                            </div>
                        """.trimIndent(),
                    )
                }

                is io.ente.photos.screensaver.ente.EntePublicAlbumUrlParser.ParseResult.Error -> {
                    val message = escapeHtml(result.toDisplayMessage(appContext))
                    AppLog.error("Setup", "Setup failed: ${result.debugMessage()}")
                    renderPage(
                        s(R.string.setup_server_error_title),
                        """
                            <div class="card">
                              <h1>${esc(R.string.setup_server_error_heading)}</h1>
                              <p>$message</p>
                              <p class="note"><a class="link" href="/">${esc(R.string.setup_server_go_back)}</a></p>
                            </div>
                        """.trimIndent(),
                    )
                }
            }

            htmlResponse(Response.Status.OK, html)
        }.getOrElse { e ->
            newFixedLengthResponse(
                Response.Status.INTERNAL_ERROR,
                MIME_PLAINTEXT,
                s(R.string.setup_server_internal_error, e.message ?: s(R.string.setup_error_unknown_detail)),
            )
        }
    }

    private fun resetPairingMismatchStateLocked() {
        pairingMismatchCount = 0
        pairingMismatchWindowStartAtMs = 0L
    }

    private fun updatePairingMismatchWindowLocked(now: Long) {
        if (pairingMismatchWindowStartAtMs == 0L) return
        if (now - pairingMismatchWindowStartAtMs > PAIRING_MISMATCH_WINDOW_MS) {
            resetPairingMismatchStateLocked()
        }
    }

    private fun lockoutRemainingMsLocked(now: Long): Long? {
        if (pairingMismatchWindowStartAtMs == 0L) return null
        if (pairingMismatchCount < MAX_PAIRING_MISMATCHES) return null
        val remainingMs = PAIRING_MISMATCH_WINDOW_MS - (now - pairingMismatchWindowStartAtMs)
        return remainingMs.takeIf { it > 0L }
    }

    private fun validatePairingCode(code: String): Response? {
        synchronized(pairingMismatchLock) {
            val now = System.currentTimeMillis()
            updatePairingMismatchWindowLocked(now)

            lockoutRemainingMsLocked(now)?.let { remainingMs ->
                return tooManyAttemptsResponse(lockoutRemainingMs = remainingMs)
            }

            if (code == pairingCode) {
                resetPairingMismatchStateLocked()
                return null
            }

            if (pairingMismatchWindowStartAtMs == 0L) {
                pairingMismatchWindowStartAtMs = now
            }
            pairingMismatchCount += 1
            runCatching { Thread.sleep(PAIRING_MISMATCH_DELAY_MS) }

            val afterDelayNow = System.currentTimeMillis()
            updatePairingMismatchWindowLocked(afterDelayNow)
            val remainingMs = lockoutRemainingMsLocked(afterDelayNow)
            return if (remainingMs != null) {
                tooManyAttemptsResponse(lockoutRemainingMs = remainingMs)
            } else {
                pairingCodeErrorResponse()
            }
        }
    }

    private fun payloadTooLargeResponse(): Response {
        val html = renderPage(
            s(R.string.setup_server_request_too_large_title),
            """
                <div class="card">
                  <h1>${esc(R.string.setup_server_request_too_large_heading)}</h1>
                  <p>${esc(R.string.setup_server_request_too_large_body)}</p>
                  <p class="note"><a class="link" href="/">${esc(R.string.setup_server_back_to_setup)}</a></p>
                </div>
            """.trimIndent(),
        )
        return htmlResponse(Response.Status.PAYLOAD_TOO_LARGE, html)
    }

    private fun tooManyAttemptsResponse(lockoutRemainingMs: Long = PAIRING_MISMATCH_WINDOW_MS): Response {
        val retryAfterSeconds = ((lockoutRemainingMs + 999L) / 1000L).coerceAtLeast(1L)
        val html = renderPage(
            s(R.string.setup_server_too_many_attempts_title),
            """
                <div class="card">
                  <h1>${esc(R.string.setup_server_too_many_attempts_heading)}</h1>
                  <p>${esc(R.string.setup_server_too_many_attempts_body)}</p>
                  <p class="note"><a class="link" href="/">${esc(R.string.setup_server_back_to_setup)}</a></p>
                </div>
            """.trimIndent(),
        )
        return htmlResponse(Response.Status.TOO_MANY_REQUESTS, html).apply {
            addHeader("Retry-After", retryAfterSeconds.toString())
        }
    }

    private fun pairingCodeErrorResponse(): Response {
        val html = renderPage(
            s(R.string.setup_server_pairing_mismatch_title),
            """
                <div class="card">
                  <h1>${esc(R.string.setup_server_pairing_mismatch_heading)}</h1>
                  <p>${esc(R.string.setup_server_pairing_mismatch_body)}</p>
                  <p class="note"><a class="link" href="/">${esc(R.string.setup_server_back_to_setup)}</a></p>
                </div>
            """.trimIndent(),
        )
        return htmlResponse(Response.Status.UNAUTHORIZED, html)
    }

    private fun missingUrlResponse(): Response {
        val html = renderPage(
            s(R.string.setup_server_missing_link_title),
            """
                <div class="card">
                  <h1>${esc(R.string.setup_server_missing_link_heading)}</h1>
                  <p>${esc(R.string.setup_server_missing_link_body)}</p>
                  <p class="note"><a class="link" href="/">${esc(R.string.setup_server_back_to_setup)}</a></p>
                </div>
            """.trimIndent(),
        )
        return htmlResponse(Response.Status.BAD_REQUEST, html)
    }

    private fun securePayloadInvalidResponse(): Response {
        val html = renderPage(
            s(R.string.setup_server_secure_payload_invalid_title),
            """
                <div class="card">
                  <h1>${esc(R.string.setup_server_secure_payload_invalid_heading)}</h1>
                  <p>${esc(R.string.setup_server_secure_payload_invalid_body)}</p>
                  <p class="note"><a class="link" href="/">${esc(R.string.setup_server_back_to_setup)}</a></p>
                </div>
            """.trimIndent(),
        )
        return htmlResponse(Response.Status.BAD_REQUEST, html)
    }

    private fun htmlResponse(status: Response.Status, html: String): Response {
        return newFixedLengthResponse(status, "text/html", html).apply {
            addHeader("Cache-Control", "no-store, no-cache, max-age=0, must-revalidate")
            addHeader("Pragma", "no-cache")
        }
    }

    private data class SetupPayload(
        val code: String,
        val url: String,
        val password: String,
    )

    private fun decryptSetupPayload(payloadB64: String, headerB64: String): SetupPayload? {
        val encryptedBytes = decodeBase64(payloadB64) ?: return null

        return runCatching {
            val plaintextBytes = EnteCrypto.decryptBlobBytes(
                encryptedData = encryptedBytes,
                decryptionHeaderB64 = headerB64,
                key = encryptionKey,
            )
            val payload = JSONObject(String(plaintextBytes, Charsets.UTF_8))
            SetupPayload(
                code = payload.optString("code").trim(),
                url = payload.optString("url").trim(),
                password = payload.optString("password"),
            )
        }.getOrNull()
    }

    private fun decodeBase64(value: String): ByteArray? {
        return runCatching {
            Base64.decode(value, Base64.DEFAULT)
        }.getOrNull()
    }

    private fun renderPage(title: String, content: String): String {
        return """
            <!doctype html>
            <html>
              <head>
                <meta charset="utf-8" />
                <meta name="viewport" content="width=device-width, initial-scale=1" />
                <title>${escapeHtml(title)}</title>
                <style>
                  :root { color-scheme: dark; }
                  * { box-sizing: border-box; }
                  body {
                    margin: 0;
                    background: #0B0E10;
                    color: #FFFFFF;
                    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
                  }
                  .container {
                    max-width: 520px;
                    margin: 0 auto;
                    padding: 18px;
                    width: 100%;
                  }
                  .card {
                    background: #15181B;
                    border: 1px solid #2A2F33;
                    border-radius: 16px;
                    padding: 16px;
                  }
                  h1 {
                    font-size: 22px;
                    margin: 0 0 12px;
                  }
                  form {
                    display: flex;
                    flex-direction: column;
                    gap: 10px;
                  }
                  label {
                    display: block;
                    margin-top: 2px;
                    font-size: 13px;
                    color: #B7BDC3;
                  }
                  input {
                    width: 100%;
                    padding: 12px;
                    font-size: 16px;
                    border-radius: 12px;
                    border: 1px solid #2A2F33;
                    background: #0F1113;
                    color: #FFFFFF;
                  }
                  button {
                    width: 100%;
                    padding: 14px;
                    border: none;
                    border-radius: 14px;
                    background: #08C225;
                    color: #FFFFFF;
                    font-size: 16px;
                    font-weight: 600;
                  }
                  .note {
                    margin-top: 12px;
                    font-size: 12px;
                    color: #8D949A;
                  }
                  .link {
                    color: #B7BDC3;
                    text-decoration: underline;
                  }
                  @media (max-width: 480px) {
                    .container { padding: 14px; }
                    h1 { font-size: 20px; }
                    button { font-size: 15px; }
                  }
                </style>
              </head>
              <body>
                <div class="container">
                  $content
                </div>
              </body>
            </html>
        """.trimIndent()
    }

    private fun escapeHtml(input: String): String {
        return input
            .replace("&", "&amp;")
            .replace("<", "&lt;")
            .replace(">", "&gt;")
            .replace("\"", "&quot;")
            .replace("'", "&#39;")
    }

    private fun s(@StringRes id: Int, vararg args: Any): String {
        return appContext.getString(id, *args)
    }

    private fun esc(@StringRes id: Int, vararg args: Any): String {
        return escapeHtml(s(id, *args))
    }
}
