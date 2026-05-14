import "package:ente_components/ente_components.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  group("foundation tokens", () {
    test("expose expected spacing, radii, motion, and shadow values", () {
      expect(Spacing.xxs, 2);
      expect(Spacing.sm, 8);
      expect(Spacing.xl, 24);
      expect(Spacing.xxxl, 40);

      expect(Radii.xs, 4);
      expect(Radii.md, 12);
      expect(Radii.button, 20);
      expect(Radii.buttonRadius, const Radius.circular(20));
      expect(
        Radii.buttonBorder,
        const BorderRadius.all(Radius.circular(20)),
      );

      expect(Motion.quick, const Duration(milliseconds: 120));
      expect(Motion.standard, const Duration(milliseconds: 180));
      expect(Motion.slow, const Duration(milliseconds: 260));

      expect(Shadows.soft, hasLength(1));
      expect(Shadows.soft.first.color, const Color(0x14000000));
      expect(Shadows.soft.first.blurRadius, 16);
      expect(Shadows.floating.first.offset, const Offset(0, 12));
    });

    test("expose light and dark semantic color values", () {
      expect(ColorTokens.light.primary, const Color(0xFF08C225));
      expect(ColorTokens.light.warning, const Color(0xFFF63A3A));
      expect(ColorTokens.light.backgroundBase, const Color(0xFFFAFAFA));
      expect(ColorTokens.light.textBase, const Color(0xFF000000));
      expect(ColorTokens.light.textReverse, const Color(0xFFFFFFFF));
      expect(ColorTokens.light.iconColor, const Color.fromRGBO(0, 0, 0, 0.75));

      expect(ColorTokens.dark.primary, const Color(0xFF08C225));
      expect(ColorTokens.dark.warningLight, const Color(0xFF292929));
      expect(ColorTokens.dark.backgroundBase, const Color(0xFF161616));
      expect(ColorTokens.dark.textBase, const Color(0xFFFFFFFF));
      expect(ColorTokens.dark.textReverse, const Color(0xFF000000));
      expect(ColorTokens.dark.iconColor, const Color(0xFFFFFFFF));
    });

    test("selects app primary tokens without changing shared colors", () {
      final photosLight = ColorTokens.forApp(EnteApp.photos);
      final authLight = ColorTokens.forApp(EnteApp.auth);
      final lockerLight = ColorTokens.forApp(EnteApp.locker);
      final authDark = ColorTokens.forApp(
        EnteApp.auth,
        brightness: Brightness.dark,
      );

      expect(photosLight.primary, primaryDefaultLight);
      expect(photosLight.primaryLight, primaryLightLight);
      expect(photosLight.primaryStroke, primaryStrokeLight);
      expect(photosLight.primaryDark, primaryDarkLight);
      expect(photosLight.primaryDarker, primaryDarkerLight);

      expect(authLight.primary, authPrimaryDefaultLight);
      expect(authLight.primaryLight, authPrimaryLightLight);
      expect(authLight.primaryStroke, authPrimaryStrokeLight);
      expect(authLight.primaryDark, authPrimaryDarkLight);
      expect(authLight.primaryDarker, authPrimaryDarkerLight);

      expect(lockerLight.primary, lockerPrimaryDefaultLight);
      expect(lockerLight.primaryLight, lockerPrimaryLightLight);
      expect(lockerLight.primaryStroke, lockerPrimaryStrokeLight);
      expect(lockerLight.primaryDark, lockerPrimaryDarkLight);
      expect(lockerLight.primaryDarker, lockerPrimaryDarkerLight);

      expect(authDark.primary, authPrimaryDefaultDark);
      expect(authDark.primaryLight, authPrimaryLightDark);

      expect(authLight.backgroundBase, ColorTokens.light.backgroundBase);
      expect(authLight.warning, ColorTokens.light.warning);
      expect(authLight.info, ColorTokens.light.info);
      expect(lockerLight.textBase, ColorTokens.light.textBase);
      expect(lockerLight.iconColor, ColorTokens.light.iconColor);
      expect(lockerLight.accentPurple, ColorTokens.light.accentPurple);
    });

    test("match Figma Color Tokens light and dark modes", () {
      const expectedLight = <String, Color>{
        "accent/orange": Color.fromRGBO(242, 72, 34, 1),
        "accent/orange-light": Color.fromRGBO(255, 247, 244, 1),
        "accent/pink": Color.fromRGBO(223, 97, 187, 1),
        "accent/pink-light": Color.fromRGBO(253, 246, 251, 1),
        "accent/purple": Color.fromRGBO(138, 56, 245, 1),
        "accent/purple-light": Color.fromRGBO(248, 243, 254, 1),
        "accent/teal": Color.fromRGBO(95, 183, 187, 1),
        "accent/teal-light": Color.fromRGBO(245, 251, 251, 1),
        "background/base": Color.fromRGBO(250, 250, 250, 1),
        "caution/default": Color.fromRGBO(255, 169, 57, 1),
        "caution/light": Color.fromRGBO(250, 244, 235, 1),
        "fill/base": Color.fromRGBO(0, 0, 0, 1),
        "fill/dark": Color.fromRGBO(245, 245, 245, 1),
        "fill/darker": Color.fromRGBO(233, 233, 233, 1),
        "fill/darkest": Color.fromRGBO(210, 210, 210, 1),
        "fill/light": Color.fromRGBO(255, 255, 255, 1),
        "info/dark": Color.fromRGBO(14, 95, 217, 1),
        "info/darker": Color.fromRGBO(11, 76, 173, 1),
        "info/default": Color.fromRGBO(16, 113, 255, 1),
        "info/light": Color.fromRGBO(231, 239, 250, 1),
        "info/stroke": Color.fromRGBO(200, 216, 238, 1),
        "primary/dark": Color.fromRGBO(6, 157, 30, 1),
        "primary/darker": Color.fromRGBO(5, 124, 24, 1),
        "primary/default": Color.fromRGBO(8, 194, 37, 1),
        "primary/light": Color.fromRGBO(231, 246, 233, 1),
        "primary/stroke": Color.fromRGBO(186, 236, 194, 1),
        "special/content-reverse": Color.fromRGBO(255, 255, 255, 1),
        "special/scrim": Color.fromRGBO(0, 0, 0, 0.4),
        "special/white": Color.fromRGBO(255, 255, 255, 1),
        "special/white-overlay": Color.fromRGBO(255, 255, 255, 0.14),
        "stroke/dark": Color.fromRGBO(224, 224, 224, 1),
        "stroke/faint": Color.fromRGBO(235, 235, 235, 1),
        "text/base": Color.fromRGBO(0, 0, 0, 1),
        "text/dark": Color.fromRGBO(26, 26, 26, 1),
        "text/darker": Color.fromRGBO(21, 21, 21, 1),
        "text/light": Color.fromRGBO(102, 102, 102, 1),
        "text/lighter": Color.fromRGBO(150, 150, 150, 1),
        "text/lightest": Color.fromRGBO(222, 222, 222, 1),
        "text/reverse": Color.fromRGBO(255, 255, 255, 1),
        "warning/dark": Color.fromRGBO(221, 52, 52, 1),
        "warning/darker": Color.fromRGBO(197, 46, 46, 1),
        "warning/default": Color.fromRGBO(246, 58, 58, 1),
        "warning/light": Color.fromRGBO(250, 235, 235, 1),
      };
      const expectedDark = <String, Color>{
        "accent/orange": Color.fromRGBO(242, 72, 34, 1),
        "accent/orange-light": Color.fromRGBO(41, 41, 41, 1),
        "accent/pink": Color.fromRGBO(223, 97, 187, 1),
        "accent/pink-light": Color.fromRGBO(41, 41, 41, 1),
        "accent/purple": Color.fromRGBO(138, 56, 245, 1),
        "accent/purple-light": Color.fromRGBO(41, 41, 41, 1),
        "accent/teal": Color.fromRGBO(95, 183, 187, 1),
        "accent/teal-light": Color.fromRGBO(41, 41, 41, 1),
        "background/base": Color.fromRGBO(22, 22, 22, 1),
        "caution/default": Color.fromRGBO(255, 169, 57, 1),
        "caution/light": Color.fromRGBO(41, 41, 41, 1),
        "fill/base": Color.fromRGBO(255, 255, 255, 1),
        "fill/dark": Color.fromRGBO(10, 10, 10, 1),
        "fill/darker": Color.fromRGBO(20, 20, 20, 1),
        "fill/darkest": Color.fromRGBO(41, 41, 41, 1),
        "fill/light": Color.fromRGBO(33, 33, 33, 1),
        "info/dark": Color.fromRGBO(14, 95, 217, 1),
        "info/darker": Color.fromRGBO(11, 76, 173, 1),
        "info/default": Color.fromRGBO(16, 113, 255, 1),
        "info/light": Color.fromRGBO(41, 41, 41, 1),
        "info/stroke": Color.fromRGBO(26, 43, 77, 1),
        "primary/dark": Color.fromRGBO(6, 157, 30, 1),
        "primary/darker": Color.fromRGBO(5, 124, 24, 1),
        "primary/default": Color.fromRGBO(8, 194, 37, 1),
        "primary/light": Color.fromRGBO(41, 41, 41, 1),
        "primary/stroke": Color.fromRGBO(28, 65, 34, 1),
        "special/content-reverse": Color.fromRGBO(0, 0, 0, 1),
        "special/scrim": Color.fromRGBO(0, 0, 0, 0.4),
        "special/white": Color.fromRGBO(255, 255, 255, 1),
        "special/white-overlay": Color.fromRGBO(255, 255, 255, 0.14),
        "stroke/dark": Color.fromRGBO(62, 62, 62, 1),
        "stroke/faint": Color.fromRGBO(33, 33, 33, 1),
        "text/base": Color.fromRGBO(255, 255, 255, 1),
        "text/dark": Color.fromRGBO(229, 229, 229, 1),
        "text/darker": Color.fromRGBO(204, 204, 204, 1),
        "text/light": Color.fromRGBO(153, 153, 153, 1),
        "text/lighter": Color.fromRGBO(150, 150, 150, 1),
        "text/lightest": Color.fromRGBO(10, 10, 10, 1),
        "text/reverse": Color.fromRGBO(0, 0, 0, 1),
        "warning/dark": Color.fromRGBO(221, 52, 52, 1),
        "warning/darker": Color.fromRGBO(197, 46, 46, 1),
        "warning/default": Color.fromRGBO(246, 58, 58, 1),
        "warning/light": Color.fromRGBO(41, 41, 41, 1),
      };

      expect(_figmaColorTokenMap(ColorTokens.light), expectedLight);
      expect(_figmaColorTokenMap(ColorTokens.dark), expectedDark);
    });
  });

  group("text styles", () {
    test("match the published type scale", () {
      expect(TextStyles.fontFamily, "Inter");

      expect(TextStyles.h1.fontSize, 20);
      expect(TextStyles.h1.height, 28 / 20);
      expect(TextStyles.h1.fontWeight, FontWeight.w700);
      expect(TextStyles.h1.letterSpacing, 0);

      expect(TextStyles.h2.fontSize, 18);
      expect(TextStyles.h2.height, 24 / 18);
      expect(TextStyles.h2.fontWeight, FontWeight.w600);

      expect(TextStyles.body.fontSize, 14);
      expect(TextStyles.body.height, 20 / 14);
      expect(TextStyles.body.fontWeight, FontWeight.w500);

      expect(TextStyles.mini.fontSize, 12);
      expect(TextStyles.tiny.fontSize, 10);
      expect(TextStyles.bodyLink.decoration, TextDecoration.underline);
    });
  });

  group("theme", () {
    test("maps color and text tokens into light ThemeData", () {
      final theme = ComponentTheme.lightTheme();

      expect(theme.brightness, Brightness.light);
      expect(
        theme.scaffoldBackgroundColor,
        ColorTokens.light.backgroundBase,
      );
      expect(theme.colorScheme.primary, ColorTokens.light.primary);
      expect(theme.colorScheme.error, ColorTokens.light.warning);
      expect(
        theme.textTheme.headlineLarge?.fontFamily,
        TextStyles.fontFamily,
      );
      expect(
        theme.textTheme.headlineLarge?.fontSize,
        TextStyles.h1.fontSize,
      );
      expect(
        theme.textTheme.headlineLarge?.fontWeight,
        TextStyles.h1.fontWeight,
      );
      expect(
        theme.textTheme.bodyMedium?.fontFamily,
        TextStyles.fontFamily,
      );
      expect(
        theme.textTheme.bodyMedium?.fontSize,
        TextStyles.body.fontSize,
      );
    });

    test("maps color and text tokens into dark ThemeData", () {
      final theme = ComponentTheme.darkTheme();

      expect(theme.brightness, Brightness.dark);
      expect(
        theme.scaffoldBackgroundColor,
        ColorTokens.dark.backgroundBase,
      );
      expect(theme.colorScheme.primary, ColorTokens.dark.primary);
      expect(theme.colorScheme.error, ColorTokens.dark.warning);
      expect(
        theme.textTheme.labelSmall?.fontFamily,
        TextStyles.fontFamily,
      );
      expect(
        theme.textTheme.labelSmall?.fontSize,
        TextStyles.tiny.fontSize,
      );
      expect(
        theme.textTheme.labelSmall?.fontWeight,
        TextStyles.tiny.fontWeight,
      );
    });

    test("maps selected app primary tokens into ThemeData", () {
      final authTheme = ComponentTheme.lightTheme(app: EnteApp.auth);
      final lockerTheme = ComponentTheme.darkTheme(app: EnteApp.locker);

      expect(authTheme.colorScheme.primary, authPrimaryDefaultLight);
      expect(
        authTheme.scaffoldBackgroundColor,
        ColorTokens.light.backgroundBase,
      );
      expect(lockerTheme.colorScheme.primary, lockerPrimaryDefaultDark);
      expect(
        lockerTheme.scaffoldBackgroundColor,
        ColorTokens.dark.backgroundBase,
      );
    });

    testWidgets("selects color tokens from the ambient brightness",
        (tester) async {
      late ColorTokens lightColors;
      late ColorTokens darkColors;

      await tester.pumpWidget(
        Theme(
          data: ComponentTheme.lightTheme(),
          child: Builder(
            builder: (context) {
              lightColors = ComponentTheme.colorsOf(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      await tester.pumpWidget(
        Theme(
          data: ComponentTheme.darkTheme(),
          child: Builder(
            builder: (context) {
              darkColors = context.componentColors;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(lightColors.backgroundBase, ColorTokens.light.backgroundBase);
      expect(lightColors.textBase, ColorTokens.light.textBase);
      expect(darkColors.backgroundBase, ColorTokens.dark.backgroundBase);
      expect(darkColors.textBase, ColorTokens.dark.textBase);
    });

    testWidgets("reads app-aware tokens from ComponentTheme ThemeData",
        (tester) async {
      late ColorTokens authColors;
      late ColorTokens lockerColors;

      await tester.pumpWidget(
        Theme(
          data: ComponentTheme.lightTheme(app: EnteApp.auth),
          child: Builder(
            builder: (context) {
              authColors = context.componentColors;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      await tester.pumpWidget(
        Theme(
          data: ComponentTheme.darkTheme(app: EnteApp.locker),
          child: Builder(
            builder: (context) {
              lockerColors = context.componentColors;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(authColors.primary, authPrimaryDefaultLight);
      expect(authColors.backgroundBase, ColorTokens.light.backgroundBase);
      expect(lockerColors.primary, lockerPrimaryDefaultDark);
      expect(lockerColors.backgroundBase, ColorTokens.dark.backgroundBase);
    });

    test("defaults to photos primary tokens when no app is passed", () {
      expect(
        ComponentTheme.lightTheme().colorScheme.primary,
        primaryDefaultLight,
      );
    });
  });
}

Map<String, Color> _figmaColorTokenMap(ColorTokens colors) {
  return {
    "accent/orange": colors.accentOrange,
    "accent/orange-light": colors.accentOrangeLight,
    "accent/pink": colors.accentPink,
    "accent/pink-light": colors.accentPinkLight,
    "accent/purple": colors.accentPurple,
    "accent/purple-light": colors.accentPurpleLight,
    "accent/teal": colors.accentTeal,
    "accent/teal-light": colors.accentTealLight,
    "background/base": colors.backgroundBase,
    "caution/default": colors.caution,
    "caution/light": colors.cautionLight,
    "fill/base": colors.fillBase,
    "fill/dark": colors.fillDark,
    "fill/darker": colors.fillDarker,
    "fill/darkest": colors.fillDarkest,
    "fill/light": colors.fillLight,
    "info/dark": colors.infoDark,
    "info/darker": colors.infoDarker,
    "info/default": colors.info,
    "info/light": colors.infoLight,
    "info/stroke": colors.infoStroke,
    "primary/dark": colors.primaryDark,
    "primary/darker": colors.primaryDarker,
    "primary/default": colors.primary,
    "primary/light": colors.primaryLight,
    "primary/stroke": colors.primaryStroke,
    "special/content-reverse": colors.specialContentReverse,
    "special/scrim": colors.specialScrim,
    "special/white": colors.specialWhite,
    "special/white-overlay": colors.specialWhiteOverlay,
    "stroke/dark": colors.strokeDark,
    "stroke/faint": colors.strokeFaint,
    "text/base": colors.textBase,
    "text/dark": colors.textDark,
    "text/darker": colors.textDarker,
    "text/light": colors.textLight,
    "text/lighter": colors.textLighter,
    "text/lightest": colors.textLightest,
    "text/reverse": colors.textReverse,
    "warning/dark": colors.warningDark,
    "warning/darker": colors.warningDarker,
    "warning/default": colors.warning,
    "warning/light": colors.warningLight,
  };
}
