import 'package:flutter/material.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'toc.dart';
import 'topic_page.dart';

void main() {
  Sodium.init();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'flutter_sodium',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('flutter_sodium'),
        ),
        body: SafeArea(
            child: FutureBuilder(
                // build table of contents
                future: buildToc(context),
                builder: (BuildContext context,
                    AsyncSnapshot<List<Topic>> snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return snapshot.hasError
                        ? Text("Build TOC failed\n\n${snapshot.error}")
                        : ListView(children: <Widget>[
                            if (snapshot.hasData)
                              for (var topic in snapshot.data!)
                                if (topic is Section)
                                  ListTile(
                                      title: Text(topic.title,
                                          style: Theme.of(context)
                                              .textTheme
                                              .headline6))
                                else
                                  ListTile(
                                      title: Text(topic.title),
                                      trailing: Icon(Icons.arrow_forward_ios,
                                          size: 12.0),
                                      onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  TopicPage(topic))))
                          ]);
                  }

                  return Container();
                })));
  }
}
