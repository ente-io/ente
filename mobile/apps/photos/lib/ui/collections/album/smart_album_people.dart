import "dart:async";

import 'package:flutter/material.dart';
import "package:photos/generated/l10n.dart";
import "package:photos/models/collection/smart_album_config.dart";
import "package:photos/models/selected_people.dart";
import "package:photos/services/smart_albums_service.dart";
import "package:photos/ui/components/buttons/button_widget.dart";
import "package:photos/ui/components/models/button_type.dart";
import 'package:photos/ui/components/title_bar_title_widget.dart';
import 'package:photos/ui/components/title_bar_widget.dart';
import "package:photos/ui/viewer/search/result/people_section_all_page.dart"
    show PeopleSectionAllWidget;

class SmartAlbumPeople extends StatefulWidget {
  const SmartAlbumPeople({
    super.key,
    required this.collectionId,
  });

  final int collectionId;

  @override
  State<SmartAlbumPeople> createState() => _SmartAlbumPeopleState();
}

class _SmartAlbumPeopleState extends State<SmartAlbumPeople> {
  final _selectedPeople = SelectedPeople();
  SmartAlbumConfig? currentConfig;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    getSelections();
  }

  Future<void> getSelections() async {
    currentConfig =
        await SmartAlbumsService.instance.getConfig(widget.collectionId);

    if (currentConfig != null &&
        currentConfig!.personIDs.isNotEmpty &&
        mounted) {
      _selectedPeople.select(currentConfig!.personIDs);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          8 + MediaQuery.viewPaddingOf(context).bottom,
        ),
        child: ListenableBuilder(
          listenable: _selectedPeople,
          builder: (context, _) {
            return ButtonWidget(
              buttonType: ButtonType.primary,
              buttonSize: ButtonSize.large,
              labelText: S.of(context).save,
              shouldSurfaceExecutionStates: false,
              isDisabled: _selectedPeople.personIds.isEmpty,
              onTap: _selectedPeople.personIds.isEmpty
                  ? null
                  : () async {
                      isLoading = true;
                      if (mounted) setState(() {});

                      try {
                        SmartAlbumConfig newConfig;

                        if (currentConfig == null) {
                          final infoMap = <String, PersonInfo>{};

                          // Add files which are needed
                          for (final personId in _selectedPeople.personIds) {
                            infoMap[personId] = (updatedAt: 0, addedFiles: {});
                          }

                          newConfig = SmartAlbumConfig(
                            collectionId: widget.collectionId,
                            personIDs: _selectedPeople.personIds,
                            infoMap: infoMap,
                          );
                        } else {
                          newConfig = await currentConfig!.getUpdatedConfig(
                            _selectedPeople.personIds,
                          );
                        }

                        await SmartAlbumsService.instance.saveConfig(newConfig);
                        SmartAlbumsService.instance.syncSmartAlbums().ignore();

                        Navigator.pop(context);
                      } catch (_) {
                        isLoading = false;
                        if (mounted) setState(() {});
                      }
                    },
            );
          },
        ),
      ),
      body: Stack(
        children: [
          CustomScrollView(
            primary: false,
            slivers: <Widget>[
              TitleBarWidget(
                flexibleSpaceTitle: TitleBarTitleWidget(
                  title: S.of(context).people,
                ),
                expandedHeight: MediaQuery.textScalerOf(context).scale(120),
                flexibleSpaceCaption: S.of(context).peopleWidgetDesc,
                actionIcons: const [],
              ),
              SliverFillRemaining(
                child: PeopleSectionAllWidget(
                  selectedPeople: _selectedPeople,
                  namedOnly: true,
                ),
              ),
            ],
          ),
          if (isLoading)
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
              ),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
