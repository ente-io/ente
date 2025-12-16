import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:photos/l10n/l10n.dart";
import "package:photos/models/activity/activity_models.dart";
import "package:photos/models/collection/collection.dart";
import "package:photos/models/file/file.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/theme/colors.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/activity/activity_screen.dart";
import "package:photos/ui/activity/ritual_camera_page.dart";
import "package:photos/ui/collections/album/column_item.dart";
import "package:photos/ui/viewer/file/thumbnail_widget.dart";
import "package:photos/utils/navigation_util.dart";

class RitualsSection extends StatelessWidget {
  const RitualsSection({
    required this.rituals,
    required this.progress,
    this.selectedRitualId,
    this.onSelectionChanged,
    this.showHeader = true,
    this.showStarterRitual = true,
    super.key,
  });

  final List<Ritual> rituals;
  final Map<String, RitualProgress> progress;
  final String? selectedRitualId;
  final ValueChanged<Ritual?>? onSelectionChanged;
  final bool showHeader;
  final bool showStarterRitual;

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeader) ...[
            Row(
              children: [
                Text(
                  context.l10n.ritualsTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () async {
                    await _showRitualEditor(context, ritual: null);
                  },
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.fillFaint,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(8),
                    minimumSize: const Size(40, 40),
                  ),
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedPlusSign,
                    size: 22,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ] else
            const SizedBox(height: 4),
          if (showStarterRitual)
            _StarterRitualCard(
              isSelected: selectedRitualId == null,
              onTap: () => onSelectionChanged?.call(null),
            ),
          if (rituals.isEmpty)
            _CreateRitualCard(
              onTap: () async {
                await _showRitualEditor(context, ritual: null);
              },
            )
          else
            Column(
              children: rituals
                  .map(
                    (ritual) => _RitualCard(
                      ritual: ritual,
                      isSelected: ritual.id == selectedRitualId,
                      onTap: () => onSelectionChanged?.call(ritual),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _StarterRitualCard extends StatelessWidget {
  const _StarterRitualCard({
    required this.isSelected,
    this.onTap,
  });

  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.backgroundElevated2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? colorScheme.primary500
              : colorScheme.backgroundElevated2,
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.fillFaintPressed,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      "📸",
                      style: TextStyle(
                        fontSize: 18,
                        height: 1,
                        decoration: TextDecoration.none,
                      ),
                      textHeightBehavior: _tightTextHeightBehavior,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.l10n.ritualDefaultHeatmapTitle,
                    style: getEnteTextTheme(context).body,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CreateRitualCard extends StatelessWidget {
  const _CreateRitualCard({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.backgroundElevated2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.backgroundElevated2,
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.fillFaintPressed,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedPlusSign,
                      color: colorScheme.textBase,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.ritualCreateYourOwn,
                        style: textTheme.body,
                      ),
                      Text(
                        context.l10n.ritualGetDailyReminders,
                        style: textTheme.smallMuted,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RitualCard extends StatelessWidget {
  const _RitualCard({
    required this.ritual,
    this.isSelected = false,
    this.onTap,
  });

  final Ritual ritual;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.backgroundElevated2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? colorScheme.primary500
              : colorScheme.backgroundElevated2,
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (onTap != null) {
              onTap!();
            } else {
              routeToPage(
                context,
                ActivityScreen(ritual: ritual),
              );
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 0, 0),
            child: SizedBox(
              height: 64,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorScheme.fillFaintPressed,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        ritual.icon,
                        style: const TextStyle(
                          fontSize: 18,
                          height: 1,
                          decoration: TextDecoration.none,
                        ),
                        textHeightBehavior: _tightTextHeightBehavior,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          ritual.title.isEmpty
                              ? context.l10n.ritualUntitled
                              : ritual.title,
                          style: textTheme.body,
                          textHeightBehavior: _tightTextHeightBehavior,
                        ),
                        ritual.albumName == null || ritual.albumName!.isEmpty
                            ? Text(
                                context.l10n.ritualAlbumNotSet,
                                style: textTheme.smallMuted,
                                textHeightBehavior: _tightTextHeightBehavior,
                              )
                            : Text(
                                ritual.albumName!,
                                style: textTheme.smallMuted,
                                textHeightBehavior: _tightTextHeightBehavior,
                              ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedCameraAdd01,
                      color: colorScheme.textBase,
                      size: 24,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: colorScheme.fillFaint,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(8),
                      minimumSize: const Size(40, 40),
                    ),
                    onPressed: () => _openRitualCamera(context, ritual),
                    tooltip: context.l10n.ritualOpenCameraTooltip,
                  ),
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    splashRadius: 20,
                    icon: Transform.translate(
                      offset: const Offset(4, 0),
                      child: const Icon(Icons.more_vert_rounded),
                    ),
                    elevation: 0,
                    color: colorScheme.backgroundElevated,
                    surfaceTintColor: colorScheme.backgroundElevated,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: colorScheme.strokeFaint,
                        width: 0.5,
                      ),
                    ),
                    onSelected: (value) async {
                      switch (value) {
                        case "edit":
                          await _showRitualEditor(context, ritual: ritual);
                          break;
                        case "delete":
                          await activityService.deleteRitual(ritual.id);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: "edit",
                        padding: EdgeInsets.zero,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                              child: Row(
                                children: [
                                  HugeIcon(
                                    icon: HugeIcons.strokeRoundedPencilEdit01,
                                    color: colorScheme.textBase,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    context.l10n.edit,
                                    style: getEnteTextTheme(context).body,
                                  ),
                                ],
                              ),
                            ),
                            Divider(
                              height: 0.5,
                              thickness: 0.5,
                              color: colorScheme.strokeFaint,
                              indent: 0,
                              endIndent: 0,
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: "delete",
                        padding: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                          child: Row(
                            children: [
                              const HugeIcon(
                                icon: HugeIcons.strokeRoundedDelete02,
                                color: Colors.red,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                context.l10n.delete,
                                style: getEnteTextTheme(context)
                                    .body
                                    .copyWith(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> showRitualEditor(BuildContext context, {Ritual? ritual}) async {
  await _showRitualEditor(context, ritual: ritual);
}

Future<void> _showRitualEditor(BuildContext context, {Ritual? ritual}) async {
  final controller = TextEditingController(text: ritual?.title ?? "");
  final days = [...(ritual?.daysOfWeek ?? List<bool>.filled(7, true))];
  Collection? selectedAlbum = ritual?.albumId != null
      ? CollectionsService.instance.getCollectionByID(ritual!.albumId!)
      : null;
  String? selectedAlbumName = selectedAlbum?.displayName ?? ritual?.albumName;
  int? selectedAlbumId = selectedAlbum?.id ?? ritual?.albumId;
  TimeOfDay selectedTime =
      ritual?.timeOfDay ?? const TimeOfDay(hour: 9, minute: 0);
  String selectedEmoji = ritual?.icon ?? "📸";
  final formKey = GlobalKey<FormState>();

  await showGeneralDialog(
    context: context,
    barrierLabel: context.l10n.ritualEditorLabel,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    barrierDismissible: true,
    transitionDuration: const Duration(milliseconds: 240),
    useRootNavigator: false,
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      final mediaQuery = MediaQuery.of(dialogContext);
      final colorScheme = getEnteColorScheme(dialogContext);
      final textTheme = getEnteTextTheme(dialogContext);
      final bottomPadding = mediaQuery.viewPadding.bottom;
      final maxHeight = mediaQuery.size.height * 0.95;
      return MediaQuery.removeViewInsets(
        context: dialogContext,
        removeBottom: true,
        child: SafeArea(
          top: false,
          bottom: false,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: Padding(
                padding: EdgeInsets.fromLTRB(12, 8, 12, bottomPadding + 16),
                child: Material(
                  color: Colors.transparent,
                  child: StatefulBuilder(
                    builder: (context, setState) {
                      final bool canSave = controller.text.trim().isNotEmpty &&
                          selectedAlbumId != null;
                      final bool allDaysOff =
                          days.every((selected) => !selected);
                      return Container(
                        decoration: BoxDecoration(
                          color: colorScheme.backgroundElevated,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 22,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                          child: Form(
                            key: formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      ritual == null
                                          ? context.l10n.ritualNew
                                          : context.l10n.ritualEdit,
                                      style: textTheme.largeBold,
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Container(
                                          width: 70,
                                          height: 70,
                                          decoration: BoxDecoration(
                                            color: colorScheme.fillFaintPressed,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              selectedEmoji,
                                              style:
                                                  const TextStyle(fontSize: 32),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          right: -4,
                                          bottom: -4,
                                          child: Material(
                                            color:
                                                colorScheme.backgroundElevated,
                                            shape: const CircleBorder(),
                                            elevation: 2,
                                            child: InkWell(
                                              customBorder:
                                                  const CircleBorder(),
                                              onTap: () async {
                                                final emoji = await _pickEmoji(
                                                  context,
                                                  selectedEmoji,
                                                );
                                                if (emoji != null) {
                                                  setState(() {
                                                    selectedEmoji = emoji;
                                                  });
                                                }
                                              },
                                              child: const Padding(
                                                padding: EdgeInsets.all(6),
                                                child: HugeIcon(
                                                  icon: HugeIcons
                                                      .strokeRoundedEdit03,
                                                  size: 18,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        controller: controller,
                                        autofocus: false,
                                        textCapitalization:
                                            TextCapitalization.sentences,
                                        onChanged: (_) => setState(() {}),
                                        decoration: InputDecoration(
                                          hintText:
                                              context.l10n.ritualEnterPrompt,
                                          filled: true,
                                          fillColor: colorScheme.fillFaint,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 14,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(18),
                                            borderSide: BorderSide.none,
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(18),
                                            borderSide: BorderSide.none,
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(18),
                                            borderSide: BorderSide.none,
                                          ),
                                        ),
                                        validator: (value) {
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return context
                                                .l10n.ritualEnterDescription;
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                _sectionLabel(
                                  context,
                                  context.l10n.ritualDayLabel,
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.fillFaint,
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      const double maxCircleSize = 38;
                                      const double minCircleSize = 20;
                                      const double minSpacing = 6;
                                      final double availableWidth =
                                          constraints.maxWidth;

                                      double circleSize = maxCircleSize;
                                      double spacing =
                                          (availableWidth - circleSize * 7) / 8;

                                      if (spacing < minSpacing) {
                                        spacing = minSpacing;
                                        circleSize =
                                            ((availableWidth - (spacing * 8)) /
                                                    7)
                                                .clamp(
                                          minCircleSize,
                                          maxCircleSize,
                                        );
                                        spacing =
                                            (availableWidth - circleSize * 7) /
                                                8;
                                      }

                                      final children = <Widget>[
                                        SizedBox(width: spacing),
                                      ];
                                      for (int index = 0;
                                          index < days.length;
                                          index++) {
                                        children.add(
                                          _DayCircle(
                                            label: _weekLabel(context, index),
                                            selected: days[index],
                                            size: circleSize,
                                            colorScheme: colorScheme,
                                            onTap: () {
                                              setState(() {
                                                days[index] = !days[index];
                                              });
                                            },
                                          ),
                                        );
                                        children.add(SizedBox(width: spacing));
                                      }

                                      return Row(children: children);
                                    },
                                  ),
                                ),
                                const SizedBox(height: 16),
                                if (allDaysOff)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.fillFaint,
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.notifications_off_outlined,
                                          color: colorScheme.textMuted,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            context.l10n
                                                .ritualNotificationsOffHint,
                                            style: textTheme.small.copyWith(
                                              color: colorScheme.textMuted,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else ...[
                                  _sectionLabel(
                                    context,
                                    context.l10n.ritualTimeLabel,
                                  ),
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () async {
                                      final result = await showTimePicker(
                                        context: context,
                                        initialTime: selectedTime,
                                      );
                                      if (result != null) {
                                        setState(() {
                                          selectedTime = result;
                                        });
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 14,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colorScheme.fillFaint,
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              selectedTime.format(context),
                                              style: textTheme.h3Bold,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: colorScheme
                                                  .backgroundElevated2,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              Icons.schedule,
                                              color: colorScheme.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 16),
                                _sectionLabel(
                                  context,
                                  context.l10n.ritualAlbumLabel,
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () async {
                                    final result = await _pickAlbum(context);
                                    if (result != null) {
                                      setState(() {
                                        selectedAlbum = result;
                                        selectedAlbumId = result.id;
                                        selectedAlbumName = result.displayName;
                                      });
                                    }
                                  },
                                  child: _AlbumPreviewTile(
                                    album: selectedAlbum,
                                    fallbackName: selectedAlbumName,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: canSave
                                          ? colorScheme.primary500
                                          : colorScheme.fillMuted,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                    ),
                                    onPressed: () async {
                                      if (!canSave) return;
                                      final updated = (ritual ??
                                              activityService
                                                  .createEmptyRitual())
                                          .copyWith(
                                        title: controller.text.trim(),
                                        daysOfWeek: days,
                                        timeOfDay: selectedTime,
                                        albumId: selectedAlbumId,
                                        albumName: selectedAlbumName,
                                        icon: selectedEmoji,
                                      );
                                      await activityService.saveRitual(updated);
                                      Navigator.of(context).pop();
                                    },
                                    child: Text(
                                      ritual == null
                                          ? context.l10n.ritualSave
                                          : context.l10n.ritualUpdate,
                                      style: textTheme.bodyBold
                                          .copyWith(color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      );
    },
  );
}

String _weekLabel(BuildContext context, int index) {
  final labels = MaterialLocalizations.of(context).narrowWeekdays;
  return labels[index % labels.length];
}

Future<Collection?> _pickAlbum(BuildContext context) async {
  final albums = List<Collection>.from(
    await CollectionsService.instance.getCollectionsForRituals(),
  );
  Collection? selected;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return _AlbumPickerSheet(
        albums: albums,
        onSelected: (collection) => selected = collection,
      );
    },
  );

  return selected;
}

class _AlbumPickerSheet extends StatefulWidget {
  const _AlbumPickerSheet({
    required this.albums,
    required this.onSelected,
  });

  final List<Collection> albums;
  final ValueChanged<Collection?> onSelected;

  @override
  State<_AlbumPickerSheet> createState() => _AlbumPickerSheetState();
}

class _AlbumPickerSheetState extends State<_AlbumPickerSheet> {
  late final TextEditingController _controller;
  Collection? _selected;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = CollectionsService.instance;
    final mediaQuery = MediaQuery.of(context);
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final l10n = context.l10n;
    final trimmedQuery = _controller.text.trim();
    final bool canCreateAlbum = trimmedQuery.isNotEmpty;
    final queryLower = trimmedQuery.toLowerCase();
    final filteredAlbums = queryLower.isEmpty
        ? widget.albums
        : widget.albums
            .where(
              (album) => album.displayName.toLowerCase().contains(queryLower),
            )
            .toList();

    Future<void> createAlbum() async {
      final trimmed = _controller.text.trim();
      if (trimmed.isEmpty) return;
      final created = await service.createAlbum(trimmed);
      if (!context.mounted) return;
      _selected = created;
      widget.onSelected(created);
      Navigator.of(context).pop();
    }

    return MediaQuery.removeViewInsets(
      context: context,
      removeBottom: true,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 12,
            right: 12,
            bottom: mediaQuery.viewPadding.bottom + 16,
            top: 8,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.backgroundElevated,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 8, 0),
                  child: Row(
                    children: [
                      Text(
                        l10n.ritualSelectAlbumTitle,
                        style: textTheme.bodyBold,
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: l10n.ritualSearchOrCreate,
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: colorScheme.fillFaint,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: colorScheme.strokeFaint,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: colorScheme.strokeFaint,
                        ),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => FocusScope.of(context).unfocus(),
                  ),
                ),
                Flexible(
                  child: SizedBox(
                    height: 360,
                    child: filteredAlbums.isEmpty
                        ? Center(
                            child: Text(
                              widget.albums.isEmpty
                                  ? l10n.ritualNoAlbumsYet
                                  : l10n.ritualNoMatchingAlbums,
                              style: textTheme.small.copyWith(
                                color: colorScheme.textMuted,
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemBuilder: (context, index) {
                              final album = filteredAlbums[index];
                              return GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  _selected = album;
                                  widget.onSelected(album);
                                  Navigator.of(context).pop();
                                },
                                child: AlbumColumnItemWidget(
                                  album,
                                  selectedCollections: _selected == album
                                      ? <Collection>[album]
                                      : const <Collection>[],
                                ),
                              );
                            },
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemCount: filteredAlbums.length,
                          ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canCreateAlbum
                            ? colorScheme.primary500
                            : colorScheme.fillMuted,
                        foregroundColor: colorScheme.backgroundBase,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: canCreateAlbum ? createAlbum : null,
                      child: Text(
                        canCreateAlbum
                            ? l10n.ritualCreateAlbumWithName(
                                albumName: trimmedQuery,
                              )
                            : l10n.ritualCreateNew,
                        style: textTheme.bodyBold.copyWith(
                          color: canCreateAlbum
                              ? Colors.white
                              : colorScheme.textMuted,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AlbumPreviewTile extends StatelessWidget {
  const _AlbumPreviewTile({required this.album, required this.fallbackName});

  final Collection? album;
  final String? fallbackName;

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.fillFaint,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          _AlbumThumbnail(album: album),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.ritualAlbumLabel,
                  style: textTheme.miniMuted,
                ),
                const SizedBox(height: 2),
                Text(
                  album?.displayName ??
                      fallbackName ??
                      context.l10n.ritualAlbumSelectionPlaceholder,
                  style: textTheme.smallBold,
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: colorScheme.textMuted,
          ),
        ],
      ),
    );
  }
}

class _AlbumThumbnail extends StatelessWidget {
  const _AlbumThumbnail({required this.album});

  final Collection? album;

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    if (album == null) {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: colorScheme.fillFaintPressed,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.photo_album_outlined,
          color: colorScheme.textMuted,
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 60,
        height: 60,
        child: FutureBuilder<EnteFile?>(
          future: CollectionsService.instance.getCover(album!),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return ThumbnailWidget(
                snapshot.data!,
                showFavForAlbumOnly: true,
                shouldShowOwnerAvatar: false,
              );
            }
            return Container(
              color: colorScheme.fillFaintPressed,
            );
          },
        ),
      ),
    );
  }
}

class _DayCircle extends StatelessWidget {
  const _DayCircle({
    required this.label,
    required this.selected,
    required this.size,
    required this.colorScheme,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final double size;
  final EnteColorScheme colorScheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: size,
        height: size,
        decoration: BoxDecoration(
          color:
              selected ? colorScheme.primary500 : colorScheme.fillFaintPressed,
          borderRadius: BorderRadius.circular(size / 2),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : colorScheme.textMuted,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

void _openRitualCamera(BuildContext context, Ritual ritual) {
  final albumId = ritual.albumId;
  if (albumId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.l10n.ritualSetAlbumToLaunchCamera,
        ),
      ),
    );
    return;
  }
  routeToPage(
    context,
    RitualCameraPage(
      ritualId: ritual.id,
      albumId: albumId,
    ),
  );
}

Widget _sectionLabel(BuildContext context, String label) {
  final textTheme = getEnteTextTheme(context);
  final colorScheme = getEnteColorScheme(context);
  return Text(
    label,
    style: textTheme.smallBold.copyWith(color: colorScheme.textMuted),
  );
}

Future<String?> _pickEmoji(BuildContext context, String current) async {
  const emojiOptions = [
    "📸",
    "😊",
    "🌿",
    "☕️",
    "🌅",
    "🏃",
    "🧘",
    "📚",
    "🎧",
    "💅",
    "🎨",
    "🥾",
    "🌙",
    "📝",
    "🧠",
    "🧹",
    "🌻",
    "🧩",
  ];
  String? selected;
  String customEmoji = current;
  final customEmojiController = TextEditingController(text: current);
  final colorScheme = getEnteColorScheme(context);
  final textTheme = getEnteTextTheme(context);
  await showModalBottomSheet(
    context: context,
    backgroundColor: colorScheme.backgroundElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    context.l10n.ritualPickEmojiTitle,
                    style: textTheme.bodyBold,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 6,
                childAspectRatio: 1,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                children: emojiOptions.map((emoji) {
                  final isActive = emoji == customEmoji;
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      selected = emoji;
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isActive
                            ? colorScheme.primary500.withValues(alpha: 0.1)
                            : colorScheme.fillFaint,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isActive
                              ? colorScheme.primary500
                              : colorScheme.strokeFaint,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Text(
                context.l10n.ritualCustomKeyboardLabel,
                style: textTheme.miniMuted,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: customEmojiController,
                      textInputAction: TextInputAction.done,
                      onTap: () {
                        final text = customEmojiController.text;
                        customEmojiController.selection = TextSelection(
                          baseOffset: 0,
                          extentOffset: text.length,
                        );
                      },
                      onChanged: (value) {
                        final trimmed = value.trim();
                        final firstGrapheme = trimmed.characters.isEmpty
                            ? ""
                            : trimmed.characters.take(1).toString();
                        if (firstGrapheme.isEmpty) {
                          customEmoji = "";
                          customEmojiController.value = const TextEditingValue(
                            text: "",
                            selection: TextSelection.collapsed(offset: 0),
                          );
                          return;
                        }
                        if (!_isEmoji(firstGrapheme)) {
                          customEmojiController.value = TextEditingValue(
                            text: customEmoji,
                            selection: TextSelection.collapsed(
                              offset: customEmoji.length,
                            ),
                          );
                          return;
                        }
                        customEmojiController.value = TextEditingValue(
                          text: firstGrapheme,
                          selection: TextSelection.collapsed(
                            offset: firstGrapheme.length,
                          ),
                        );
                        customEmoji = firstGrapheme;
                      },
                      onSubmitted: (value) {
                        final trimmed = value.trim();
                        if (trimmed.isEmpty || !_isEmoji(trimmed)) return;
                        selected = trimmed.characters.take(1).toString();
                        Navigator.of(context).pop();
                      },
                      decoration: InputDecoration(
                        hintText: context.l10n.ritualEmojiKeyboardHint,
                        filled: true,
                        fillColor: colorScheme.fillFaint,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colorScheme.strokeFaint,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colorScheme.strokeFaint,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary500,
                      minimumSize: const Size(64, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: customEmoji.isEmpty
                        ? null
                        : () {
                            selected = customEmoji;
                            Navigator.of(context).pop();
                          },
                    child: Text(
                      context.l10n.ritualEmojiUseAction,
                      style: textTheme.bodyBold.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
  return selected;
}

const _tightTextHeightBehavior = TextHeightBehavior(
  applyHeightToFirstAscent: false,
  applyHeightToLastDescent: false,
);

bool _isEmoji(String value) {
  if (value.isEmpty) return false;
  final codePoints = value.runes;
  for (final codePoint in codePoints) {
    if ((codePoint >= 0x1F300 && codePoint <= 0x1FAFF) ||
        (codePoint >= 0x1F1E6 && codePoint <= 0x1F1FF) ||
        (codePoint >= 0x1F680 && codePoint <= 0x1F6FF) ||
        (codePoint >= 0x2600 && codePoint <= 0x27BF)) {
      return true;
    }
  }
  return false;
}
