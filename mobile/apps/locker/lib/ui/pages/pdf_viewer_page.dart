import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:ente_components/ente_components.dart';
import 'package:ente_strings/ente_strings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:logging/logging.dart';
import 'package:pdfx/pdfx.dart' as pdf;

enum _ViewerAction { download, openExternally }

class PdfViewerPage extends StatefulWidget {
  const PdfViewerPage({
    super.key,
    required this.localFile,
    required this.fileName,
    required this.onOpenExternally,
    this.openPdf = pdf.PdfDocument.openFile,
    this.onDownload,
    this.onShare,
  });

  final File localFile;
  final String fileName;
  final Future<void> Function(BuildContext) onOpenExternally;
  final Future<pdf.PdfDocument> Function(String) openPdf;
  final Future<void> Function(BuildContext)? onDownload;
  final Future<void> Function(BuildContext)? onShare;

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  static final _logger = Logger('PdfViewerPage');
  static const _maxImageDimension = 3072;
  static const _maxRenderPixels = 4 * 1024 * 1024;
  final _pdfTransformation = TransformationController();
  final _pdfContentKey = GlobalKey();
  final _pdfPage = ValueNotifier(1);
  final _pageAspectRatios = <int, double>{};
  (double, double)? _pdfLayout;
  List<double> _pdfPageOffsets = [];
  Size _pdfViewport = Size.zero;
  pdf.PdfDocument? _document;
  Future<void>? _pendingRender;
  bool _loading = false;
  bool _failed = false;
  bool _pdfInteracting = false;
  double _pdfRenderScale = 1;
  int _pdfLayoutRevision = 0;
  bool _toolbarVisible = true;

  double get _toolbarHeight => math.max(
    kToolbarHeight,
    MediaQuery.textScalerOf(context).scale(20) * 1.4,
  );

  void _setToolbarVisible(bool visible) {
    if (_toolbarVisible == visible ||
        _loading ||
        _failed ||
        MediaQuery.accessibleNavigationOf(context)) {
      return;
    }
    setState(() => _toolbarVisible = visible);
  }

  void _onZoom(ScaleUpdateDetails details) {
    if (details.pointerCount > 1 && (details.scale - 1).abs() > 0.01) {
      _setToolbarVisible(false);
    }
  }

  PreferredSizeWidget _overlayToolbar(AppBar toolbar) {
    final visible =
        _toolbarVisible ||
        _loading ||
        _failed ||
        MediaQuery.accessibleNavigationOf(context);
    return PreferredSize(
      preferredSize: toolbar.preferredSize,
      child: IgnorePointer(
        ignoring: !visible,
        child: ExcludeFocus(
          excluding: !visible,
          child: ExcludeSemantics(
            excluding: !visible,
            child: AnimatedOpacity(
              opacity: visible ? 1 : 0,
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 180),
              child: toolbar,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _pdfTransformation.addListener(_updatePdfPage);
    _loading = true;
    _pendingRender = _openDocument();
  }

  Future<void> _openDocument() async {
    try {
      _document = await widget.openPdf(widget.localFile.path);
      if (_document!.pagesCount < 1) {
        final document = _document!;
        _document = null;
        await document.close();
        throw StateError('PDF has no pages');
      }
      for (var number = 1; number <= _document!.pagesCount; number++) {
        if (!mounted) return;
        try {
          final page = await _document!.getPage(number);
          try {
            var ratio = page.width / page.height;
            if (!ratio.isFinite || ratio <= 0) {
              throw StateError('Invalid PDF page dimensions');
            }
            if (defaultTargetPlatform == TargetPlatform.iOS) {
              // pdfx reports unrotated dimensions on iOS, even after rendering.
              final scale = 64 / math.max(page.width, page.height);
              final preview = await page.render(
                width: math.max(1.0, page.width * scale),
                height: math.max(1.0, page.height * scale),
                format: pdf.PdfPageImageFormat.png,
              );
              if (preview == null) throw StateError('PDF page cannot be sized');
              final buffer = await ui.ImmutableBuffer.fromUint8List(
                preview.bytes,
              );
              try {
                final descriptor = await ui.ImageDescriptor.encoded(buffer);
                if ((descriptor.width > descriptor.height) != (ratio > 1)) {
                  ratio = 1 / ratio;
                }
                descriptor.dispose();
              } finally {
                buffer.dispose();
              }
            }
            _pageAspectRatios[number] = ratio;
          } finally {
            await page.close();
          }
        } catch (error, stack) {
          _logger.warning('Failed to measure PDF page $number', error, stack);
          _pageAspectRatios[number] = 3 / 4;
        }
      }
      if (mounted) setState(() => _loading = false);
    } catch (error, stack) {
      _logger.warning('Failed to open PDF document', error, stack);
      if (mounted) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
    }
  }

  Future<MemoryImage?> _renderPage(
    int number,
    double renderWidth,
    bool Function() isActive,
  ) {
    // Android permits only one open native page per document at a time.
    final result = _pendingRender!.then<MemoryImage?>((_) async {
      if (!mounted || !isActive()) return null;
      final page = await _document!.getPage(number);
      try {
        if (!mounted || !isActive()) return null;
        final visualWidth = _pageAspectRatios[number]! > 1
            ? math.max(page.width, page.height)
            : math.min(page.width, page.height);
        final scale = math.min(
          renderWidth / visualWidth,
          math.min(
            _maxImageDimension / math.max(page.width, page.height),
            math.sqrt(_maxRenderPixels / (page.width * page.height)),
          ),
        );
        final rendered = await page.render(
          width: math.max(1.0, page.width * scale),
          height: math.max(1.0, page.height * scale),
          format: pdf.PdfPageImageFormat.png,
          backgroundColor: '#ffffff',
        );
        if (rendered == null) {
          throw StateError('PDF page could not be rendered');
        }
        if (!mounted || !isActive()) return null;
        return MemoryImage(rendered.bytes);
      } finally {
        await page.close();
      }
    });
    _pendingRender = result.then<void>(
      (_) {},
      onError: (Object error, StackTrace stack) {
        _logger.warning('Failed to render PDF page', error, stack);
      },
    );
    return result;
  }

  Future<void> _closeDocument() async {
    try {
      // Native pages must finish rendering and close before their document.
      await _pendingRender;
      await _document?.close();
    } catch (error, stack) {
      _logger.warning('Failed to close PDF document', error, stack);
    }
  }

  @override
  void dispose() {
    unawaited(_closeDocument());
    _pdfTransformation.dispose();
    _pdfPage.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.componentColors;
    final l10n = context.strings;
    return Scaffold(
      backgroundColor: colors.backgroundBase,
      extendBodyBehindAppBar: true,
      appBar: _overlayToolbar(
        AppBar(
          backgroundColor: colors.backgroundBase,
          foregroundColor: colors.textBase,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          toolbarHeight: _toolbarHeight,
          leading: IconButtonComponent(
            icon: const HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01),
            variant: IconButtonComponentVariant.unfilled,
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onTap: () => Navigator.maybePop(context),
          ),
          title: Tooltip(
            message: widget.fileName,
            child: Text(
              widget.fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyles.display3.copyWith(color: colors.textBase),
            ),
          ),
          actions: [
            if (widget.onShare != null)
              IconButtonComponent(
                icon: const HugeIcon(icon: HugeIcons.strokeRoundedShare08),
                variant: IconButtonComponentVariant.unfilled,
                tooltip: l10n.shareLink,
                onTap: () => widget.onShare!(context),
              ),
            Builder(
              builder: (buttonContext) => IconButtonComponent(
                icon: const HugeIcon(icon: HugeIcons.strokeRoundedMoreVertical),
                variant: IconButtonComponentVariant.unfilled,
                tooltip: l10n.more,
                shouldSurfaceExecutionStates: false,
                onTap: () async {
                  final action = await showEntePopupMenu<_ViewerAction>(
                    context: buttonContext,
                    options: [
                      if (widget.onDownload != null)
                        EntePopupMenuOption(
                          value: _ViewerAction.download,
                          label: l10n.download,
                        ),
                      EntePopupMenuOption(
                        value: _ViewerAction.openExternally,
                        label: l10n.openInAnotherApp,
                      ),
                    ],
                  );
                  if (!context.mounted || action == null) return;
                  switch (action) {
                    case _ViewerAction.download:
                      await widget.onDownload!(context);
                    case _ViewerAction.openExternally:
                      await widget.onOpenExternally(context);
                  }
                },
              ),
            ),
          ],
        ),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: () => _setToolbarVisible(!_toolbarVisible),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _failed
                ? _buildError(context)
                : _buildPdf(context),
          ),
        ),
      ),
    );
  }

  int _pageAt(double y) {
    var low = 0;
    var high = _pdfPageOffsets.length - 2;
    while (low < high) {
      final middle = (low + high + 1) ~/ 2;
      if (_pdfPageOffsets[middle] <= y) {
        low = middle;
      } else {
        high = middle - 1;
      }
    }
    return low;
  }

  void _updatePdfPage() {
    if (_pdfPageOffsets.length < 2) return;
    final center = _pdfTransformation.toScene(
      Offset(_pdfViewport.width / 2, _pdfViewport.height / 2),
    );
    _pdfPage.value = _pageAt(center.dy) + 1;
  }

  void _scrollPdf(double direction) {
    if (_pdfInteracting) {
      return;
    }
    final matrix = _pdfTransformation.value.clone();
    final translation = matrix.getTranslation();
    final height = math.max(
      _pdfViewport.height,
      _pdfPageOffsets.last - Spacing.md + Spacing.lg,
    );
    final minimum = math.min(
      0.0,
      _pdfViewport.height - height * matrix.getMaxScaleOnAxis(),
    );
    final step = math.max(1.0, _pdfViewport.height - _toolbarHeight) * 0.8;
    final y = (translation.y + direction * step).clamp(minimum, 0.0);
    if (y == translation.y) {
      return;
    }
    matrix.setTranslationRaw(translation.x, y.toDouble(), 0);
    // Cancel any old fling before applying an accessibility scroll.
    setState(() => _pdfLayoutRevision++);
    _pdfTransformation.value = matrix;
  }

  double _renderWidth(int index, double pixelWidth, bool visible) {
    final ratio = _pageAspectRatios[index + 1]!;
    return math.min(
      (pixelWidth * (visible ? _pdfRenderScale : 1)).ceilToDouble(),
      math.min(
        _maxImageDimension * math.min(1.0, ratio),
        math.sqrt(_maxRenderPixels * ratio),
      ),
    );
  }

  Widget _buildPdf(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      // Keep the reading position when the viewport or toolbar size changes.
      final anchor = _pdfTransformation.toScene(
        _pdfViewport.center(Offset.zero),
      );
      final anchorPage = _pageAt(anchor.dy);
      final anchorFraction = _pdfPageOffsets.isEmpty
          ? null
          : (anchor.dy - _pdfPageOffsets[anchorPage]) /
                (_pdfPageOffsets[anchorPage + 1] -
                    _pdfPageOffsets[anchorPage] -
                    Spacing.md);
      final viewportShift = (constraints.maxHeight - _pdfViewport.height) / 2;
      if (_pdfViewport != constraints.biggest) {
        _pdfInteracting = false;
        _pdfRenderScale = _pdfTransformation.value.getMaxScaleOnAxis();
        _pdfLayoutRevision++;
      }
      _pdfViewport = constraints.biggest;
      final width = constraints.maxWidth - Spacing.lg * 2;
      final layout = (width, _toolbarHeight);
      if (_pdfLayout != layout) {
        _pdfPageOffsets = [_toolbarHeight + Spacing.lg];
        for (var page = 1; page <= _document!.pagesCount; page++) {
          _pdfPageOffsets.add(
            _pdfPageOffsets.last +
                width / _pageAspectRatios[page]! +
                Spacing.md,
          );
        }
        _pdfLayout = layout;
      }
      final height = math.max(
        constraints.maxHeight,
        _pdfPageOffsets.last - Spacing.md + Spacing.lg,
      );
      final anchorShift = anchorFraction == null
          ? 0.0
          : _pdfPageOffsets[anchorPage] +
                anchorFraction *
                    (_pdfPageOffsets[anchorPage + 1] -
                        _pdfPageOffsets[anchorPage] -
                        Spacing.md) -
                anchor.dy;
      final matrix = _pdfTransformation.value.clone();
      final scale = matrix.getMaxScaleOnAxis();
      final translation = matrix.getTranslation();
      final x = translation.x.clamp(
        math.min(0.0, constraints.maxWidth * (1 - scale)),
        0.0,
      );
      final y =
          (translation.y == 0
                  ? 0.0
                  : translation.y + viewportShift - anchorShift * scale)
              .clamp(constraints.maxHeight - height * scale, 0.0);
      if (x != translation.x || y != translation.y) {
        matrix.setTranslationRaw(x.toDouble(), y.toDouble(), 0);
        _pdfTransformation.value = matrix;
      }
      _updatePdfPage();
      return AnimatedBuilder(
        animation: _pdfTransformation,
        builder: (context, child) {
          final matrix = _pdfTransformation.value;
          final y = matrix.getTranslation().y;
          final minimum =
              constraints.maxHeight - height * matrix.getMaxScaleOnAxis();
          return Semantics(
            container: true,
            onScrollUp: y > minimum ? () => _scrollPdf(-1) : null,
            onScrollDown: y < 0 ? () => _scrollPdf(1) : null,
            child: child,
          );
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            InteractiveViewer.builder(
              // Reflow invalidates the old gesture and inertia coordinates.
              key: ValueKey('pdf-layout-$_pdfLayoutRevision'),
              transformationController: _pdfTransformation,
              alignment: Alignment.topLeft,
              minScale: 1,
              maxScale: 4,
              onInteractionUpdate: _onZoom,
              onInteractionStart: (_) => _pdfInteracting = true,
              onInteractionEnd: (_) {
                _pdfInteracting = false;
                final scale = _pdfTransformation.value.getMaxScaleOnAxis();
                if (_pdfRenderScale != scale) {
                  setState(() => _pdfRenderScale = scale);
                }
              },
              builder: (context, viewport) {
                final first = _pageAt(viewport.point0.y);
                final last = _pageAt(viewport.point2.y);
                final pixelWidth =
                    width * MediaQuery.devicePixelRatioOf(context);
                return SizedBox(
                  // Keep rendered tiles alive when the gesture state is reset.
                  key: _pdfContentKey,
                  width: constraints.maxWidth,
                  height: height,
                  child: Stack(
                    children: [
                      for (final index in [
                        for (var index = first; index <= last; index++) index,
                        if (first > 0) first - 1,
                        if (last < _document!.pagesCount - 1) last + 1,
                      ])
                        Positioned(
                          key: ValueKey(index),
                          top: _pdfPageOffsets[index],
                          left: Spacing.lg,
                          right: Spacing.lg,
                          height:
                              _pdfPageOffsets[index + 1] -
                              _pdfPageOffsets[index] -
                              Spacing.md,
                          child: _PdfPageTile(
                            number: index + 1,
                            renderWidth: _renderWidth(
                              index,
                              pixelWidth,
                              index >= first && index <= last,
                            ),
                            renderPage: _renderPage,
                            errorBuilder: _buildError,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: Spacing.sm),
                child: IgnorePointer(
                  child: ValueListenableBuilder<int>(
                    valueListenable: _pdfPage,
                    builder: (context, page, _) => Semantics(
                      label: context.strings.scanPageOfTotal(
                        current: page,
                        total: _document!.pagesCount,
                      ),
                      child: ExcludeSemantics(
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: constraints.maxWidth / 2,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: Spacing.md,
                            vertical: Spacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: context.componentColors.fillDark,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$page / ${_document!.pagesCount}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyles.mini.copyWith(
                              color: context.componentColors.textBase,
                            ),
                          ),
                        ),
                      ),
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

  Widget _buildError(BuildContext context) => Center(
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.strings.errorOpeningFile,
            textAlign: TextAlign.center,
            style: TextStyles.body.copyWith(
              color: context.componentColors.textBase,
            ),
          ),
          const SizedBox(height: Spacing.lg),
          ButtonComponent(
            label: context.strings.openInAnotherApp,
            onTap: () => widget.onOpenExternally(context),
          ),
        ],
      ),
    ),
  );
}

class _PdfPageTile extends StatefulWidget {
  const _PdfPageTile({
    required this.number,
    required this.renderWidth,
    required this.renderPage,
    required this.errorBuilder,
  });

  final int number;
  final double renderWidth;
  final Future<MemoryImage?> Function(int, double, bool Function()) renderPage;
  final WidgetBuilder errorBuilder;

  @override
  State<_PdfPageTile> createState() => _PdfPageTileState();
}

class _PdfPageTileState extends State<_PdfPageTile> {
  MemoryImage? _rendered;
  bool _failed = false;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(_PdfPageTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.renderWidth != oldWidget.renderWidth) unawaited(_load());
  }

  Future<void> _load() async {
    final request = ++_request;
    try {
      final rendered = await widget.renderPage(
        widget.number,
        widget.renderWidth,
        () => mounted && request == _request,
      );
      if (mounted && request == _request) {
        final previous = _rendered;
        setState(() {
          _rendered = rendered;
          _failed = false;
        });
        if (previous != rendered) unawaited(previous?.evict());
      } else {
        unawaited(rendered?.evict());
      }
    } catch (_) {
      if (mounted && request == _request) {
        setState(() => _failed = _rendered == null);
      }
    }
  }

  @override
  void dispose() {
    _rendered?.evict();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _failed
      ? widget.errorBuilder(context)
      : _rendered == null
      ? const Center(child: CircularProgressIndicator())
      : Image(
          image: _rendered!,
          gaplessPlayback: true,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stack) => widget.errorBuilder(context),
        );
}
