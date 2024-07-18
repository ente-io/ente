import 'package:ente_auth/l10n/l10n.dart';
import 'package:ente_auth/utils/platform_util.dart';
import 'package:flutter/material.dart';

class RawCodesViewer extends StatefulWidget {
  final String rawData;
  const RawCodesViewer(this.rawData, {super.key});

  @override
  State<RawCodesViewer> createState() => _RawCodesViewerState();
}

class _RawCodesViewerState extends State<RawCodesViewer> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(context.l10n.rawCodeData),
      ),
      body: _getBody(),
    );
  }

  Widget _getBody() {
    return Container(
      padding: const EdgeInsets.only(left: 12, top: 8, right: 12),
      child: SingleChildScrollView(
        child: SelectableRegion(
          focusNode: FocusNode(),
          selectionControls: PlatformUtil.selectionControls,
          child: Text(
            widget.rawData,
            style: const TextStyle(
              fontFeatures: [
                FontFeature.tabularFigures(),
              ],
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}
