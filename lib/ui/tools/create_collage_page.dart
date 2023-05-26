import "package:flutter/material.dart";
import "package:flutter/widgets.dart";
import "package:logging/logging.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/file.dart";

class CreateCollagePage extends StatefulWidget {
  final List<File> files;

  const CreateCollagePage(this.files, {super.key});

  @override
  State<CreateCollagePage> createState() => _CreateCollagePageState();
}

class _CreateCollagePageState extends State<CreateCollagePage> {
  final _logger = Logger("CreateCollagePage");

  @override
  Widget build(BuildContext context) {
    for (final file in widget.files) {
      _logger.info(file.displayName);
    }
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(S.of(context).createCollage),
      ),
      body: _getBody(),
    );
  }

  Widget _getBody() {
    return Text("Collage!");
  }
}
