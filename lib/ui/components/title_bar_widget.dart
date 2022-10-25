import 'package:flutter/material.dart';
import 'package:photos/theme/ente_theme.dart';

class TitleBarWidget extends StatelessWidget {
  final List<Widget>? actionIcons;
  const TitleBarWidget({this.actionIcons, super.key});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      toolbarHeight: 48,
      leadingWidth: 48,
      automaticallyImplyLeading: false,
      pinned: true,
      expandedHeight: 102,
      centerTitle: false,
      titleSpacing: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            'Title',
            style: getEnteTextTheme(context).largeBold,
          ),
          Text(
            'Caption',
            style: getEnteTextTheme(context)
                .mini
                .copyWith(color: getEnteColorScheme(context).textMuted),
          )
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
          child: Row(
            children: _getActions(),
          ),
        ),
      ],
      leading: Padding(
        padding: const EdgeInsets.all(4),
        child: IconButton(
          visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_outlined),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Title',
                style: getEnteTextTheme(context).h3Bold,
              ),
              Text(
                'Caption',
                style: getEnteTextTheme(context)
                    .small
                    .copyWith(color: getEnteColorScheme(context).textMuted),
              )
            ],
          ),
        ),
      ),
    );
  }

  _getActions() {
    if (actionIcons == null) {
      return <Widget>[const SizedBox.shrink()];
    }
    final actions = <Widget>[];
    bool addWhiteSpace = false;
    final length = actionIcons!.length;
    int index = 0;
    if (length == 0) {
      return <Widget>[const SizedBox.shrink()];
    }
    if (length == 1) {
      return actionIcons;
    }
    while (index < length) {
      if (!addWhiteSpace) {
        actions.add(actionIcons![index]);
        index++;
        addWhiteSpace = true;
      } else {
        actions.add(const SizedBox(width: 4));
        addWhiteSpace = false;
      }
    }
    return actions;
  }
}
