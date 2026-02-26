import 'dart:io';

void main(List<String> args) {
  if (args.length != 2) {
    stderr.writeln(
      'Usage: dart run scripts/generate_timezone_aliases.dart <backward> <output>',
    );
    exit(2);
  }

  final backwardFile = File(args[0]);
  final outputFile = File(args[1]);

  if (!backwardFile.existsSync()) {
    stderr.writeln('Backward file not found: ${backwardFile.path}');
    exit(2);
  }

  final alias = <String, String>{};

  for (final line in backwardFile.readAsLinesSync()) {
    final cleaned = line.split('#').first.trim();
    if (cleaned.isEmpty) {
      continue;
    }
    if (!cleaned.startsWith('Link')) {
      continue;
    }
    final parts = cleaned.split(RegExp(r'\s+'));
    if (parts.length < 3) {
      continue;
    }
    final target = parts[1];
    final name = parts[2];
    alias[name] = target;
  }

  String resolve(String name) {
    final seen = <String>{};
    var current = name;
    while (alias.containsKey(current) && !seen.contains(current)) {
      seen.add(current);
      current = alias[current]!;
    }
    return current;
  }

  final resolved = <String, String>{};
  for (final entry in alias.entries) {
    resolved[entry.key] = resolve(entry.key);
  }

  final keys = resolved.keys.toList()..sort();
  final buffer = StringBuffer()
    ..writeln('// GENERATED CODE - DO NOT MODIFY BY HAND')
    ..writeln('// Generated from tzdb backward file.')
    ..writeln('// Regenerate with: scripts/update_timezone_aliases.sh')
    ..writeln('const Map<String, String> kTimeZoneAliases = {');
  for (final key in keys) {
    buffer.writeln("  '$key': '${resolved[key]}',");
  }
  buffer.writeln('};');

  outputFile.writeAsStringSync(buffer.toString());
}
