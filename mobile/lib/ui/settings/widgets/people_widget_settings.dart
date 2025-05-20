import 'package:flutter/material.dart';
import "package:photos/generated/l10n.dart";
import "package:photos/models/selected_people.dart";
import "package:photos/services/people_home_widget_service.dart";
import 'package:photos/theme/ente_theme.dart';
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

  Set<String> people = <String>{};

  @override
  void initState() {
    super.initState();
    _selectedPeople.addListener(_selectedPeopleListener);
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

  void _selectedPeopleListener() {
    people = _selectedPeople.personIds;
    setState(() {});
  }

  @override
  void dispose() {
    _selectedPeople.removeListener(_selectedPeopleListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = getEnteTextTheme(context);
    return Scaffold(
      bottomNavigationBar: hasInstalledAny
          ? Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                8 + MediaQuery.viewPaddingOf(context).bottom,
              ),
              child: ButtonWidget(
                buttonType: ButtonType.primary,
                buttonSize: ButtonSize.large,
                labelText: S.of(context).save,
                shouldSurfaceExecutionStates: false,
                isDisabled: people.isEmpty,
                onTap: people.isEmpty
                    ? null
                    : () async {
                        await PeopleHomeWidgetService.instance
                            .setSelectedPeople(people.toList());
                        Navigator.pop(context);
                        await PeopleHomeWidgetService.instance.peopleChanged();
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
            flexibleSpaceCaption: S.of(context).peopleWidgetDesc,
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
                      height: MediaQuery.sizeOf(context).height * 0.5 - 300,
                    ),
                    Image.asset(
                      "assets/people-widget-static.png",
                      height: 160,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Add a people widget to your homescreen and come back here to customize",
                      style: textTheme.largeFaint,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            SliverToBoxAdapter(
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
