// Adapted from: https://github.com/deckerst/aves

import "package:collection/collection.dart";
import "package:intl/intl.dart";
import "package:photos/models/ffmpeg/channel_layouts.dart";
import "package:photos/models/ffmpeg/codecs.dart";
import "package:photos/models/ffmpeg/ffprobe_keys.dart";
import "package:photos/models/ffmpeg/language.dart";
import "package:photos/models/ffmpeg/mp4.dart";
import "package:photos/models/location/location.dart";

class FFProbeProps {
  final double? captureFps;
  final String? androidManufacturer;
  final String? androidModel;
  final String? androidVersion;
  final String? bitRate;
  final String? bitsPerRawSample;
  final String? byteCount;
  final String? channelLayout;
  final String? chromaLocation;
  final String? codecName;
  final String? codecPixelFormat;
  final int? codedHeight;
  final int? codedWidth;
  final String? colorPrimaries;
  final String? colorRange;
  final String? colorSpace;
  final String? colorTransfer;
  final String? colorProfile;
  final String? compatibleBrands;
  final String? creationTime;
  final String? displayAspectRatio;
  final DateTime? date;
  final String? duration;
  final String? durationMicros;
  final String? extraDataSize;
  final String? fieldOrder;
  final String? fpsDen;
  final int? frameCount;
  final String? handlerName;
  final bool? hasBFrames;
  final int? height;
  final String? language;
  final Location? location;
  final String? majorBrand;
  final String? mediaFormat;
  final String? mediaType;
  final String? minorVersion;
  final String? nalLengthSize;
  final String? quicktimeLocationAccuracyHorizontal;
  final int? rFrameRate;
  final String? rotate;
  final String? sampleFormat;
  final String? sampleRate;
  final String? sampleAspectRatio;
  final String? sarDen;
  final int? segmentCount;
  final String? sourceOshash;
  final String? startMicros;
  final String? startPts;
  final String? startTime;
  final String? statisticsWritingApp;
  final String? statisticsWritingDateUtc;
  final String? timeBase;
  final String? track;
  final String? vendorId;
  final int? width;
  final String? xiaomiSlowMoment;

  FFProbeProps({
    required this.captureFps,
    required this.androidManufacturer,
    required this.androidModel,
    required this.androidVersion,
    required this.bitRate,
    required this.bitsPerRawSample,
    required this.byteCount,
    required this.channelLayout,
    required this.chromaLocation,
    required this.codecName,
    required this.codecPixelFormat,
    required this.codedHeight,
    required this.codedWidth,
    required this.colorPrimaries,
    required this.colorRange,
    required this.colorSpace,
    required this.colorTransfer,
    required this.colorProfile,
    required this.compatibleBrands,
    required this.creationTime,
    required this.displayAspectRatio,
    required this.date,
    required this.duration,
    required this.durationMicros,
    required this.extraDataSize,
    required this.fieldOrder,
    required this.fpsDen,
    required this.frameCount,
    required this.handlerName,
    required this.hasBFrames,
    required this.height,
    required this.language,
    required this.location,
    required this.majorBrand,
    required this.mediaFormat,
    required this.mediaType,
    required this.minorVersion,
    required this.nalLengthSize,
    required this.quicktimeLocationAccuracyHorizontal,
    required this.rFrameRate,
    required this.rotate,
    required this.sampleFormat,
    required this.sampleRate,
    required this.sampleAspectRatio,
    required this.sarDen,
    required this.segmentCount,
    required this.sourceOshash,
    required this.startMicros,
    required this.startPts,
    required this.startTime,
    required this.statisticsWritingApp,
    required this.statisticsWritingDateUtc,
    required this.timeBase,
    required this.track,
    required this.vendorId,
    required this.width,
    required this.xiaomiSlowMoment,
  });

  factory FFProbeProps.fromJson(Map<dynamic, dynamic>? json) {
    return FFProbeProps(
      captureFps:
          double.tryParse(json?[FFProbeKeys.androidCaptureFramerate] ?? ""),
      androidManufacturer: json?[FFProbeKeys.androidManufacturer],
      androidModel: json?[FFProbeKeys.androidModel],
      androidVersion: json?[FFProbeKeys.androidVersion],
      bitRate: _formatMetric(
        json?[FFProbeKeys.bitrate] ?? json?[FFProbeKeys.bps],
        'b/s',
      ),
      bitsPerRawSample: json?[FFProbeKeys.bitsPerRawSample],
      byteCount: _formatFilesize(json?[FFProbeKeys.byteCount]),
      channelLayout: _formatChannelLayout(json?[FFProbeKeys.channelLayout]),
      chromaLocation: json?[FFProbeKeys.chromaLocation],
      codecName: _formatCodecName(json?[FFProbeKeys.codecName]),
      codecPixelFormat:
          (json?[FFProbeKeys.codecPixelFormat] as String?)?.toUpperCase(),
      codedHeight: int.tryParse(json?[FFProbeKeys.codedHeight] ?? ""),
      codedWidth: int.tryParse(json?[FFProbeKeys.codedWidth] ?? ""),
      colorPrimaries:
          (json?[FFProbeKeys.colorPrimaries] as String?)?.toUpperCase(),
      colorRange: (json?[FFProbeKeys.colorRange] as String?)?.toUpperCase(),
      colorSpace: (json?[FFProbeKeys.colorSpace] as String?)?.toUpperCase(),
      colorTransfer:
          (json?[FFProbeKeys.colorTransfer] as String?)?.toUpperCase(),
      colorProfile: json?[FFProbeKeys.colorTransfer],
      compatibleBrands: json?[FFProbeKeys.compatibleBrands],
      creationTime: _formatDate(json?[FFProbeKeys.creationTime] ?? ""),
      displayAspectRatio: json?[FFProbeKeys.dar],
      date: DateTime.tryParse(json?[FFProbeKeys.date] ?? ""),
      duration: _formatDuration(json?[FFProbeKeys.durationMicros]),
      durationMicros: formatPreciseDuration(
        Duration(
          microseconds:
              int.tryParse(json?[FFProbeKeys.durationMicros] ?? "") ?? 0,
        ),
      ),
      extraDataSize: json?[FFProbeKeys.extraDataSize],
      fieldOrder: json?[FFProbeKeys.fieldOrder],
      fpsDen: json?[FFProbeKeys.fpsDen],
      frameCount: int.tryParse(json?[FFProbeKeys.frameCount] ?? ""),
      handlerName: json?[FFProbeKeys.handlerName],
      hasBFrames: json?[FFProbeKeys.hasBFrames],
      height: int.tryParse(json?[FFProbeKeys.height] ?? ""),
      language: json?[FFProbeKeys.language],
      location: _formatLocation(json?[FFProbeKeys.location]),
      majorBrand: json?[FFProbeKeys.majorBrand],
      mediaFormat: json?[FFProbeKeys.mediaFormat],
      mediaType: json?[FFProbeKeys.mediaType],
      minorVersion: json?[FFProbeKeys.minorVersion],
      nalLengthSize: json?[FFProbeKeys.nalLengthSize],
      quicktimeLocationAccuracyHorizontal:
          json?[FFProbeKeys.quicktimeLocationAccuracyHorizontal],
      rFrameRate: int.tryParse(json?[FFProbeKeys.rFrameRate] ?? ""),
      rotate: json?[FFProbeKeys.rotate],
      sampleFormat: json?[FFProbeKeys.sampleFormat],
      sampleRate: json?[FFProbeKeys.sampleRate],
      sampleAspectRatio: json?[FFProbeKeys.sar],
      sarDen: json?[FFProbeKeys.sarDen],
      segmentCount: int.tryParse(json?[FFProbeKeys.segmentCount] ?? ""),
      sourceOshash: json?[FFProbeKeys.sourceOshash],
      startMicros: json?[FFProbeKeys.startMicros],
      startPts: json?[FFProbeKeys.startPts],
      startTime: _formatDuration(json?[FFProbeKeys.startTime]),
      statisticsWritingApp: json?[FFProbeKeys.statisticsWritingApp],
      statisticsWritingDateUtc: json?[FFProbeKeys.statisticsWritingDateUtc],
      timeBase: json?[FFProbeKeys.timeBase],
      track: json?[FFProbeKeys.title],
      vendorId: json?[FFProbeKeys.vendorId],
      width: int.tryParse(json?[FFProbeKeys.width] ?? ""),
      xiaomiSlowMoment: json?[FFProbeKeys.xiaomiSlowMoment],
    );
  }

  static String _formatBrand(String value) => Mp4.brands[value] ?? value;

  static String _formatChannelLayout(dynamic value) {
    if (value is int) {
      return ChannelLayouts.names[value] ?? 'unknown ($value)';
    }
    return '$value';
  }

  static final Map<String, String> _codecNames = {
    Codecs.ac3: 'AC-3',
    Codecs.eac3: 'E-AC-3',
    Codecs.h264: 'AVC (H.264)',
    Codecs.hevc: 'HEVC (H.265)',
    Codecs.matroska: 'Matroska',
    Codecs.mpeg4: 'MPEG-4 Visual',
    Codecs.mpts: 'MPEG-TS',
    Codecs.opus: 'Opus',
    Codecs.pgs: 'PGS',
    Codecs.subrip: 'SubRip',
    Codecs.theora: 'Theora',
    Codecs.vorbis: 'Vorbis',
    Codecs.webm: 'WebM',
  };

  static String? _formatCodecName(String? value) =>
      value == null || value == "none"
          ? null
          : _codecNames[value] ?? value.toUpperCase().replaceAll('_', ' ');

  // input example: '2021-04-12T09:14:37.000000Z'
  static String? _formatDate(String value) {
    final date = DateTime.tryParse(value);
    if (date == null) return value;
    final epoch = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    if (date == epoch) return null;
    return date.toIso8601String();
  }

  // input example: '00:00:05.408000000' or '5.408000'
  static Duration? _parseDuration(String? value) {
    if (value == null) return null;

    var match = _durationHmsmPattern.firstMatch(value);
    if (match != null) {
      final h = int.tryParse(match.group(1)!);
      final m = int.tryParse(match.group(2)!);
      final s = int.tryParse(match.group(3)!);
      final millis = double.tryParse(match.group(4)!);
      if (h != null && m != null && s != null && millis != null) {
        return Duration(
          hours: h,
          minutes: m,
          seconds: s,
          milliseconds: (millis * 1000).toInt(),
        );
      }
    }

    match = _durationSmPattern.firstMatch(value);
    if (match != null) {
      final s = int.tryParse(match.group(1)!);
      final millis = double.tryParse(match.group(2)!);
      if (s != null && millis != null) {
        return Duration(
          seconds: s,
          milliseconds: (millis * 1000).toInt(),
        );
      }
    }

    return null;
  }

  // input example: '00:00:05.408000000' or '5.408000'
  static String? _formatDuration(String? value) {
    if (value == null) return null;
    final duration = _parseDuration(value);
    return duration != null ? formatPreciseDuration(duration) : value;
  }

  static String? _formatFilesize(dynamic value) {
    if (value == null) return null;
    final size = value is int ? value : int.tryParse(value);
    const String asciiLocale = 'en_US';
    return size != null ? formatFileSize(asciiLocale, size) : value;
  }

  static String _formatLanguage(String value) {
    final language = Language.living639_2
        .firstWhereOrNull((language) => language.iso639_2 == value);
    return language?.native ?? value;
  }

  static final _durationHmsmPattern = RegExp(r'(\d+):(\d+):(\d+)(.\d+)');
  static final _durationSmPattern = RegExp(r'(\d+)(.\d+)');
  static final _locationPattern = RegExp(r'([+-][.0-9]+)');

  // format ISO 6709 input, e.g. '+37.5090+127.0243/' (Samsung), '+51.3328-000.7053+113.474/' (Apple)
  static Location? _formatLocation(String? value) {
    if (value == null) return null;
    final matches = _locationPattern.allMatches(value);
    if (matches.isNotEmpty) {
      final coordinates =
          matches.map((m) => double.tryParse(m.group(0)!)).toList();
      if (coordinates.every((c) => c == 0)) return null;
      try {
        return Location(
          latitude: coordinates[0],
          longitude: coordinates[1],
        );
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  static String? _formatMetric(dynamic size, String unit, {int round = 2}) {
    if (size == null) return null;
    if (size is String) {
      final parsed = int.tryParse(size);
      if (parsed == null) return size;
      size = parsed;
    }

    const divider = 1000;
    if (size < divider) return '$size $unit';
    if (size < divider * divider) {
      return '${(size / divider).toStringAsFixed(round)} K$unit';
    }
    return '${(size / divider / divider).toStringAsFixed(round)} M$unit';
  }
}

String formatDay(DateTime date, String locale) =>
    DateFormat.yMMMd(locale).format(date);

String formatTime(DateTime date, String locale, bool use24hour) =>
    (use24hour ? DateFormat.Hm(locale) : DateFormat.jm(locale)).format(date);

String formatDateTime(DateTime date, String locale, bool use24hour) => [
      formatDay(date, locale),
      formatTime(date, locale, use24hour),
    ].join(" ");

String formatFriendlyDuration(Duration d) {
  final seconds = (d.inSeconds.remainder(Duration.secondsPerMinute))
      .toString()
      .padLeft(2, '0');
  if (d.inHours == 0) return '${d.inMinutes}:$seconds';

  final minutes = (d.inMinutes.remainder(Duration.minutesPerHour))
      .toString()
      .padLeft(2, '0');
  return '${d.inHours}:$minutes:$seconds';
}

String? formatPreciseDuration(Duration d) {
  if (d.inSeconds == 0) return null;
  final millis =
      ((d.inMicroseconds / 1000.0).round() % 1000).toString().padLeft(3, '0');
  final seconds = (d.inSeconds.remainder(Duration.secondsPerMinute))
      .toString()
      .padLeft(2, '0');
  final minutes = (d.inMinutes.remainder(Duration.minutesPerHour))
      .toString()
      .padLeft(2, '0');
  final hours = (d.inHours).toString().padLeft(2, '0');
  return '$hours:$minutes:$seconds.$millis';
}

const kilo = 1024;
const mega = kilo * kilo;
const giga = mega * kilo;
const tera = giga * kilo;

String formatFileSize(String locale, int size, {int round = 2}) {
  if (size < kilo) return '$size B';

  final compactFormatter =
      NumberFormat('0${round > 0 ? '.${'0' * round}' : ''}', locale);
  if (size < mega) return '${compactFormatter.format(size / kilo)} KB';
  if (size < giga) return '${compactFormatter.format(size / mega)} MB';
  if (size < tera) return '${compactFormatter.format(size / giga)} GB';
  return '${compactFormatter.format(size / tera)} TB';
}
