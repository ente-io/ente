import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:photos/l10n/l10n.dart";
import "package:photos/models/rituals/ritual_models.dart";
import "package:photos/service_locator.dart";
import "package:photos/ui/rituals/ritual_editor_dialog.dart";
import "package:photos/ui/rituals/rituals_section.dart";

class AllRitualsScreen extends StatefulWidget {
  const AllRitualsScreen({super.key, this.ritual});

  final Ritual? ritual;

  @override
  State<AllRitualsScreen> createState() => _AllRitualsScreenState();
}

class _AllRitualsScreenState extends State<AllRitualsScreen> {
  Ritual? _selectedRitual;

  @override
  void initState() {
    super.initState();
    _selectedRitual = widget.ritual;
  }

  @override
  void didUpdateWidget(covariant AllRitualsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ritual != widget.ritual) {
      _selectedRitual = widget.ritual;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ritualsEnabled = flagService.ritualsFlag;
    if (!ritualsEnabled) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.ritualsTitle), centerTitle: false),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              "Rituals are currently limited to internal users.",
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.ritualsTitle),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF1DB954),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(8),
                minimumSize: const Size(40, 40),
              ),
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedPlusSign,
                size: 24,
                color: Colors.white,
              ),
              onPressed: () async {
                await showRitualEditor(context, ritual: null);
              },
              tooltip: l10n.ritualAddTooltip,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ValueListenableBuilder<RitualsState>(
          valueListenable: ritualsService.stateNotifier,
          builder: (context, state, _) {
            Ritual? selectedRitual = _selectedRitual;
            if (selectedRitual != null) {
              final match = state.rituals.where(
                (ritual) => ritual.id == selectedRitual!.id,
              );
              if (match.isNotEmpty) {
                selectedRitual = match.first;
              } else {
                selectedRitual = null;
              }
            }
            return ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 48),
              children: [
                RitualsSection(
                  rituals: state.rituals,
                  showHeader: false,
                  selectedRitualId: selectedRitual?.id,
                  onSelectionChanged: (ritual) {
                    setState(() {
                      _selectedRitual = ritual;
                    });
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
