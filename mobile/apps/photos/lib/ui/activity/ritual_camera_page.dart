import "dart:async";
import "dart:io";

import "package:camera/camera.dart";
import "package:flutter/material.dart";
import "package:photos/models/activity/activity_models.dart";
import "package:photos/models/collection/collection.dart";
import "package:photos/models/collection/collection_items.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/theme/colors.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/theme/text_style.dart";
import "package:photos/ui/actions/collection/collection_file_actions.dart";
import "package:photos/ui/actions/collection/collection_sharing_actions.dart";
import "package:photos/ui/activity/activity_screen.dart";
import "package:photos/ui/notification/toast.dart";
import "package:photos/ui/viewer/gallery/collection_page.dart";
import "package:photos/utils/navigation_util.dart";
import "package:receive_sharing_intent/receive_sharing_intent.dart";

enum _CameraScreenMode { capture, review }

class RitualCameraPage extends StatefulWidget {
  const RitualCameraPage({
    super.key,
    required this.ritualId,
    required this.albumId,
  });

  final String ritualId;
  final int? albumId;

  @override
  State<RitualCameraPage> createState() => _RitualCameraPageState();
}

class _RitualCameraPageState extends State<RitualCameraPage>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = <CameraDescription>[];
  CameraDescription? _activeCamera;
  late final PageController _pageController;
  Ritual? _ritual;
  _CameraScreenMode _mode = _CameraScreenMode.capture;
  int _selectedIndex = 0;
  bool _pausedForNavigation = false;
  bool _initializing = true;
  bool _capturing = false;
  bool _saving = false;
  String? _error;
  List<XFile> _captures = <XFile>[];
  Collection? _album;
  int _pointers = 0;
  double _minAvailableZoom = 1.0;
  double _maxAvailableZoom = 1.0;
  double _currentZoom = 1.0;
  double _baseZoom = 1.0;
  Offset? _focusPointRel;
  Timer? _focusHideTimer;
  Timer? _zoomHintTimer;
  bool _showZoomHint = false;
  static const int _maxCaptures = 20;
  late final VoidCallback _activityListener;

  void _ensurePageVisible(int index, {bool animate = false}) {
    if (_captures.isEmpty) return;
    final int capped = index.clamp(0, _captures.length - 1);
    void jump() {
      if (animate) {
        _pageController.animateToPage(
          capped,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      } else {
        _pageController.jumpToPage(capped);
      }
    }

    if (_pageController.hasClients) {
      jump();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          jump();
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pageController = PageController();
    _activityListener = _syncRitualFromActivity;
    activityService.stateNotifier.addListener(_activityListener);
    _loadAlbum();
    _syncRitualFromActivity();
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    activityService.stateNotifier.removeListener(_activityListener);
    _focusHideTimer?.cancel();
    _zoomHintTimer?.cancel();
    _controller?.dispose();
    _pageController.dispose();
    _cleanupCaptures();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      controller.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed && _activeCamera != null) {
      _initializeCamera(_activeCamera);
    }
  }

  Future<void> _loadAlbum() async {
    if (widget.albumId == null) return;
    final collection =
        CollectionsService.instance.getCollectionByID(widget.albumId!);
    if (mounted) {
      setState(() {
        _album = collection;
      });
    }
  }

  void _syncRitualFromActivity() {
    final rituals = activityService.stateNotifier.value.rituals;
    Ritual? match;
    for (final ritual in rituals) {
      if (ritual.id == widget.ritualId) {
        match = ritual;
        break;
      }
    }
    if (match != null && mounted) {
      setState(() {
        _ritual = match;
      });
    }
  }

  Future<void> _initializeCamera([CameraDescription? description]) async {
    if (!flagService.ritualsFlag) return;
    setState(() {
      _initializing = true;
      _error = null;
    });
    try {
      _cameras = _cameras.isEmpty ? await availableCameras() : _cameras;
      if (_cameras.isEmpty) {
        setState(() {
          _error = "No camera found on this device.";
          _initializing = false;
        });
        return;
      }
      final CameraDescription target =
          description ?? _preferredCamera() ?? _cameras.first;
      final bool reuseExisting = _controller != null;
      if (reuseExisting) {
        await _controller!.setDescription(target);
      } else {
        final controller = CameraController(
          target,
          ResolutionPreset.high,
          imageFormatGroup: ImageFormatGroup.jpeg,
          enableAudio: true,
        );
        await controller.initialize();
        _controller = controller;
      }
      if (_controller != null) {
        _minAvailableZoom = await _controller!.getMinZoomLevel();
        _maxAvailableZoom = await _controller!.getMaxZoomLevel();
        _currentZoom = 1.0;
        _baseZoom = 1.0;
        await _controller!.setZoomLevel(_currentZoom);
      }
      if (!mounted) {
        await _controller?.dispose();
        return;
      }
      setState(() {
        _activeCamera = target;
        _initializing = false;
      });
    } catch (e) {
      setState(() {
        _error = "Unable to start camera. Please check permissions.";
        _initializing = false;
      });
    }
  }

  CameraDescription? _preferredCamera() {
    for (final camera in _cameras) {
      if (camera.lensDirection == CameraLensDirection.back) {
        return camera;
      }
    }
    return null;
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _saving) return;
    final current = _activeCamera;
    if (current == null) return;
    final nextIndex = (_cameras.indexOf(current) + 1) % _cameras.length;
    await _initializeCamera(_cameras[nextIndex]);
  }

  Future<void> _takePicture() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _capturing ||
        _saving) {
      return;
    }
    setState(() {
      _capturing = true;
    });
    try {
      final XFile capture = await _controller!.takePicture();
      if (!mounted) return;
      setState(() {
        _captures = List<XFile>.from(_captures)..add(capture);
      });
      _ensurePageVisible(_captures.length - 1, animate: true);
    } catch (_) {
      if (!mounted) return;
      showShortToast(context, "Unable to capture photo. Please try again.");
    } finally {
      if (mounted) {
        setState(() {
          _capturing = false;
        });
      }
    }
  }

  Future<void> _onShutterTap() async {
    if (_captures.length >= _maxCaptures) {
      if (mounted) {
        showShortToast(context, "You can add up to $_maxCaptures photos.");
      }
      return;
    }
    final int previousCount = _captures.length;
    await _takePicture();
    if (!mounted) return;
    final int newCount = _captures.length;
    if (newCount > previousCount) {
      setState(() {
        _selectedIndex = newCount - 1;
        if (previousCount == 0) {
          _mode = _CameraScreenMode.review;
        }
      });
      _ensurePageVisible(_selectedIndex, animate: true);
    }
  }

  Future<void> _onAccept() async {
    if (_captures.isEmpty) {
      showShortToast(context, "Capture at least one photo first.");
      return;
    }
    if (widget.albumId == null) {
      if (!mounted) return;
      final navContext = context;
      ScaffoldMessenger.of(navContext).showSnackBar(
        const SnackBar(
          content: Text(
            "Ritual album missing. Edit the ritual to set an album.",
          ),
        ),
      );
      await _pausePreview();
      if (!mounted) return;
      await routeToPage(navContext, const ActivityScreen())
          .whenComplete(_resumePreview);
      return;
    }
    final List<XFile> pending = List<XFile>.from(_captures);
    bool saved = false;
    setState(() {
      _saving = true;
    });
    try {
      final shared = pending
          .map(
            (file) => SharedMediaFile(
              path: file.path,
              type: SharedMediaType.image,
            ),
          )
          .toList(growable: false);
      final actions = CollectionActions(CollectionsService.instance);
      await actions.addToCollection(
        context,
        widget.albumId!,
        true,
        sharedFiles: shared,
      );
      saved = true;
      if (!mounted) return;
      showShortToast(
        context,
        _album == null ? "Added to album" : "Added to ${_album!.displayName}",
      );
      final collection = _album ??
          CollectionsService.instance.getCollectionByID(widget.albumId!);
      if (collection != null && mounted) {
        final thumbnail =
            await CollectionsService.instance.getCover(collection);
        if (!mounted) return;
        replacePage(
          context,
          CollectionPage(
            CollectionWithThumbnail(
              collection,
              thumbnail,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Couldn't add photos to the album: $e"),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
          if (saved) {
            _captures = <XFile>[];
          }
        });
      }
      if (saved) {
        _cleanupCaptures(pending);
      }
    }
  }

  void _enterReview() {
    if (_captures.isEmpty) return;
    setState(() {
      _mode = _CameraScreenMode.review;
      _selectedIndex = _captures.length - 1;
    });
    _ensurePageVisible(_selectedIndex);
  }

  void _returnToCapture() {
    setState(() {
      _mode = _CameraScreenMode.capture;
    });
  }

  void _removeCapture(int index) {
    if (index < 0 || index >= _captures.length) return;
    final file = _captures[index];
    try {
      File(file.path).deleteSync();
    } catch (_) {
      // best-effort cleanup
    }
    setState(() {
      _captures.removeAt(index);
      if (_captures.isEmpty) {
        _mode = _CameraScreenMode.capture;
        _selectedIndex = 0;
      } else {
        _selectedIndex = index.clamp(0, _captures.length - 1);
      }
    });
    if (_captures.isNotEmpty) {
      _ensurePageVisible(_selectedIndex);
    }
  }

  void _cleanupCaptures([List<XFile>? files]) {
    final targets = files ?? _captures;
    for (final capture in targets) {
      try {
        File(capture.path).deleteSync();
      } catch (_) {
        // ignore cleanup failures
      }
    }
    _captures = <XFile>[];
  }

  Future<void> _pausePreview() async {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.isPreviewPaused) {
      return;
    }
    try {
      await controller.pausePreview();
      _pausedForNavigation = true;
    } catch (_) {
      // ignore pause failures
    }
  }

  Future<void> _resumePreview() async {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        !_pausedForNavigation) {
      return;
    }
    try {
      await controller.resumePreview();
      _pausedForNavigation = false;
    } catch (_) {
      // ignore resume failures
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!flagService.ritualsFlag) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text("Rituals are currently limited to internal users."),
            ),
          ),
        ),
      );
    }
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final bool isReady = _controller != null &&
        _controller!.value.isInitialized &&
        !_initializing;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned.fill(
              child: _mode == _CameraScreenMode.capture
                  ? _buildCameraArea(isReady, colorScheme)
                  : _buildReviewArea(),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildTopBar(textTheme),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _mode == _CameraScreenMode.capture
                  ? _buildCaptureControls(colorScheme, isReady)
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_captures.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                            child: _ThumbnailStrip(
                              captures: _captures,
                              selectedIndex: _selectedIndex,
                              onSelect: (index) {
                                setState(() {
                                  _selectedIndex = index;
                                });
                                _ensurePageVisible(index);
                              },
                              onRemove: _removeCapture,
                            ),
                          ),
                        _buildReviewControls(colorScheme, textTheme),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(EnteTextTheme textTheme) {
    final String title = _ritual?.title.trim().isNotEmpty == true
        ? _ritual!.title.trim()
        : "Take a photo";
    final String icon = _ritual?.icon.isNotEmpty == true ? _ritual!.icon : "📸";
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  icon,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: textTheme.smallBold.copyWith(color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Spacer(),
          _RoundIconButton(
            onTap: () => Navigator.of(context).maybePop(),
            icon: Icons.close,
            background: Colors.white.withValues(alpha: 0.12),
            size: 44,
          ),
        ],
      ),
    );
  }

  Widget _buildCameraArea(bool isReady, EnteColorScheme colorScheme) {
    if (_initializing) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: colorScheme.textMuted,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _initializing ? null : _initializeCamera,
              child: const Text("Try again"),
            ),
            TextButton(
              onPressed: () async {
                await _pausePreview();
                if (!mounted) return;
                await routeToPage(context, const ActivityScreen())
                    .whenComplete(_resumePreview);
              },
              child: const Text("Back to rituals"),
            ),
          ],
        ),
      );
    }
    if (!isReady || _controller == null) {
      return const SizedBox.shrink();
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final mediaOrientation = MediaQuery.of(context).orientation;
        final double previewAspect = mediaOrientation == Orientation.portrait
            ? 1 / _controller!.value.aspectRatio
            : _controller!.value.aspectRatio;

        final Offset? focus = _focusPointRel == null
            ? null
            : Offset(
                _focusPointRel!.dx * constraints.maxWidth,
                _focusPointRel!.dy * (constraints.maxWidth / previewAspect),
              );

        final Size previewSize =
            Size(constraints.maxWidth, constraints.maxWidth / previewAspect);

        return Listener(
          onPointerDown: (_) => _pointers++,
          onPointerUp: (_) => _pointers--,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRect(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: previewSize.width,
                    height: previewSize.height,
                    child: CameraPreview(
                      _controller!,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onScaleStart: _handleScaleStart,
                        onScaleUpdate: _handleScaleUpdate,
                        onTapDown: (details) => _onViewFinderTap(
                          details,
                          BoxConstraints.tight(previewSize),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _GridPainter(),
                  ),
                ),
              ),
              if (focus != null)
                Positioned(
                  left: focus.dx - 24,
                  top: focus.dy - 24,
                  child: AnimatedOpacity(
                    opacity: _focusPointRel == null ? 0 : 1,
                    duration: const Duration(milliseconds: 120),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.9),
                          width: 2,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Positioned(
                left: 12,
                top: 88, // keep below top bar so it stays visible
                child: AnimatedOpacity(
                  opacity: _showZoomHint ? 1 : 0,
                  duration: const Duration(milliseconds: 120),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "${_currentZoom.toStringAsFixed(1)}x",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReviewArea() {
    if (_captures.isEmpty) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Text(
            "No photos yet",
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }
    return Container(
      color: Colors.black,
      child: PageView.builder(
        controller: _pageController,
        itemCount: _captures.length,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        itemBuilder: (context, index) {
          final capture = _captures[index];
          return Image.file(
            File(capture.path),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          );
        },
      ),
    );
  }

  Widget _buildCaptureControls(
    EnteColorScheme colorScheme,
    bool isReady,
  ) {
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    final bool canCapture =
        !_capturing && !_saving && isReady && _captures.length < _maxCaptures;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 32, 16, 26 + bottomPadding),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.60),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 96,
            child: _captures.isEmpty
                ? const SizedBox.shrink()
                : _StackedPreview(
                    captures: _captures,
                    onTap: _enterReview,
                  ),
          ),
          Expanded(
            child: Center(
              child: _ShutterButton(
                enabled: canCapture,
                busy: _capturing,
                onTap: canCapture ? _onShutterTap : null,
              ),
            ),
          ),
          SizedBox(
            width: 96,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: _RoundIconButton(
                    onTap: (_cameras.length < 2 || _saving || _initializing)
                        ? null
                        : _switchCamera,
                    icon: Icons.cameraswitch_rounded,
                    background: Colors.white.withValues(alpha: 0.12),
                    iconColor: Colors.white,
                    size: 48,
                  ),
                ),
                if (_captures.isNotEmpty)
                  Positioned(
                    top: -120, // increased gap above switch button
                    right: 0,
                    child: _ConfirmChip(
                      count: _captures.length,
                      onTap: _enterReview,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewControls(
    EnteColorScheme colorScheme,
    EnteTextTheme textTheme,
  ) {
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 18, 16, 24 + bottomPadding),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.60),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _RoundIconButton(
                onTap: _saving ? null : _returnToCapture,
                icon: Icons.add_photo_alternate_outlined,
                background: Colors.white.withValues(alpha: 0.12),
                iconColor: Colors.white,
                size: 44,
              ),
              const Spacer(),
              ElevatedButton(
                onPressed:
                    (_captures.isNotEmpty && !_saving) ? _onAccept : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _saving
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: colorScheme.textBase,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_outline),
                          const SizedBox(width: 8),
                          Text(
                            "Add to album",
                            style: textTheme.bodyBold
                                .copyWith(color: Colors.black),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleScaleStart(ScaleStartDetails details) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    _baseZoom = _currentZoom;
  }

  Future<void> _handleScaleUpdate(ScaleUpdateDetails details) async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    // Only respond to pinch gestures (2 pointers) to avoid accidental zooms.
    if (_pointers != 2) return;
    final double newZoom =
        (_baseZoom * details.scale).clamp(_minAvailableZoom, _maxAvailableZoom);
    if (newZoom == _currentZoom) return;
    _currentZoom = newZoom;
    try {
      await _controller!.setZoomLevel(_currentZoom);
      _showZoomIndicator();
    } catch (_) {
      // Ignore zoom failures to avoid interrupting capture flow.
    }
  }

  void _onViewFinderTap(
    TapDownDetails details,
    BoxConstraints constraints,
  ) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    final offset = Offset(
      details.localPosition.dx / constraints.maxWidth,
      details.localPosition.dy / constraints.maxHeight,
    );
    try {
      controller.setExposurePoint(offset);
      controller.setFocusPoint(offset);
      _showFocusIndicator(offset);
    } catch (_) {
      // Best effort; not all devices support focus/exposure points.
    }
  }

  void _showFocusIndicator(Offset normalizedOffset) {
    _focusHideTimer?.cancel();
    setState(() {
      _focusPointRel = normalizedOffset;
    });
    _focusHideTimer = Timer(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _focusPointRel = null;
        });
      }
    });
  }

  void _showZoomIndicator() {
    _zoomHintTimer?.cancel();
    setState(() {
      _showZoomHint = true;
    });
    _zoomHintTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() {
          _showZoomHint = false;
        });
      }
    });
  }
}

class _ThumbnailStrip extends StatelessWidget {
  const _ThumbnailStrip({
    required this.captures,
    required this.selectedIndex,
    required this.onSelect,
    required this.onRemove,
  });

  final List<XFile> captures;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: captures.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final capture = captures[index];
          return GestureDetector(
            onTap: () => onSelect(index),
            child: _ReviewThumb(
              file: capture,
              selected: index == selectedIndex,
              onRemove: () => onRemove(index),
            ),
          );
        },
      ),
    );
  }
}

class _StackedPreview extends StatelessWidget {
  const _StackedPreview({
    required this.captures,
    required this.onTap,
  });

  final List<XFile> captures;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final display = captures.length <= 2
        ? List<XFile>.from(captures)
        : captures.sublist(captures.length - 2);
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: 64,
        width: 74,
        child: Stack(
          clipBehavior: Clip.none,
          children: display.asMap().entries.map((entry) {
            final index = entry.key;
            final capture = entry.value;
            final double offset = index * 10;
            return Positioned(
              left: offset,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(capture.path),
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _ConfirmChip extends StatelessWidget {
  const _ConfirmChip({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          color: Color(0xFF08C225),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black38,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Center(
              child: Icon(
                Icons.check,
                color: Colors.white,
                size: 26,
              ),
            ),
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF08C225),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    "$count",
                    style: const TextStyle(
                      color: Color(0xFF08C225),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShutterButton extends StatelessWidget {
  const _ShutterButton({
    required this.onTap,
    required this.enabled,
    required this.busy,
  });

  final VoidCallback? onTap;
  final bool enabled;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 78,
        height: 78,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: Colors.white,
            width: 3,
          ),
        ),
        child: Center(
          child: Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(21),
              color: enabled ? Colors.white : Colors.white30,
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.onTap,
    required this.icon,
    this.background,
    this.iconColor,
    this.size = 44,
  });

  final VoidCallback? onTap;
  final IconData icon;
  final Color? background;
  final Color? iconColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: background ?? Colors.black.withValues(alpha: 0.1),
        ),
        child: Icon(
          icon,
          color: iconColor ?? Colors.white,
        ),
      ),
    );
  }
}

class _ReviewThumb extends StatelessWidget {
  const _ReviewThumb({
    required this.file,
    required this.onRemove,
    required this.selected,
  });

  final XFile file;
  final VoidCallback onRemove;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white,
              width: selected ? 2 : 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(file.path),
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: const Color(0xFFF35151),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: const Icon(
                Icons.close,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 1;
    final double thirdWidth = size.width / 3;
    final double thirdHeight = size.height / 3;
    for (int i = 1; i < 3; i++) {
      canvas.drawLine(
        Offset(thirdWidth * i, 0),
        Offset(thirdWidth * i, size.height),
        paint,
      );
      canvas.drawLine(
        Offset(0, thirdHeight * i),
        Offset(size.width, thirdHeight * i),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
