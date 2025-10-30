import 'package:logging/logging.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photos/core/errors.dart';

enum AssetDateTimeLabel {
  creation('createDateTime'),
  modification('modifiedDateTime');

  const AssetDateTimeLabel(this.fieldName);

  final String fieldName;
}

enum AssetTimePrecision { microseconds, milliseconds }

final _logger = Logger('AssetTimeUtil');

int safeAssetTime(
  AssetEntity asset, {
  required AssetDateTimeLabel label,
  required AssetTimePrecision precision,
}) {
  try {
    final DateTime dateTime = switch (label) {
      AssetDateTimeLabel.creation => asset.createDateTime,
      AssetDateTimeLabel.modification => asset.modifiedDateTime,
    };

    return switch (precision) {
      AssetTimePrecision.microseconds => dateTime.microsecondsSinceEpoch,
      AssetTimePrecision.milliseconds => dateTime.millisecondsSinceEpoch,
    };
  } on RangeError catch (e, stackTrace) {
    final error = InvalidDateTimeError(
      assetId: asset.id,
      assetTitle: asset.title,
      field: label.fieldName,
      originalError: e.message ?? e.toString(),
    );
    _logger.severe(
      'Invalid asset date encountered for ${error.field}',
      error,
      stackTrace,
    );
    throw error;
  }
}
