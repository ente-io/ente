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
import java.io.IOException
import kotlinx.coroutines.runBlocking
import org.json.JSONObject

class EnteSetupServer(
    private val appContext: Context,
    port: Int,
    private val pairingCode: String,
    private val encryptionKeyId: String,
    private val encryptionKey: ByteArray,
    private val onConfigUpdated: () -> Unit,
) : NanoHTTPD("0.0.0.0", port) {

    companion object {
        private const val PAIRING_MISMATCH_DELAY_MS = 300L
        private const val PAIRING_MISMATCH_WINDOW_MS = 60_000L
        private const val MAX_PAIRING_MISMATCHES = 20
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
            session.method == Method.GET && path == "/" -> serveIndex(session)
            session.method == Method.GET && path.startsWith("/setup-crypto/") ->
                serveSetupCryptoAsset(path.removePrefix("/setup-crypto/"))
            session.method == Method.POST && path == "/set" -> serveSet(session)
            session.method == Method.POST && path == "/clear" -> serveClear(session)
            path == "/set" || path == "/clear" -> {
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

    private fun serveSetupCryptoAsset(fileName: String): Response {
        val allowed = mapOf(
            "ente_wasm.js" to "application/javascript",
            "ente_wasm_bg.js" to "application/javascript",
            "ente_wasm_bg.wasm" to "application/wasm",
        )

        val mime = allowed[fileName] ?: return newFixedLengthResponse(
            Response.Status.NOT_FOUND,
            MIME_PLAINTEXT,
            s(R.string.setup_server_not_found),
        )

        val bytes = try {
            appContext.assets.open("setup_crypto/$fileName").use { it.readBytes() }
        } catch (_: IOException) {
            return newFixedLengthResponse(
                Response.Status.NOT_FOUND,
                MIME_PLAINTEXT,
                s(R.string.setup_server_not_found),
            )
        }

        return newFixedLengthResponse(
            Response.Status.OK,
            mime,
            bytes.inputStream(),
            bytes.size.toLong(),
        ).apply {
            addHeader("Cache-Control", "no-store")
        }
    }

    private fun serveIndex(session: IHTTPSession): Response {
        val providedCode = session.parameters["code"]?.firstOrNull()?.trim().orEmpty()
        val codeMatches = providedCode.isNotBlank() && providedCode == pairingCode
        val providedKid = session.parameters["kid"]?.firstOrNull()?.trim().orEmpty()
        val kidMatches = providedKid.isNotBlank() && providedKid == encryptionKeyId

        val codeInput = if (codeMatches) {
            "<input type=\"hidden\" name=\"code\" value=\"${escapeHtml(providedCode)}\" />"
        } else {
            """
                <label for="code">${esc(R.string.setup_server_pairing_code_label)}</label>
                <input name="code" id="code" placeholder="${esc(R.string.setup_server_pairing_code_placeholder)}" inputmode="numeric" />
            """.trimIndent()
        }
        val kidInput = if (kidMatches) {
            "<input type=\"hidden\" name=\"kid\" id=\"kid\" value=\"${escapeHtml(providedKid)}\" />"
        } else {
            ""
        }

        val codeHint = if (codeMatches) {
            ""
        } else {
            "<p class=\"note\">${esc(R.string.setup_server_pairing_code_hint)}</p>"
        }

        val body = """
            <div class="card">
              <h1>${esc(R.string.app_name)}</h1>
              <form method="post" action="/set" id="setup-form">
                $codeInput
                $kidInput
                <input type="hidden" name="payload" id="payload" />
                <input type="hidden" name="header" id="header" />
                <label for="url">${esc(R.string.setup_server_public_album_label)}</label>
                <input name="url" id="url" placeholder="${esc(R.string.setup_server_public_album_placeholder)}" autocomplete="off" />
                <label for="password">${esc(R.string.setup_server_password_label)}</label>
                <input name="password" id="password" type="password" autocomplete="new-password" />
                <button type="submit">${esc(R.string.setup_server_save_button)}</button>
              </form>
            </div>
            $codeHint
            <p class="note">${esc(R.string.setup_server_open_screen_note)}</p>
            ${secureSubmitScript(enabled = kidMatches)}
        """.trimIndent()

        val html = renderPage(s(R.string.setup_server_page_title), body)
        return newFixedLengthResponse(Response.Status.OK, "text/html", html)
    }

    private fun serveSet(session: IHTTPSession): Response {
        return runCatching {
            val contentLength = session.headers["content-length"]?.toLongOrNull()
            if (contentLength != null && contentLength > 8 * 1024L) {
                return@runCatching payloadTooLargeResponse()
            }

            val files = HashMap<String, String>()
            session.parseBody(files)

            AppLog.info("Setup", "Setup request received")
            val code = session.parameters["code"]?.firstOrNull().orEmpty().trim()
            if (code != pairingCode) {
                AppLog.error("Setup", "Pairing code mismatch")
                return@runCatching pairingCodeMismatchResponse()
            }
            resetPairingMismatchState()

            val encryptedPayload = session.parameters["payload"]?.firstOrNull().orEmpty().trim()
            val (url, password) = if (encryptedPayload.isNotBlank()) {
                val kid = session.parameters["kid"]?.firstOrNull().orEmpty().trim()
                if (kid != encryptionKeyId) {
                    AppLog.error("Setup", "Encryption key mismatch")
                    return@runCatching securePayloadInvalidResponse()
                }

                val header = session.parameters["header"]?.firstOrNull().orEmpty().trim()
                decryptSetupPayload(encryptedPayload, header) ?: run {
                    AppLog.error("Setup", "Encrypted setup payload invalid")
                    return@runCatching securePayloadInvalidResponse()
                }
            } else {
                val rawUrl = session.parameters["url"]?.firstOrNull().orEmpty().trim()
                val rawPassword = session.parameters["password"]?.firstOrNull().orEmpty()
                rawUrl to rawPassword
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

            newFixedLengthResponse(Response.Status.OK, "text/html", html)
        }.getOrElse { e ->
            newFixedLengthResponse(
                Response.Status.INTERNAL_ERROR,
                MIME_PLAINTEXT,
                s(R.string.setup_server_internal_error, e.message ?: s(R.string.setup_error_unknown_detail)),
            )
        }
    }

    private fun serveClear(session: IHTTPSession): Response {
        return runCatching {
            val contentLength = session.headers["content-length"]?.toLongOrNull()
            if (contentLength != null && contentLength > 2 * 1024L) {
                return@runCatching payloadTooLargeResponse()
            }

            val files = HashMap<String, String>()
            session.parseBody(files)

            val code = session.parameters["code"]?.firstOrNull().orEmpty().trim()
            if (code != pairingCode) {
                AppLog.error("Setup", "Pairing code mismatch")
                return@runCatching pairingCodeMismatchResponse()
            }
            resetPairingMismatchState()

            runBlocking { repo.clearConfig() }
            AppLog.info("Setup", "Config cleared via setup page")
            onConfigUpdated()
            newFixedLengthResponse(Response.Status.OK, MIME_PLAINTEXT, s(R.string.setup_server_cleared_plaintext))
        }.getOrElse { e ->
            newFixedLengthResponse(
                Response.Status.INTERNAL_ERROR,
                MIME_PLAINTEXT,
                s(R.string.setup_server_internal_error, e.message ?: s(R.string.setup_error_unknown_detail)),
            )
        }
    }

    private fun resetPairingMismatchState() {
        synchronized(pairingMismatchLock) {
            pairingMismatchCount = 0
            pairingMismatchWindowStartAtMs = 0L
        }
    }

    private fun pairingCodeMismatchResponse(): Response {
        val now = System.currentTimeMillis()

        val lockedOut = synchronized(pairingMismatchLock) {
            if (
                pairingMismatchWindowStartAtMs == 0L ||
                now - pairingMismatchWindowStartAtMs > PAIRING_MISMATCH_WINDOW_MS
            ) {
                pairingMismatchWindowStartAtMs = now
                pairingMismatchCount = 0
            }

            pairingMismatchCount += 1
            pairingMismatchCount >= MAX_PAIRING_MISMATCHES
        }

        runCatching { Thread.sleep(PAIRING_MISMATCH_DELAY_MS) }

        return if (lockedOut) {
            tooManyAttemptsResponse()
        } else {
            pairingCodeErrorResponse()
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
        return newFixedLengthResponse(Response.Status.PAYLOAD_TOO_LARGE, "text/html", html)
    }

    private fun tooManyAttemptsResponse(): Response {
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
        return newFixedLengthResponse(Response.Status.TOO_MANY_REQUESTS, "text/html", html).apply {
            addHeader("Retry-After", (PAIRING_MISMATCH_WINDOW_MS / 1000L).toString())
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
        return newFixedLengthResponse(Response.Status.UNAUTHORIZED, "text/html", html)
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
        return newFixedLengthResponse(Response.Status.BAD_REQUEST, "text/html", html)
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
        return newFixedLengthResponse(Response.Status.BAD_REQUEST, "text/html", html)
    }

    private fun decryptSetupPayload(payloadB64: String, headerB64: String): Pair<String, String>? {
        val encryptedBytes = decodeBase64(payloadB64) ?: return null

        return runCatching {
            val plaintextBytes = EnteCrypto.decryptBlobBytes(
                encryptedData = encryptedBytes,
                decryptionHeaderB64 = headerB64,
                key = encryptionKey,
            )
            val payload = JSONObject(String(plaintextBytes, Charsets.UTF_8))
            payload.optString("url").trim() to payload.optString("password")
        }.getOrNull()
    }

    private fun decodeBase64(value: String): ByteArray? {
        return runCatching {
            Base64.decode(value, Base64.DEFAULT)
        }.getOrNull()
    }

    private fun secureSubmitScript(enabled: Boolean): String {
        if (!enabled) return ""

        return """
            <script>
              (() => {
                const form = document.getElementById('setup-form');
                const kidInput = document.getElementById('kid');
                const payloadInput = document.getElementById('payload');
                const headerInput = document.getElementById('header');
                const urlInput = document.getElementById('url');
                const passwordInput = document.getElementById('password');
                if (!form || !kidInput || !payloadInput || !headerInput || !urlInput || !passwordInput) return;

                const hash = window.location.hash.startsWith('#') ? window.location.hash.substring(1) : '';
                const hashParams = new URLSearchParams(hash);
                const ek = hashParams.get('ek');

                const bytesToBase64 = (bytes) => {
                  let binary = '';
                  bytes.forEach((b) => { binary += String.fromCharCode(b); });
                  return btoa(binary);
                };

                const base64UrlToBytes = (value) => {
                  const normalized = value.replace(/-/g, '+').replace(/_/g, '/');
                  const padded = normalized + '='.repeat((4 - (normalized.length % 4)) % 4);
                  const binary = atob(padded);
                  const out = new Uint8Array(binary.length);
                  for (let i = 0; i < binary.length; i++) out[i] = binary.charCodeAt(i);
                  return out;
                };

                form.addEventListener('submit', async (event) => {
                  if (!ek) {
                    event.preventDefault();
                    alert('Secure key missing. Please scan the QR code again from the TV.');
                    return;
                  }

                  event.preventDefault();

                  try {
                    const wasm = await import('/setup-crypto/ente_wasm.js');
                    if (typeof wasm.crypto_init === 'function') {
                      wasm.crypto_init();
                    }

                    const keyBytes = base64UrlToBytes(ek);
                    const keyB64 = bytesToBase64(keyBytes);

                    const plaintext = JSON.stringify({
                      url: urlInput.value || '',
                      password: passwordInput.value || ''
                    });
                    const plaintextBytes = new TextEncoder().encode(plaintext);
                    const plaintextB64 = bytesToBase64(plaintextBytes);

                    const encrypted = wasm.crypto_encrypt_blob(plaintextB64, keyB64);
                    const encryptedData = encrypted?.encrypted_data ?? encrypted?.encryptedData;
                    const decryptionHeader = encrypted?.decryption_header ?? encrypted?.decryptionHeader;

                    if (!encryptedData || !decryptionHeader) {
                      throw new Error('Missing encrypted payload');
                    }

                    payloadInput.value = encryptedData;
                    headerInput.value = decryptionHeader;

                    urlInput.value = '';
                    passwordInput.value = '';
                    urlInput.removeAttribute('name');
                    passwordInput.removeAttribute('name');

                    form.submit();
                  } catch (err) {
                    alert('Secure setup failed. Please scan the QR code again and retry.');
                  }
                });
              })();
            </script>
        """.trimIndent()
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
