import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:photos/generated/intl/app_localizations.dart";
import "package:photos/models/ml/face/person.dart";
import "package:photos/ui/viewer/people/faces_timeline_banner.dart";

void main() {
  group("FacesTimelineBannerSection", () {
    late PersonEntity person;

    setUp(() {
      person = PersonEntity(
        "person-1",
        PersonData(name: "Alex"),
      );
    });

    testWidgets("renders banner when timeline is ready", (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: FacesTimelineBannerSection(
            showBanner: true,
            person: person,
            onTap: () {},
          ),
        ),
      );

      expect(find.byType(FacesTimelineBanner), findsOneWidget);
      expect(find.textContaining("Faces timeline"), findsOneWidget);
    });

    testWidgets("hides banner when timeline is unavailable", (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: FacesTimelineBannerSection(
            showBanner: false,
            person: person,
            onTap: () {},
          ),
        ),
      );

      expect(find.byType(FacesTimelineBanner), findsNothing);
    });

    testWidgets("hides banner when tap callback is missing", (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: FacesTimelineBannerSection(
            showBanner: true,
            person: person,
            onTap: null,
          ),
        ),
      );

      expect(find.byType(FacesTimelineBanner), findsNothing);
    });
  });
}
