import "dart:async";
import "dart:math" as math;

import "package:ente_components/ente_components.dart";
import "package:flutter/material.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:hugeicons/hugeicons.dart";
import "package:photos/ui/settings/developer_settings_tap_area.dart";
import "package:rive/rive.dart" as rive;

enum OnboardingIllustration {
  login("assets/onboarding_login.riv", 0.535, -30.8, 3.9),
  signUp("assets/onboarding_login.riv", 0.44, -53.9, 3.6),
  email("assets/onboarding_email.riv", 0.533, -25.8, 13.5),
  password("assets/onboarding_password.riv", 0.5289, -36.2, -2.1),
  forgotPassword("assets/onboarding_forgot_password.riv", 0.5294, -28.5, -6.1),
  key("assets/onboarding_key.riv", 0.5325, -31, 6.7),
  recoveryKey("assets/onboarding_key.riv", 0.4714, -29.4, -4.6),
  pricing("assets/onboarding_pricing.riv", 0.535, -20.8, 7.9);

  const OnboardingIllustration(
    this.asset,
    this.scale,
    this.topOffset,
    this.centerOffset,
  );

  static const double artboardWidth = 500;
  static const double artboardHeight = 509;

  final String asset;
  final double scale;
  final double topOffset;
  final double centerOffset;

  double get width => artboardWidth * scale;
  double get height => artboardHeight * scale;
}

enum OnboardingTitleBarStyle { card, header }

class OnboardingPageScaffold extends StatefulWidget {
  const OnboardingPageScaffold({
    super.key,
    required this.title,
    required this.illustration,
    required this.body,
    this.actions = const [],
    this.headerHeight = defaultHeaderHeight,
    this.showBackButton = true,
    this.titleBarStyle = OnboardingTitleBarStyle.card,
    this.headerTrailing,
    this.isBodyCentered = false,
    this.pinActions = false,
    this.showDeveloperSettingsTapArea = false,
  });

  static const double defaultHeaderHeight = 159;
  static const double compactHeaderHeight = 82;
  static const double planHeaderHeight = 148;
  static const double horizontalPadding = Spacing.xxl;

  final String title;
  final OnboardingIllustration illustration;
  final Widget body;
  final List<Widget> actions;
  final double headerHeight;
  final bool showBackButton;
  final OnboardingTitleBarStyle titleBarStyle;
  final Widget? headerTrailing;
  final bool isBodyCentered;

  // Only pin actions on pages that never show the keyboard.
  final bool pinActions;
  final bool showDeveloperSettingsTapArea;

  @override
  State<OnboardingPageScaffold> createState() => OnboardingPageScaffoldState();
}

class OnboardingPageScaffoldState extends State<OnboardingPageScaffold> {
  static const double _cardRadius = Radii.bottomSheet;
  static const double _titleBarHeight = 48;
  static const double _titleBarTopInset = 33;
  static const double _titleBarBottomInset = 17;
  static const double _inlineTitleTopInset = 36;
  static const double _inlineTitleBottomInset = 20;
  static const double _headerBarCenter = 33;
  static const double _headerBarLeftInset = 10;
  static const double _headerBarRightInset = 11;
  static const double _footerSpacing = Spacing.lg;
  static const double _footerInset = Spacing.xxl;

  rive.FileLoader? _fileLoader;
  rive.ViewModelInstance? _viewModel;
  String? _latestTrigger;
  Timer? _deferredTrigger;
  DateTime _entryCompletesAt = DateTime.now();
  ModalRoute<dynamic>? _route;
  bool _isIllustrationHidden = false;
  bool _hasBuilt = false;
  bool _hasExited = false;
  int _illustrationGeneration = 0;

  // Wait for entry to finish; interrupting it can freeze the pose.
  void trigger(String name) {
    _latestTrigger = name;
    if (_viewModel == null) {
      return;
    }
    _deferredTrigger?.cancel();
    final remaining = _entryCompletesAt.difference(DateTime.now());
    if (remaining <= Duration.zero) {
      _trigger(name);
      return;
    }
    _deferredTrigger = Timer(remaining, () {
      if (mounted) _trigger(name);
    });
  }

  @override
  void initState() {
    super.initState();
    _fileLoader = _loadIllustration();
  }

  // Keep onboarding usable when the native Rive runtime is unavailable.
  rive.FileLoader? _loadIllustration() {
    try {
      return rive.FileLoader.fromAsset(
        widget.illustration.asset,
        riveFactory: rive.Factory.flutter,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != _route) {
      _route?.animation?.removeStatusListener(_onRouteAnimationStatus);
      _route?.secondaryAnimation?.removeStatusListener(
        _onSecondaryAnimationStatus,
      );
      _route = route;
      route?.animation?.addStatusListener(_onRouteAnimationStatus);
      route?.secondaryAnimation?.addStatusListener(_onSecondaryAnimationStatus);
    }
  }

  @override
  void dispose() {
    _route?.animation?.removeStatusListener(_onRouteAnimationStatus);
    _route?.secondaryAnimation?.removeStatusListener(
      _onSecondaryAnimationStatus,
    );
    _deferredTrigger?.cancel();
    _viewModel = null;
    _fileLoader?.dispose();
    super.dispose();
  }

  void _onRouteAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.reverse) {
      _triggerExit();
    } else if (status == AnimationStatus.forward) {
      _restartIllustration();
    }
  }

  void _onSecondaryAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.forward) {
      _triggerExit();
    } else if (status == AnimationStatus.reverse ||
        status == AnimationStatus.dismissed) {
      _restartIllustration();
    }
  }

  void _restartIllustration() {
    if (!_hasExited) return;
    _hasExited = false;
    _deferredTrigger?.cancel();
    if (_viewModel == null) return;
    _viewModel = null;
    setState(() {
      _illustrationGeneration++;
    });
  }

  void _onLoaded(rive.RiveLoaded state) {
    _viewModel = state.viewModelInstance;
    final artboard = state.controller.artboard;
    for (var i = 0; i < artboard.animationCount(); i++) {
      final animation = artboard.animationAt(i);
      if (animation.name.toLowerCase() == "entry") {
        _entryDuration = Duration(
          milliseconds: (animation.duration * 1000).round(),
        );
      }
      animation.dispose();
    }
    _playEntry();
    final latest = _latestTrigger;
    if (latest != null) trigger(latest);
  }

  Duration _entryDuration = const Duration(seconds: 5);

  void _playEntry() {
    _entryCompletesAt = DateTime.now().add(_entryDuration);
    _trigger("entry");
  }

  void _triggerExit() {
    if (_hasExited) return;
    _hasExited = true;
    _trigger("exit");
  }

  void _trigger(String name) {
    _viewModel?.trigger(name)?.trigger();
  }

  void _onHeaderAnimationEnd() {
    if (!mounted) return;
    final isKeyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    if (_isIllustrationHidden == isKeyboardOpen) return;
    setState(() {
      _isIllustrationHidden = isKeyboardOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.componentColors;
    final mediaQuery = MediaQuery.of(context);
    final isKeyboardOpen = mediaQuery.viewInsets.bottom > 0;
    final headerHeight =
        mediaQuery.padding.top + (isKeyboardOpen ? 0 : widget.headerHeight);
    if (!isKeyboardOpen) {
      _isIllustrationHidden = false;
    } else if (!_hasBuilt) {
      _isIllustrationHidden = true;
    }
    _hasBuilt = true;

    return Scaffold(
      backgroundColor: colors.green,
      resizeToAvoidBottomInset: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: constraints.maxHeight),
                child: AnimatedContainer(
                  duration: Motion.slow,
                  curve: Curves.easeOutCubic,
                  height: headerHeight,
                  onEnd: _onHeaderAnimationEnd,
                  child: _buildHeader(colors, mediaQuery),
                ),
              ),
              Expanded(child: _buildCard(context, colors, mediaQuery)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(ColorTokens colors, MediaQueryData mediaQuery) {
    final illustration = widget.illustration;
    final hasHeaderBar = widget.titleBarStyle == OnboardingTitleBarStyle.header;
    final canPop = widget.showBackButton && (_route?.canPop ?? false);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          bottom: -_cardRadius,
          child: _OnboardingBackdrop(color: colors.green),
        ),
        if (hasHeaderBar)
          Positioned(
            top:
                mediaQuery.padding.top + _headerBarCenter - _titleBarHeight / 2,
            left: mediaQuery.padding.left + _headerBarLeftInset,
            right: mediaQuery.padding.right + _headerBarRightInset,
            height: _titleBarHeight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: _titleBarHeight,
                  child: canPop
                      ? _backButton(context, colors.specialWhite)
                      : null,
                ),
                SizedBox(width: _titleBarHeight, child: widget.headerTrailing),
              ],
            ),
          ),
        if (_fileLoader != null)
          Positioned(
            top: mediaQuery.padding.top + illustration.topOffset,
            left: 0,
            right: 0,
            height: illustration.height,
            child: IgnorePointer(
              child: Visibility(
                visible: !_isIllustrationHidden,
                maintainState: true,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Transform.translate(
                    offset: Offset(illustration.centerOffset, 0),
                    child: SizedBox(
                      width: illustration.width,
                      height: illustration.height,
                      child: rive.RiveWidgetBuilder(
                        key: ValueKey(_illustrationGeneration),
                        fileLoader: _fileLoader!,
                        dataBind: rive.DataBind.auto(),
                        onLoaded: _onLoaded,
                        builder: (BuildContext context, rive.RiveState state) {
                          if (state is rive.RiveLoaded) {
                            return rive.RiveWidget(
                              controller: state.controller,
                              fit: rive.Fit.contain,
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _backButton(BuildContext context, Color color) {
    return IconButtonComponent(
      variant: IconButtonComponentVariant.unfilled,
      size: _titleBarHeight,
      iconSize: IconSizes.medium,
      icon: HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft02, color: color),
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      onTap: () => Navigator.of(context).maybePop(),
    );
  }

  Widget _buildCard(
    BuildContext context,
    ColorTokens colors,
    MediaQueryData mediaQuery,
  ) {
    final hasCardTitleBar =
        widget.titleBarStyle == OnboardingTitleBarStyle.card;
    final canPop =
        hasCardTitleBar && widget.showBackButton && (_route?.canPop ?? false);
    final title = Text(
      widget.title,
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyles.display2.copyWith(color: colors.textBase),
    );
    final titleContent = widget.showDeveloperSettingsTapArea
        ? DeveloperSettingsTapArea(
            behavior: HitTestBehavior.translucent,
            child: title,
          )
        : title;
    final hasPinnedFooter = widget.actions.isNotEmpty && widget.pinActions;
    final hasScrollingFooter = widget.actions.isNotEmpty && !widget.pinActions;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.backgroundBase,
        border: Border.all(color: colors.strokeDark),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(_cardRadius),
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                if (hasCardTitleBar)
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      mediaQuery.padding.left +
                          OnboardingPageScaffold.horizontalPadding -
                          Spacing.md,
                      _titleBarTopInset,
                      mediaQuery.padding.right +
                          OnboardingPageScaffold.horizontalPadding -
                          Spacing.md,
                      _titleBarBottomInset,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        children: [
                          SizedBox(
                            width: _titleBarHeight,
                            height: _titleBarHeight,
                            child: canPop
                                ? _backButton(context, colors.textBase)
                                : null,
                          ),
                          Expanded(child: titleContent),
                          const SizedBox(width: _titleBarHeight),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      mediaQuery.padding.left +
                          OnboardingPageScaffold.horizontalPadding,
                      _inlineTitleTopInset,
                      mediaQuery.padding.right +
                          OnboardingPageScaffold.horizontalPadding,
                      _inlineTitleBottomInset,
                    ),
                    sliver: SliverToBoxAdapter(child: titleContent),
                  ),
                SliverPadding(
                  padding: EdgeInsets.only(
                    left:
                        mediaQuery.padding.left +
                        OnboardingPageScaffold.horizontalPadding,
                    right:
                        mediaQuery.padding.right +
                        OnboardingPageScaffold.horizontalPadding,
                  ),
                  sliver: SliverLayoutBuilder(
                    builder: (context, constraints) {
                      final remaining =
                          constraints.viewportMainAxisExtent -
                          constraints.precedingScrollExtent;
                      return SliverToBoxAdapter(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: math.max(0, remaining),
                          ),
                          child: Column(
                            mainAxisAlignment: hasScrollingFooter
                                ? MainAxisAlignment.spaceBetween
                                : widget.isBodyCentered
                                ? MainAxisAlignment.center
                                : MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (widget.isBodyCentered)
                                const SizedBox.shrink(),
                              widget.body,
                              if (hasScrollingFooter)
                                _buildFooter(mediaQuery, inline: true),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          if (hasPinnedFooter) _buildFooter(mediaQuery, inline: false),
        ],
      ),
    );
  }

  Widget _buildFooter(MediaQueryData mediaQuery, {required bool inline}) {
    final horizontalInset = inline ? 0.0 : _footerInset;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalInset + (inline ? 0 : mediaQuery.padding.left),
        _footerInset,
        horizontalInset + (inline ? 0 : mediaQuery.padding.right),
        _footerInset +
            (mediaQuery.viewInsets.bottom > 0 ? 0 : mediaQuery.padding.bottom),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < widget.actions.length; i++) ...[
            if (i > 0) const SizedBox(height: _footerSpacing),
            widget.actions[i],
          ],
        ],
      ),
    );
  }
}

class OnboardingAccountPrompt extends StatelessWidget {
  const OnboardingAccountPrompt({
    super.key,
    required this.question,
    required this.actionLabel,
    required this.onTap,
  });

  final String question;
  final String actionLabel;
  final FutureOr<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.componentColors;
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: Spacing.xs,
      children: [
        Text(
          question,
          textAlign: TextAlign.center,
          style: TextStyles.body.copyWith(color: colors.textLight),
        ),
        ButtonComponent(
          label: actionLabel,
          variant: ButtonComponentVariant.link,
          size: ButtonComponentSize.small,
          shouldSurfaceExecutionStates: false,
          onTap: onTap,
        ),
      ],
    );
  }
}

class _OnboardingBackdrop extends StatefulWidget {
  const _OnboardingBackdrop({required this.color});

  final Color color;

  @override
  State<_OnboardingBackdrop> createState() => _OnboardingBackdropState();
}

class _OnboardingBackdropState extends State<_OnboardingBackdrop> {
  static Future<PictureInfo?>? _texture;

  PictureInfo? _picture;

  @override
  void initState() {
    super.initState();
    _texture ??= _loadTexture();
    unawaited(
      _texture!.then((picture) {
        if (mounted && picture != null) setState(() => _picture = picture);
      }),
    );
  }

  static Future<PictureInfo?> _loadTexture() async {
    try {
      return await vg.loadPicture(
        const SvgAssetLoader("assets/onboarding_doodle.svg"),
        null,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ClipRect(
        child: CustomPaint(
          isComplex: true,
          painter: _OnboardingBackdropPainter(
            color: widget.color,
            texture: _picture,
          ),
        ),
      ),
    );
  }
}

class _OnboardingBackdropPainter extends CustomPainter {
  const _OnboardingBackdropPainter({required this.color, this.texture});

  static const double textureWidth = 670;
  static const double textureHeight = 1006;
  static const double textureLeft = -90;
  static const double textureOpacity = 0.38 * 0.4;

  final Color color;
  final PictureInfo? texture;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = color);
    final texture = this.texture;
    if (texture == null) return;
    const textureBounds = Rect.fromLTWH(
      textureLeft,
      0,
      textureWidth,
      textureHeight,
    );
    canvas.saveLayer(
      textureBounds.intersect(Offset.zero & size),
      Paint()
        ..blendMode = BlendMode.softLight
        ..color = Colors.white.withValues(alpha: textureOpacity),
    );
    canvas.drawRect(textureBounds, Paint()..color = Colors.black);
    canvas.translate(textureLeft, 0);
    canvas.scale(textureWidth / texture.size.width);
    canvas.drawPicture(texture.picture);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_OnboardingBackdropPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.texture != texture;
  }
}
