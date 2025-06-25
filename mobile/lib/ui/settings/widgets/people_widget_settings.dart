import 'package:flutter/material.dart';
import "package:photos/generated/l10n.dart";
import "package:photos/l10n/l10n.dart";
import "package:photos/models/selected_people.dart";
import "package:photos/services/people_home_widget_service.dart";
import "package:photos/ui/components/buttons/button_widget.dart";
import 'package:photos/ui/components/buttons/icon_button_widget.dart';
import "package:photos/ui/components/models/button_type.dart";
import 'package:photos/ui/components/title_bar_title_widget.dart';
import 'package:photos/ui/components/title_bar_widget.dart';
import "package:photos/ui/viewer/search/result/people_section_all_page.dart";

class PeopleWidgetSettings extends StatefulWidget {
  const PeopleWidgetSettings({super.key});

  @override
  State<PeopleWidgetSettings> createState() => _PeopleWidgetSettingsState();
}

class _PeopleWidgetSettingsState extends State<PeopleWidgetSettings> {
  bool hasInstalledAny = false;
  final _selectedPeople = SelectedPeople();

  @override
  void initState() {
    super.initState();
    getSelections();
    checkIfAnyWidgetInstalled();
  }

  Future<void> getSelections() async {
    final selectedPeople = PeopleHomeWidgetService.instance.getSelectedPeople();

    if (selectedPeople != null) {
      _selectedPeople.select(selectedPeople.toSet());
    }
  }

  Future<void> checkIfAnyWidgetInstalled() async {
    final count = await PeopleHomeWidgetService.instance.countHomeWidgets();
    setState(() {
      hasInstalledAny = count > 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: hasInstalledAny
          ? Padding(
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
                            await PeopleHomeWidgetService.instance
                                .setSelectedPeople(
                              _selectedPeople.personIds.toList(),
                            );
                            Navigator.pop(context);
                            await PeopleHomeWidgetService.instance
                                .checkPeopleChanged();
                          },
                  );
                },
              ),
            )
          : null,
      body: CustomScrollView(
        primary: false,
        slivers: <Widget>[
          TitleBarWidget(
            flexibleSpaceTitle: TitleBarTitleWidget(
              title: S.of(context).people,
            ),
            expandedHeight: 120,
            flexibleSpaceCaption: hasInstalledAny
                ? S.of(context).peopleWidgetDesc
                : context.l10n.addPeopleWidgetPrompt,
            actionIcons: [
              IconButtonWidget(
                icon: Icons.close_outlined,
                iconButtonType: IconButtonType.secondary,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          if (!hasInstalledAny)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: MediaQuery.sizeOf(context).height * 0.5 - 200,
                    ),
                    Image.asset(
                      "assets/people-widget-static.png",
                      height: 160,
                    ),
                  ],
                ),
              ),
            )
          else
            SliverFillRemaining(
              child: PeopleSectionAllWidget(
                selectedPeople: _selectedPeople,
                namedOnly: true,
              ),
            ),
        ],
      ),
    );
  }
}
