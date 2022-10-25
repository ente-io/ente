import 'package:flutter/material.dart';
import 'package:photos/theme/ente_theme.dart';

class TitleBarWidget extends StatelessWidget {
  const TitleBarWidget({super.key});

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
            children: [
              IconButton(
                visualDensity:
                    const VisualDensity(horizontal: -2, vertical: -2),
                onPressed: () {},
                icon: Icon(
                  Icons.favorite_border_rounded,
                  color: getEnteColorScheme(context).strokeBase,
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                visualDensity:
                    const VisualDensity(horizontal: -2, vertical: -2),
                onPressed: () {},
                icon: Icon(
                  Icons.more_horiz_outlined,
                  color: getEnteColorScheme(context).strokeBase,
                ),
              ),
            ],
          ),
        ),
      ],
      // iconTheme:
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
}
