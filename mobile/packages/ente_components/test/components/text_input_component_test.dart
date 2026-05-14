import "package:ente_components/ente_components.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  testWidgets(
      "TextInputComponent renders label, required mark, and helper text", (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const TextInputComponent(
          label: "Email",
          hintText: "name@example.com",
          helperText: "Use your account email",
          isRequired: true,
        ),
      ),
    );

    expect(_richText("Email *"), findsOneWidget);
    expect(find.text("Use your account email"), findsOneWidget);
    expect(
      tester.widget<Text>(find.text("Use your account email")).style?.color,
      ColorTokens.light.textLight,
    );
    expect(
      tester
          .widget<TextField>(
            find.byType(TextField),
          )
          .decoration
          ?.hintText,
      "name@example.com",
    );
  });

  testWidgets("TextInputComponent gives error text priority over helper text", (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const TextInputComponent(
          label: "Password",
          helperText: "At least 8 characters",
          errorText: "Password is required",
        ),
      ),
    );

    expect(find.text("Password is required"), findsOneWidget);
    expect(find.text("At least 8 characters"), findsNothing);
    expect(
      tester.widget<Text>(find.text("Password is required")).style?.color,
      ColorTokens.light.warning,
    );
  });

  testWidgets("TextInputComponent renders success text when valid",
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        const TextInputComponent(
          label: "Code",
          successText: "Looks good",
        ),
      ),
    );

    expect(find.text("Looks good"), findsOneWidget);
    expect(
      tester.widget<Text>(find.text("Looks good")).style?.color,
      ColorTokens.light.primary,
    );
  });

  testWidgets("TextInputComponent supports explicit focused visual state", (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const TextInputComponent(
          label: "Email",
          isFocused: true,
        ),
      ),
    );

    final input = tester.widget<TextField>(
      find.byType(TextField),
    );
    final border = input.decoration?.enabledBorder as OutlineInputBorder?;
    expect(border?.borderSide.color, ColorTokens.light.primary);
    expect(border?.borderSide.width, 2);
  });

  testWidgets(
      "TextInputComponent maps error and success states to Figma borders", (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const Column(
          children: [
            TextInputComponent(label: "Error", errorText: "This is an error"),
            TextInputComponent(label: "Success", successText: "Saved"),
          ],
        ),
      ),
    );

    final inputs = tester.widgetList<TextField>(
      find.byType(TextField),
    );
    final errorBorder =
        inputs.first.decoration?.enabledBorder as OutlineInputBorder?;
    final successBorder =
        inputs.last.decoration?.enabledBorder as OutlineInputBorder?;

    expect(errorBorder?.borderSide.color, ColorTokens.light.warning);
    expect(errorBorder?.borderSide.width, 1.5);
    expect(successBorder?.borderSide.color, ColorTokens.light.primary);
    expect(successBorder?.borderSide.width, 1.5);
  });

  testWidgets(
      "TextInputComponent forwards disabled state to the platform field", (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const TextInputComponent(
          label: "Email",
          enabled: false,
        ),
      ),
    );

    final input = tester.widget<TextField>(
      find.byType(TextField),
    );
    expect(input.enabled, isFalse);
    expect(input.decoration?.fillColor, ColorTokens.light.fillLight);
    expect(tester.widget<Opacity>(find.byType(Opacity).first).opacity, 0.38);
  });

  testWidgets("TextInputComponent supports the Figma multiline layout",
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        const TextInputComponent(
          label: "Notes",
          hintText: "Hint text",
          errorText: "This is an error",
          maxLines: 4,
          suffix: Icon(Icons.copy, key: ValueKey("copy-icon")),
        ),
      ),
    );

    final input = tester.widget<TextField>(
      find.byType(TextField),
    );
    final border = input.decoration?.enabledBorder as OutlineInputBorder?;

    expect(input.maxLines, 4);
    expect(
      input.decoration?.contentPadding,
      const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
    );
    expect(border?.borderRadius, BorderRadius.circular(16));
    expect(border?.borderSide.color, ColorTokens.light.warning);
    expect(border?.borderSide.width, 1.5);
    expect(find.byKey(const ValueKey("copy-icon")), findsOneWidget);
    expect(
      tester.widget<Text>(find.text("This is an error")).style?.fontSize,
      TextStyles.tiny.fontSize,
    );
  });

  testWidgets("TextInputComponent accepts text entry and reports changes", (
    tester,
  ) async {
    final controller = TextEditingController();
    var changedValue = "";
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _wrap(
        TextInputComponent(
          controller: controller,
          label: "Name",
          onChanged: (value) => changedValue = value,
        ),
      ),
    );

    await tester.enterText(find.byType(TextInputComponent), "Ada Lovelace");
    await tester.pump();

    expect(controller.text, "Ada Lovelace");
    expect(changedValue, "Ada Lovelace");
    expect(find.text("Ada Lovelace"), findsOneWidget);
  });

  testWidgets("TextInputComponent forwards production text input behavior", (
    tester,
  ) async {
    final controller = TextEditingController();
    final focusNode = FocusNode();
    final scrollController = ScrollController();
    var submitted = "";
    var editingComplete = false;
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(
      _wrap(
        TextInputComponent(
          controller: controller,
          focusNode: focusNode,
          label: "Invite email",
          autofocus: true,
          readOnly: true,
          showCursor: false,
          enableInteractiveSelection: false,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp("[a-z@.]")),
          ],
          maxLength: 48,
          counterText: "",
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          autocorrect: false,
          enableSuggestions: false,
          textAlign: TextAlign.center,
          textAlignVertical: TextAlignVertical.top,
          scrollController: scrollController,
          onSubmitted: (value) => submitted = value,
          onEditingComplete: () => editingComplete = true,
        ),
      ),
    );

    final input = tester.widget<TextField>(
      find.byType(TextField),
    );
    expect(input.focusNode, focusNode);
    expect(input.autofocus, isTrue);
    expect(input.readOnly, isTrue);
    expect(input.showCursor, isFalse);
    expect(input.enableInteractiveSelection, isFalse);
    expect(input.textCapitalization, TextCapitalization.words);
    expect(input.textInputAction, TextInputAction.done);
    expect(input.maxLength, 48);
    expect(input.decoration?.counterText, "");
    expect(input.keyboardType, TextInputType.emailAddress);
    expect(input.autofillHints, const [AutofillHints.email]);
    expect(input.autocorrect, isFalse);
    expect(input.enableSuggestions, isFalse);
    expect(input.textAlign, TextAlign.center);
    expect(input.textAlignVertical, TextAlignVertical.top);
    expect(input.scrollController, scrollController);

    input.onSubmitted?.call("mira@example.com");
    input.onEditingComplete?.call();
    expect(submitted, "mira@example.com");
    expect(editingComplete, isTrue);
  });

  testWidgets(
      "TextInputComponent supports clear and password visibility affordances", (
    tester,
  ) async {
    final clearController = TextEditingController(text: "search");
    final passwordController = TextEditingController(text: "secret");
    addTearDown(clearController.dispose);
    addTearDown(passwordController.dispose);

    await tester.pumpWidget(
      _wrap(
        Column(
          children: [
            TextInputComponent(
              controller: clearController,
              label: "Search",
              isClearable: true,
            ),
            TextInputComponent(
              controller: passwordController,
              label: "Password",
              obscureText: true,
              showPasswordToggle: true,
            ),
          ],
        ),
      ),
    );

    expect(find.byKey(const ValueKey("text-field-clear")), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey("text-field-clear")));
    await tester.pump();
    expect(clearController.text, "");
    expect(find.byKey(const ValueKey("text-field-clear")), findsNothing);

    var inputs = tester.widgetList<TextField>(
      find.byType(TextField),
    );
    expect(inputs.last.obscureText, isTrue);

    await tester.tap(find.byKey(const ValueKey("text-field-password-toggle")));
    await tester.pump();
    inputs = tester.widgetList<TextField>(
      find.byType(TextField),
    );
    expect(inputs.last.obscureText, isFalse);
  });

  testWidgets("TextInputComponent renders alert message visuals",
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        const TextInputComponent(
          label: "Recovery key",
          alertText: "Save this somewhere safe.",
        ),
      ),
    );

    expect(find.text("Save this somewhere safe."), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    expect(
      tester.widget<Text>(find.text("Save this somewhere safe.")).style?.color,
      ColorTokens.light.warning,
    );
  });
}

Finder _richText(String value) {
  return find.byWidgetPredicate(
    (widget) => widget is Text && widget.textSpan?.toPlainText() == value,
  );
}

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: ComponentTheme.lightTheme(),
    home: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: child,
      ),
    ),
  );
}
