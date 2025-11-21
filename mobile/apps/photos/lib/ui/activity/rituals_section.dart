import "package:flutter/material.dart";
import "package:photos/models/activity/activity_models.dart";
import "package:photos/models/collection/collection.dart";
import "package:photos/models/file/file.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/theme/colors.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/collections/album/column_item.dart";
import "package:photos/ui/viewer/file/thumbnail_widget.dart";

class RitualsSection extends StatelessWidget {
  const RitualsSection({
    required this.rituals,
    required this.progress,
    super.key,
  });

  final List<Ritual> rituals;
  final Map<String, RitualProgress> progress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "Activity",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              IconButton(
                onPressed: () async {
                  await _showRitualEditor(context, ritual: null);
                },
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (rituals.isEmpty)
            Text(
              "Create a ritual to get daily reminders.",
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            Column(
              children: rituals
                  .map(
                    (ritual) => _RitualCard(
                      ritual: ritual,
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _RitualCard extends StatelessWidget {
  const _RitualCard({
    required this.ritual,
  });

  final Ritual ritual;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.grey.shade200,
          child: Text(
            ritual.icon,
            style: const TextStyle(fontSize: 18),
          ),
        ),
        title: Text(ritual.title.isEmpty ? "Untitled ritual" : ritual.title),
        subtitle: ritual.albumName == null || ritual.albumName!.isEmpty
            ? Text(
                "Album not set",
                style: getEnteTextTheme(context).smallMuted,
              )
            : Text(
                ritual.albumName!,
                style: getEnteTextTheme(context).smallMuted,
              ),
        trailing: PopupMenuButton<String>(
          elevation: 0,
          color: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(
              color: Color.fromRGBO(0, 0, 0, 0.09),
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
            const PopupMenuItem(
              value: "edit",
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(12, 8, 12, 8),
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, color: Color(0xFF0F172A)),
                        SizedBox(width: 10),
                        Text("Edit"),
                      ],
                    ),
                  ),
                  Divider(
                    height: 0.5,
                    thickness: 0.5,
                    color: Color.fromRGBO(0, 0, 0, 0.09),
                    indent: 0,
                    endIndent: 0,
                  ),
                ],
              ),
            ),
            const PopupMenuItem(
              value: "delete",
              padding: EdgeInsets.zero,
              child: Padding(
                padding: EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red),
                    SizedBox(width: 10),
                    Text(
                      "Delete",
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
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

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      final colorScheme = getEnteColorScheme(context);
      final textTheme = getEnteTextTheme(context);
      return StatefulBuilder(
        builder: (context, setState) {
          final bool canSave =
              controller.text.trim().isNotEmpty && selectedAlbumId != null;
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                left: 12,
                right: 12,
                top: 8,
              ),
              child: Container(
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
                              ritual == null ? "New ritual" : "Edit ritual",
                              style: textTheme.largeBold,
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.of(context).pop(),
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
                                      style: const TextStyle(fontSize: 32),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: -4,
                                  bottom: -4,
                                  child: Material(
                                    color: colorScheme.backgroundElevated,
                                    shape: const CircleBorder(),
                                    elevation: 2,
                                    child: InkWell(
                                      customBorder: const CircleBorder(),
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
                                        child: Icon(
                                          Icons.edit_outlined,
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
                                autofocus: true,
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  hintText: "Enter your ritual",
                                  filled: true,
                                  fillColor: colorScheme.fillFaint,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 14,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(18),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(18),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(18),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return "Please enter a description";
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _sectionLabel(context, "Day"),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.fillFaint,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(
                              days.length,
                              (index) => _DayCircle(
                                label: _weekLabel(index),
                                selected: days[index],
                                colorScheme: colorScheme,
                                onTap: () {
                                  setState(() {
                                    days[index] = !days[index];
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _sectionLabel(context, "Time"),
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
                                    color: colorScheme.backgroundElevated2,
                                    borderRadius: BorderRadius.circular(12),
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
                        const SizedBox(height: 16),
                        _sectionLabel(context, "Album"),
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
                                      activityService.createEmptyRitual())
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
                              ritual == null ? "Save ritual" : "Update ritual",
                              style: textTheme.bodyBold
                                  .copyWith(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

String _weekLabel(int index) {
  const labels = ["S", "M", "T", "W", "T", "F", "S"];
  return labels[index];
}

Future<Collection?> _pickAlbum(BuildContext context) async {
  final service = CollectionsService.instance;
  final albums =
      List<Collection>.from(await service.getCollectionForWidgetSelection());
  Collection? selected;
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final colorScheme = getEnteColorScheme(context);
      final textTheme = getEnteTextTheme(context);
      final controller = TextEditingController();
      return StatefulBuilder(
        builder: (context, setState) {
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                left: 12,
                right: 12,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
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
                            "Select album",
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
                        controller: controller,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          hintText: "Create new album",
                          prefixIcon: const Icon(Icons.add_rounded),
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
                        onSubmitted: (value) async {
                          final trimmed = value.trim();
                          if (trimmed.isEmpty) return;
                          final created = await service.createAlbum(trimmed);
                          controller.clear();
                          albums.insert(0, created);
                          setState(() {});
                        },
                      ),
                    ),
                    Flexible(
                      child: SizedBox(
                        height: 360,
                        child: albums.isEmpty
                            ? Center(
                                child: Text(
                                  "No albums yet",
                                  style: textTheme.small
                                      .copyWith(color: colorScheme.textMuted),
                                ),
                              )
                            : ListView.separated(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                itemBuilder: (context, index) {
                                  final album = albums[index];
                                  return GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {
                                      selected = album;
                                      Navigator.of(context).pop();
                                    },
                                    child: AlbumColumnItemWidget(
                                      album,
                                      selectedCollections: selected == album
                                          ? <Collection>[album]
                                          : const <Collection>[],
                                    ),
                                  );
                                },
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 10),
                                itemCount: albums.length,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
  return selected;
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
                  "Album",
                  style: textTheme.miniMuted,
                ),
                const SizedBox(height: 2),
                Text(
                  album?.displayName ?? fallbackName ?? "Select album",
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
    required this.colorScheme,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final EnteColorScheme colorScheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color:
              selected ? colorScheme.primary500 : colorScheme.fillFaintPressed,
          borderRadius: BorderRadius.circular(20),
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
                    "Pick an emoji",
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
                "Custom (keyboard)",
                style: textTheme.miniMuted,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: customEmojiController,
                      textInputAction: TextInputAction.done,
                      onChanged: (value) {
                        final trimmed = value.trim();
                        final firstGrapheme = trimmed.isEmpty
                            ? ""
                            : trimmed.characters.take(1).toString();
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
                        if (trimmed.isEmpty) return;
                        selected = trimmed.characters.take(1).toString();
                        Navigator.of(context).pop();
                      },
                      decoration: InputDecoration(
                        hintText: "Press to open emoji keyboard",
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
                      "Use",
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
