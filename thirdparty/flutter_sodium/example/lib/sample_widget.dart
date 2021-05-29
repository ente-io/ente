import 'package:flutter/material.dart';
import 'toc.dart';

class SampleWidget extends StatelessWidget {
  final Sample sample;
  SampleWidget(this.sample);

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: Text(sample.title ?? '(no title)',
              style: Theme.of(context).textTheme.headline5)),
      if (sample.description != null && sample.description!.length > 0)
        Padding(
          padding: EdgeInsets.only(bottom: 16.0),
          child: Text(sample.description!),
        ),
      CodeBlock(sample.code),
      SampleRunner(sample)
    ]);
  }
}

class SampleRunner extends StatefulWidget {
  final Sample sample;

  SampleRunner(this.sample);

  @override
  State<StatefulWidget> createState() => _SampleRunnerState();
}

class _SampleRunnerState extends State<SampleRunner> {
  Future<String>? _sampleRun;

  void _runSample() {
    setState(() {
      _sampleRun = _runSampleHost();
    });
  }

  Future<String> _runSampleHost() async {
    final out = StringBuffer();

    // run sync or async code sample
    if (widget.sample.funcAsync != null) {
      await widget.sample.funcAsync!((o) => out.writeln(o));
    } else if (widget.sample.func != null) {
      widget.sample.func!((o) => out.writeln(o));
    }
    return out.toString().trim();
  }

  @override
  Widget build(BuildContext context) {
    if (_sampleRun == null) {
      return Padding(
          padding: EdgeInsets.only(top: 16.0), child: RunButton(_runSample));
    }

    return FutureBuilder(
        future: _sampleRun,
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) =>
            Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: RunButton(
                          snapshot.connectionState == ConnectionState.done
                              ? _runSample
                              : null)),
                  Padding(
                      padding: EdgeInsets.only(bottom: 16.0),
                      child: Text('Result',
                          style: Theme.of(context).textTheme.headline6)),
                  // display progress only for async code snippets
                  if (widget.sample.funcAsync != null &&
                      snapshot.connectionState != ConnectionState.done)
                    LinearProgressIndicator(),
                  AnimatedOpacity(
                      opacity: snapshot.connectionState == ConnectionState.done
                          ? 1
                          : 0,
                      duration: Duration(
                          milliseconds:
                              snapshot.connectionState == ConnectionState.done
                                  ? 150
                                  : 50),
                      child: CodeBlock(
                          snapshot.hasError
                              ? snapshot.error.toString()
                              : snapshot.data,
                          color: snapshot.hasError
                              ? Colors.red.shade200
                              : Colors.green.shade200)),
                ]));
  }
}

class RunButton extends StatelessWidget {
  final VoidCallback? onPressed;

  RunButton(this.onPressed);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(child: Text('Run'), onPressed: onPressed);
  }
}

class CodeBlock extends StatelessWidget {
  final String? _code;
  final Color color;

  CodeBlock(this._code, {this.color = Colors.black12});

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.all(10.0),
        color: color,
        child: Text(_code ?? '(code not found)',
            style: TextStyle(fontFamily: 'RobotoMono', fontSize: 12.0)));
  }
}
