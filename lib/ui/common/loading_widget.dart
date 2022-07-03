import 'package:flutter/cupertino.dart';

class EnteLoadingWidget extends StatelessWidget {
  const EnteLoadingWidget({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox.fromSize(
        size: Size.square(30),
        child: CupertinoActivityIndicator(),
      ),
    );
  }
}
