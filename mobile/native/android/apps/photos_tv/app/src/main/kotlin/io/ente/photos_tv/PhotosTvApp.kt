package io.ente.photos_tv

import android.graphics.BitmapFactory
import android.text.format.DateFormat
import android.util.Log
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.animation.togetherWith
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.focusable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.Typography
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onPreviewKeyEvent
import androidx.compose.ui.input.key.type
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.googlefonts.Font as DownloadableFont
import androidx.compose.ui.text.googlefonts.GoogleFont
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import okhttp3.OkHttpClient
import java.util.Date

@Composable
internal fun PhotosTvApp(isScreensaver: Boolean) {
    MaterialTheme(
        colorScheme = MaterialTheme.colorScheme.copy(background = Color.Black, surface = Color.Black, onBackground = Color.White, onSurface = Color.White),
        typography = googleSansTypography,
    ) {
        ReceiverScreen(isScreensaver = isScreensaver)
    }
}

@Composable
private fun ReceiverScreen(isScreensaver: Boolean) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val cryptoBox = remember { CryptoBox() }
    val client = remember { OkHttpClient() }
    val pairingService = remember { PairingService(client, cryptoBox) }
    val castStateStore = remember { CastStateStore(context.applicationContext) }
    var registration by remember { mutableStateOf<Registration?>(null) }
    var payload by remember { mutableStateOf<CastPayload?>(null) }
    var showPairingComplete by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }
    var pollJob by remember { mutableStateOf<Job?>(null) }
    fun startPairing() {
        pollJob?.cancel()
        registration = null
        payload = null
        showPairingComplete = false
        error = null
        scope.launch {
            runCatching {
                withContext(Dispatchers.IO) { pairingService.register() }
            }.onSuccess { value ->
                registration = value
                pollJob = launchPoll(scope, pairingService, castStateStore, value, {
                    showPairingComplete = true
                    payload = it
                }, { error = it }, { startPairing() })
            }.onFailure {
                error = it.toString()
            }
        }
    }
    LaunchedEffect(Unit) {
        withContext(Dispatchers.IO) { castStateStore.load() }
        val savedPayload = castStateStore.state.payload
        if (savedPayload == null) startPairing() else {
            showPairingComplete = false
            payload = savedPayload
        }
    }
    DisposableEffect(Unit) {
        onDispose {
            pollJob?.cancel()
        }
    }
    Box(Modifier.fillMaxSize().background(Color.Black)) {
        val currentPayload = payload
        if (currentPayload != null) {
            SlideshowScreen(
                payload = currentPayload,
                showPairingComplete = showPairingComplete,
                onPairingExpired = {
                    scope.launch {
                        withContext(Dispatchers.IO) { castStateStore.clear() }
                        showPairingComplete = false
                        startPairing()
                    }
                },
                onChangeAlbum = {
                    scope.launch {
                        withContext(Dispatchers.IO) { castStateStore.clear() }
                        showPairingComplete = false
                        startPairing()
                    }
                },
                cryptoBox = cryptoBox,
                client = client,
                isScreensaver = isScreensaver,
            )
        } else {
            PairingView(pairingCode = registration?.pairingCode, error = error, onRetry = { startPairing() })
        }
    }
}

private fun launchPoll(
    scope: CoroutineScope,
    pairingService: PairingService,
    castStateStore: CastStateStore,
    registration: Registration,
    onPayload: (CastPayload) -> Unit,
    onError: (String) -> Unit,
    onRestart: () -> Unit,
): Job {
    return scope.launch {
        while (isActive) {
            try {
                val payload = withContext(Dispatchers.IO) { pairingService.getCastPayload(registration) }
                if (payload != null) {
                    withContext(Dispatchers.IO) { castStateStore.save(CastState(payload)) }
                    onPayload(payload)
                    return@launch
                }
            } catch (error: Throwable) {
                onError(error.toString())
                delay(3000)
                onRestart()
                return@launch
            }
            delay(2000)
        }
    }
}

@Composable
private fun PairingView(pairingCode: String?, error: String?, onRetry: () -> Unit) {
    Column(
        modifier = Modifier.fillMaxSize().padding(48.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        Text("ente", fontSize = 52.sp, fontWeight = FontWeight.Bold, color = Color.White)
        Spacer(Modifier.height(32.dp))
        Text(
            "Enter this code on Ente Photos to pair this screen",
            textAlign = TextAlign.Center,
            fontSize = 32.sp,
            fontWeight = FontWeight.Medium,
            color = Color.White,
        )
        Spacer(Modifier.height(32.dp))
        Box(Modifier.height(92.dp), contentAlignment = Alignment.Center) {
            if (pairingCode == null) CircularProgressIndicator(modifier = Modifier.size(24.dp), color = Color.White, strokeWidth = 2.dp) else PairingCode(pairingCode)
        }
        Spacer(Modifier.height(24.dp))
        if (error != null) Button(onClick = onRetry) { Text("Retry: $error") } else Text("Visit ente.com/cast for help", color = Color.White)
    }
}

@Composable
private fun PairingCode(code: String) {
    Row(Modifier.clip(RoundedCornerShape(10.dp)), horizontalArrangement = Arrangement.Center) {
        code.forEachIndexed { index, character ->
            val backgroundColor = if (index % 2 == 0) Color(0xFF2E2E2E) else Color(0xFF5E5E5E)
            val foregroundColor = pairingCodeColors[index % pairingCodeColors.size]
            Box(
                modifier = Modifier.width(80.dp).height(92.dp).background(backgroundColor),
                contentAlignment = Alignment.Center,
            ) {
                Text(character.toString(), color = foregroundColor, fontSize = 64.sp, fontWeight = FontWeight.Bold)
            }
        }
    }
}

@Composable
private fun SlideshowScreen(
    payload: CastPayload,
    showPairingComplete: Boolean,
    onPairingExpired: () -> Unit,
    onChangeAlbum: () -> Unit,
    cryptoBox: CryptoBox,
    client: OkHttpClient,
    isScreensaver: Boolean,
) {
    val context = LocalContext.current
    val service = remember(payload) { SlideshowService(client, payload, DiskImageCache(context.applicationContext), cryptoBox) }
    var imageBytes by remember(payload) { mutableStateOf<ByteArray?>(null) }
    var message by remember(payload) { mutableStateOf<String?>(null) }
    var showMenu by remember(payload) { mutableStateOf(false) }
    var showDownArrowHint by remember(payload, isScreensaver) { mutableStateOf(!isScreensaver) }
    suspend fun showNext() {
        runCatching {
            withContext(Dispatchers.IO) { service.nextImage() }
        }.onSuccess {
            imageBytes = it
            message = if (it == null) "Try another album" else null
        }.onFailure {
            Log.e(LOG_TAG, "Failed to load slideshow", it)
            if (it is HttpStatusException && (it.statusCode == 401 || it.statusCode == 403)) {
                message = "Pairing expired"
                onPairingExpired()
            } else {
                message = "Unable to load album"
            }
        }
    }
    LaunchedEffect(payload) {
        showNext()
        while (isActive) {
            delay(SLIDE_DURATION)
            showNext()
        }
    }
    LaunchedEffect(showDownArrowHint) {
        if (showDownArrowHint) {
            delay(DOWN_ARROW_HINT_DURATION)
            showDownArrowHint = false
        }
    }
    Box(Modifier.fillMaxSize().background(Color.Black)) {
        AnimatedContent(
            targetState = imageBytes,
            transitionSpec = { fadeIn(animationSpec = tween(800)) togetherWith fadeOut(animationSpec = tween(800)) },
            label = "slide",
        ) { bytes ->
            when {
                bytes != null -> SlideImage(bytes = bytes)
                message != null -> StatusMessage(message = message!!, showCheckmark = false)
                showPairingComplete -> StatusMessage(message = "Pairing Complete", showCheckmark = true)
                else -> LoadingStatus()
            }
        }
        if (imageBytes != null) {
            SlideOverlay(
                showMenu = showMenu,
                showDownArrowHint = showDownArrowHint,
                isScreensaver = isScreensaver,
                onShowMenu = {
                    showDownArrowHint = false
                    showMenu = true
                },
                onHideMenu = {
                    if (showMenu) {
                        showMenu = false
                        showDownArrowHint = !isScreensaver
                    }
                },
                onChangeAlbum = onChangeAlbum,
            )
        }
    }
}

@Composable
private fun LoadingStatus() {
    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        CircularProgressIndicator(modifier = Modifier.size(24.dp), color = Color.White, strokeWidth = 2.dp)
    }
}

@Composable
private fun StatusMessage(message: String, showCheckmark: Boolean) {
    Column(
        modifier = Modifier.fillMaxSize(),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        AnimatedVisibility(showCheckmark) {
            Checkmark()
        }
        if (showCheckmark) Spacer(Modifier.height(24.dp))
        Text(message, textAlign = TextAlign.Center, fontSize = 36.sp, fontWeight = FontWeight.SemiBold, color = Color.White)
    }
}

@Composable
private fun Checkmark() {
    val transition = rememberInfiniteTransition(label = "check")
    val progress by transition.animateFloat(
        initialValue = 0f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(tween(900, easing = FastOutSlowInEasing), RepeatMode.Restart),
        label = "checkProgress",
    )
    Canvas(Modifier.size(140.dp)) {
        drawCircle(Color.Green, radius = size.minDimension / 2f)
        val path = Path()
        path.moveTo(size.width * 0.27f, size.height * 0.52f)
        path.lineTo(size.width * 0.42f, size.height * 0.67f)
        path.lineTo(size.width * 0.73f, size.height * 0.34f)
        drawPath(
            path = path,
            color = Color.White,
            style = Stroke(width = size.width * 0.055f, cap = StrokeCap.Round, join = StrokeJoin.Round),
            alpha = progress.coerceIn(0f, 1f),
        )
    }
}

@Composable
private fun SlideImage(
    bytes: ByteArray,
) {
    val bitmap = remember(bytes) { BitmapFactory.decodeByteArray(bytes, 0, bytes.size).asImageBitmap() }
    Box(Modifier.fillMaxSize().background(Color.Black)) {
        Image(bitmap = bitmap, contentDescription = null, modifier = Modifier.fillMaxSize().alpha(0.25f), contentScale = ContentScale.Crop)
        Box(Modifier.fillMaxSize().background(Color.Black.copy(alpha = 0.54f)))
        Image(bitmap = bitmap, contentDescription = null, modifier = Modifier.fillMaxSize(), contentScale = ContentScale.Fit)
    }
}

@Composable
private fun SlideOverlay(
    showMenu: Boolean,
    showDownArrowHint: Boolean,
    isScreensaver: Boolean,
    onShowMenu: () -> Unit,
    onHideMenu: () -> Unit,
    onChangeAlbum: () -> Unit,
) {
    val focusRequester = remember { FocusRequester() }
    LaunchedEffect(Unit) {
        focusRequester.requestFocus()
    }
    Box(
        Modifier
            .fillMaxSize()
            .onPreviewKeyEvent { event ->
                if (event.type != KeyEventType.KeyDown) return@onPreviewKeyEvent false
                when (event.key) {
                    Key.DirectionDown -> {
                        if (isScreensaver) return@onPreviewKeyEvent false
                        onShowMenu()
                        true
                    }
                    Key.DirectionUp, Key.Back -> {
                        if (!showMenu) return@onPreviewKeyEvent false
                        onHideMenu()
                        true
                    }
                    Key.DirectionCenter, Key.Enter -> {
                        if (!showMenu) return@onPreviewKeyEvent false
                        onChangeAlbum()
                        true
                    }
                    else -> false
                }
            }
            .focusRequester(focusRequester)
            .focusable(),
    ) {
        AlbumClock(Modifier.align(Alignment.BottomEnd).padding(end = 40.dp, bottom = 24.dp))
        AnimatedVisibility(
            visible = showDownArrowHint && !isScreensaver,
            modifier = Modifier.align(Alignment.BottomCenter).padding(bottom = 24.dp),
            enter = fadeIn(animationSpec = tween(240)) + slideInVertically(animationSpec = tween(240), initialOffsetY = { it / 2 }),
            exit = fadeOut(animationSpec = tween(180)) + slideOutVertically(animationSpec = tween(180), targetOffsetY = { it / 2 }),
        ) {
            DownArrowHint()
        }
        AnimatedVisibility(visible = showMenu, modifier = Modifier.fillMaxSize()) {
            AlbumMenu(onChangeAlbum = onChangeAlbum)
        }
    }
}

@Composable
private fun DownArrowHint(modifier: Modifier = Modifier) {
    Row(
        modifier = modifier.padding(horizontal = 18.dp, vertical = 10.dp),
        horizontalArrangement = Arrangement.Center,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            text = "Press down arrow to open menu",
            color = Color.White,
            fontSize = 20.sp,
            fontWeight = FontWeight.Normal,
        )
        Spacer(Modifier.width(8.dp))
        DownArrowIcon(Modifier.size(18.dp))
    }
}

@Composable
private fun DownArrowIcon(modifier: Modifier = Modifier) {
    Canvas(modifier) {
        val path = Path()
        path.moveTo(size.width * 0.18f, size.height * 0.35f)
        path.lineTo(size.width * 0.5f, size.height * 0.68f)
        path.lineTo(size.width * 0.82f, size.height * 0.35f)
        drawPath(path = path, color = Color.White, style = Stroke(width = size.width * 0.12f, cap = StrokeCap.Round, join = StrokeJoin.Round))
    }
}

@Composable
private fun AlbumMenu(onChangeAlbum: () -> Unit) {
    Box(
        modifier = Modifier.fillMaxSize().background(Color.Black.copy(alpha = 0.9f)).padding(64.dp),
        contentAlignment = Alignment.Center,
    ) {
        Button(onClick = onChangeAlbum) {
            Text("Change album", fontSize = 40.sp, fontWeight = FontWeight.SemiBold)
        }
    }
}

@Composable
private fun AlbumClock(modifier: Modifier = Modifier) {
    val context = LocalContext.current
    val timeFormat = remember(context) { DateFormat.getTimeFormat(context) }
    var timeMillis by remember { mutableStateOf(System.currentTimeMillis()) }
    LaunchedEffect(Unit) {
        while (isActive) {
            timeMillis = System.currentTimeMillis()
            delay(60_000L - timeMillis % 60_000L)
        }
    }
    Text(
        text = timeFormat.format(Date(timeMillis)),
        modifier = modifier.padding(horizontal = 18.dp, vertical = 10.dp),
        color = Color.White,
        fontSize = 46.sp,
        fontWeight = FontWeight.Normal,
    )
}

private val pairingCodeColors = listOf(
    Color(0xFF87CEFA),
    Color(0xFF90EE90),
    Color(0xFFF08080),
    Color(0xFFFFFFE0),
    Color(0xFFFFB6C1),
    Color(0xFFE0FFFF),
    Color(0xFFFAFAD2),
    Color(0xFF87CEFA),
    Color(0xFFD3D3D3),
    Color(0xFFB0C4DE),
    Color(0xFFFFA07A),
    Color(0xFF20B2AA),
    Color(0xFF778899),
    Color(0xFFAFEEEE),
    Color(0xFF7A58C1),
    Color(0xFFFFA500),
    Color(0xFFA0522D),
    Color(0xFF9370DB),
    Color(0xFF008080),
    Color(0xFF808000),
)

private val googleFontsProvider = GoogleFont.Provider(
    providerAuthority = "com.google.android.gms.fonts",
    providerPackage = "com.google.android.gms",
    certificates = R.array.com_google_android_gms_fonts_certs,
)

private val googleSans = GoogleFont("Google Sans")

private val googleSansFontFamily = FontFamily(
    DownloadableFont(googleFont = googleSans, fontProvider = googleFontsProvider, weight = FontWeight.Normal),
    DownloadableFont(googleFont = googleSans, fontProvider = googleFontsProvider, weight = FontWeight.Medium),
    DownloadableFont(googleFont = googleSans, fontProvider = googleFontsProvider, weight = FontWeight.SemiBold),
    DownloadableFont(googleFont = googleSans, fontProvider = googleFontsProvider, weight = FontWeight.Bold),
)

private val googleSansTypography = Typography().let {
    it.copy(
        displayLarge = it.displayLarge.copy(fontFamily = googleSansFontFamily),
        displayMedium = it.displayMedium.copy(fontFamily = googleSansFontFamily),
        displaySmall = it.displaySmall.copy(fontFamily = googleSansFontFamily),
        headlineLarge = it.headlineLarge.copy(fontFamily = googleSansFontFamily),
        headlineMedium = it.headlineMedium.copy(fontFamily = googleSansFontFamily),
        headlineSmall = it.headlineSmall.copy(fontFamily = googleSansFontFamily),
        titleLarge = it.titleLarge.copy(fontFamily = googleSansFontFamily),
        titleMedium = it.titleMedium.copy(fontFamily = googleSansFontFamily),
        titleSmall = it.titleSmall.copy(fontFamily = googleSansFontFamily),
        bodyLarge = it.bodyLarge.copy(fontFamily = googleSansFontFamily),
        bodyMedium = it.bodyMedium.copy(fontFamily = googleSansFontFamily),
        bodySmall = it.bodySmall.copy(fontFamily = googleSansFontFamily),
        labelLarge = it.labelLarge.copy(fontFamily = googleSansFontFamily),
        labelMedium = it.labelMedium.copy(fontFamily = googleSansFontFamily),
        labelSmall = it.labelSmall.copy(fontFamily = googleSansFontFamily),
    )
}

private const val LOG_TAG = "PhotosTv"
private const val DOWN_ARROW_HINT_DURATION = 5000L
