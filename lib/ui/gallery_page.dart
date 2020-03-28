import 'package:flutter/material.dart';
import 'package:myapp/photo_provider.dart';
import 'package:myapp/ui/image_widget.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:myapp/ui/change_notifier_builder.dart';
import 'package:myapp/ui/loading_widget.dart';
import 'package:myapp/ui/detail_page.dart';
import 'package:provider/provider.dart';

class GalleryPage extends StatefulWidget {
  final AssetPathEntity path;

  const GalleryPage({Key key, this.path}) : super(key: key);

  @override
  _GalleryPageState createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  AssetPathEntity get path => widget.path;

  PathProvider get provider =>
      Provider.of<PhotoProvider>(context).getOrCreatePathProvider(path);

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierBuilder(
      value: provider,
      builder: (_, __) {
        var length = path.assetCount;
        return Scaffold(
          appBar: AppBar(
            title: Text("Orma"),
          ),
          body: buildRefreshIndicator(length),
        );
      },
    );
  }

  Widget buildRefreshIndicator(int length) {
    if (!provider.isInit) {
      provider.onRefresh();
      return Center(
        child: Text("loading"),
      );
    }
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: Scrollbar(
        child: GridView.builder(
          itemBuilder: _buildItem,
          itemCount: provider.showItemCount,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
          ),
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    final list = provider.list;
    if (list.length == index) {
      onLoadMore();
      return loadWidget;
    }

    if (index > list.length) {
      return Container();
    }

    final entity = list[index];
    return GestureDetector(
      onTap: () async {
        routeToDetailPage(entity);
      },
      child: ImageWidget(
        key: ValueKey(entity),
        path: "",
      ),
    );
  }

  void routeToDetailPage(AssetEntity entity) async {
    final originFile = await entity.originFile;
    final page = DetailPage(
      file: originFile,
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) {
          return page;
        },
      ),
    );
  }

  Future<void> onLoadMore() async {
    if (!mounted) {
      return;
    }
    await provider.onLoadMore();
  }

  Future<void> _onRefresh() async {
    if (!mounted) {
      return;
    }
    await provider.onRefresh();
  }
}