import 'package:flutter/material.dart';
import "package:pro_image_editor/mixins/converted_configs.dart";
import "package:pro_image_editor/models/editor_callbacks/pro_image_editor_callbacks.dart";
import "package:pro_image_editor/models/editor_configs/pro_image_editor_configs.dart";

/// A mixin providing access to simple editor configurations.
mixin SimpleConfigsAccess on StatefulWidget {
  ProImageEditorConfigs get configs;
  ProImageEditorCallbacks get callbacks;
}

mixin SimpleConfigsAccessState<T extends StatefulWidget>
    on State<T>, ImageEditorConvertedConfigs {
  SimpleConfigsAccess get _widget => (widget as SimpleConfigsAccess);

  @override
  ProImageEditorConfigs get configs => _widget.configs;

  ProImageEditorCallbacks get callbacks => _widget.callbacks;
}
