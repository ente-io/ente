// @dart=2.9

import 'package:flutter/material.dart';
import 'package:photos/db/trash_db.dart';
import 'package:photos/ui/viewer/gallery/trash_page.dart';
import 'package:photos/utils/navigation_util.dart';

class TrashButtonWidget extends StatelessWidget {
  const TrashButtonWidget(
    this.textStyle, {
    Key key,
  }) : super(key: key);

  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: Theme.of(context).backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(0),
        side: BorderSide(
          width: 0.5,
          color: Theme.of(context).iconTheme.color.withOpacity(0.24),
        ),
      ),
      child: SizedBox(
        height: 48,
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.delete,
                    color: Theme.of(context).iconTheme.color,
                  ),
                  const Padding(padding: EdgeInsets.all(6)),
                  FutureBuilder<int>(
                    future: TrashDB.instance.count(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data > 0) {
                        return RichText(
                          text: TextSpan(
                            style: textStyle,
                            children: [
                              TextSpan(
                                text: "Trash",
                                style: Theme.of(context).textTheme.subtitle1,
                              ),
                              const TextSpan(text: "  \u2022  "),
                              TextSpan(
                                text: snapshot.data.toString(),
                              ),
                              //need to query in db and bring this value
                            ],
                          ),
                        );
                      } else {
                        return RichText(
                          text: TextSpan(
                            style: textStyle,
                            children: [
                              TextSpan(
                                text: "Trash",
                                style: Theme.of(context).textTheme.subtitle1,
                              ),
                              //need to query in db and bring this value
                            ],
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).iconTheme.color,
              ),
            ],
          ),
        ),
      ),
      onPressed: () async {
        routeToPage(
          context,
          TrashPage(),
        );
      },
    );
  }
}
