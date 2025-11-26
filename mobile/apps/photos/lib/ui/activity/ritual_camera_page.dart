import "dart:async";
import "dart:io";

import "package:camera/camera.dart";
import "package:flutter/material.dart";
import "package:photos/models/collection/collection.dart";
import "package:photos/models/collection/collection_items.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/theme/colors.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/actions/collection/collection_file_actions.dart";
import "package:photos/ui/actions/collection/collection_sharing_actions.dart";
import "package:photos/ui/activity/activity_screen.dart";
import "package:photos/ui/notification/toast.dart";
import "package:photos/ui/viewer/gallery/collection_page.dart";
import "package:photos/utils/navigation_util.dart";
import "package:receive_sharing_intent/receive_sharing_intent.dart";

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAlbum();
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusHideTimer?.cancel();
    _zoomHintTimer?.cancel();
    _controller?.dispose();
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

  Future<void> _onAccept() async {
    if (_captures.isEmpty) {
      showShortToast(context, "Capture at least one photo first.");
      return;
    }
    if (widget.albumId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text("Ritual album missing. Edit the ritual to set an album."),
        ),
      );
      await routeToPage(context, const ActivityScreen());
      return;
    }
    final List<XFile> pending = List<XFile>.from(_captures);
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
      _cleanupCaptures(pending);
      if (mounted) {
        setState(() {
          _saving = false;
          _captures = <XFile>[];
        });
      }
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

  void _onDiscard() {
    _cleanupCaptures();
    setState(() {
      _captures = <XFile>[];
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!flagService.ritualsFlag) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Ritual capture"),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text("Rituals are currently limited to internal users."),
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
      appBar: AppBar(
        title: Text(_album?.displayName ?? "Ritual capture"),
        actions: [
          IconButton(
            onPressed: _captures.isEmpty || _saving ? null : _onDiscard,
            icon: const Icon(Icons.refresh),
            tooltip: "Discard and retake",
          ),
          IconButton(
            onPressed: (_cameras.length < 2 || _saving || _initializing)
                ? null
                : _switchCamera,
            icon: const Icon(Icons.cameraswitch_rounded),
            tooltip: "Switch camera",
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                color: Colors.black,
                child: Center(
                  child: _buildCameraArea(isReady, colorScheme),
                ),
              ),
            ),
            if (_album != null || widget.albumId != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.photo_album_outlined,
                      color: colorScheme.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _album?.displayName ??
                            "Album ID ${widget.albumId ?? "-"}",
                        style: textTheme.smallMuted,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            if (_captures.isNotEmpty) _CapturedStrip(captures: _captures),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: (_captures.isNotEmpty && !_saving)
                          ? _onDiscard
                          : null,
                      child: const Text("Retake"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _CaptureButton(
                    onTap: _capturing || _saving || !isReady
                        ? null
                        : () async {
                            await _takePicture();
                          },
                    busy: _capturing,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          (_captures.isNotEmpty && !_saving) ? _onAccept : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary500,
                        foregroundColor: colorScheme.backgroundBase,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _saving
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: colorScheme.backgroundBase,
                              ),
                            )
                          : const Text("Add to album"),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraArea(bool isReady, EnteColorScheme colorScheme) {
    if (_initializing) {
      return const CircularProgressIndicator();
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
              onPressed: () {
                routeToPage(context, const ActivityScreen());
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
                    width: constraints.maxWidth,
                    height: constraints.maxWidth / previewAspect,
                    child: CameraPreview(
                      _controller!,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onScaleStart: _handleScaleStart,
                        onScaleUpdate: _handleScaleUpdate,
                        onTapDown: (details) => _onViewFinderTap(
                          details,
                          BoxConstraints.tight(
                            Size(
                              constraints.maxWidth,
                              constraints.maxWidth / previewAspect,
                            ),
                          ),
                        ),
                      ),
                    ),
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
                top: 12,
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

class _CapturedStrip extends StatelessWidget {
  const _CapturedStrip({required this.captures});

  final List<XFile> captures;

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        itemCount: captures.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final file = captures[index];
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 80,
              height: 80,
              color: colorScheme.fillFaintPressed,
              child: Image.file(
                File(file.path),
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CaptureButton extends StatelessWidget {
  const _CaptureButton({
    required this.onTap,
    required this.busy,
  });

  final VoidCallback? onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: onTap == null
              ? colorScheme.fillMuted
              : colorScheme.backgroundBase,
          border: Border.all(
            color: colorScheme.primary500,
            width: 3,
          ),
        ),
        child: Center(
          child: busy
              ? CircularProgressIndicator(
                  color: colorScheme.primary500,
                  strokeWidth: 3,
                )
              : Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: onTap == null
                        ? colorScheme.strokeFaint
                        : colorScheme.primary500,
                  ),
                ),
        ),
      ),
    );
  }
}
