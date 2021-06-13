import 'dart:convert';

import '../type.dart';

/// Filter option for get asset.
///
/// 筛选选项, 可以分别设置图片类型和视频类型对应的 [FilterOption]
///
/// See [FilterOption]
class FilterOptionGroup {
  static final _defaultOrderOption = OrderOption(
    type: OrderOptionType.updateDate,
    asc: false,
  );

  FilterOptionGroup({
    FilterOption imageOption = const FilterOption(),
    FilterOption videoOption = const FilterOption(),
    FilterOption audioOption = const FilterOption(),
    bool containsEmptyAlbum = false,
    bool containsPathModified = false,
    DateTimeCond? createTimeCond,
    DateTimeCond? updateTimeCond,
    List<OrderOption> orders = const [],
  }) {
    _map[AssetType.image] = imageOption;
    _map[AssetType.video] = videoOption;
    _map[AssetType.audio] = audioOption;
    this.containsEmptyAlbum = containsEmptyAlbum;
    this.containsPathModified = containsPathModified;
    this.createTimeCond = createTimeCond ?? DateTimeCond.def();
    this.updateTimeCond = createTimeCond ??
        DateTimeCond.def().copyWith(
          ignore: true,
        );
    this.orders.addAll(orders);
  }

  FilterOptionGroup.empty();

  final Map<AssetType, FilterOption> _map = {};

  /// 是否包含空相册
  ///
  /// Whether to include an empty album
  bool containsEmptyAlbum = false;

  /// If true, the [AssetPathEntity] will return with the last modified time.
  ///
  /// See [AssetPathEntity.lastModified]
  ///
  /// This is a performance consuming option. Only if you really need it, it is recommended to set it to true.
  bool containsPathModified = false;

  @Deprecated('Please use createTimeCond.')
  DateTimeCond get dateTimeCond => createTimeCond;

  @Deprecated('Please use createTimeCond.')
  set dateTimeCond(DateTimeCond dateTimeCond) {
    createTimeCond = dateTimeCond;
  }

  DateTimeCond createTimeCond = DateTimeCond.def();
  DateTimeCond updateTimeCond = DateTimeCond.def().copyWith(
    ignore: true,
  );

  FilterOption getOption(AssetType type) => _map[type]!;

  void setOption(AssetType type, FilterOption option) {
    _map[type] = option;
  }

  final orders = <OrderOption>[];

  void addOrderOption(OrderOption option) {
    orders.add(option);
  }

  void merge(FilterOptionGroup other) {
    for (final AssetType type in _map.keys) {
      _map[type] = _map[type]!.merge(other.getOption(type));
    }
    this.containsEmptyAlbum = other.containsEmptyAlbum;
    this.containsPathModified = other.containsPathModified;
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> result = {};
    if (_map.containsKey(AssetType.image)) {
      result["image"] = getOption(AssetType.image).toMap();
    }
    if (_map.containsKey(AssetType.video)) {
      result["video"] = getOption(AssetType.video).toMap();
    }
    if (_map.containsKey(AssetType.audio)) {
      result["audio"] = getOption(AssetType.audio).toMap();
    }

    result["createDate"] = createTimeCond.toMap();
    result["updateDate"] = updateTimeCond.toMap();
    result['containsEmptyAlbum'] = containsEmptyAlbum;
    result['containsPathModified'] = containsPathModified;

    final ordersList = List<OrderOption>.of(orders);
    if (ordersList.isEmpty) {
      ordersList.add(_defaultOrderOption);
    }

    result['orders'] = ordersList.map((e) => e.toMap()).toList();

    return result;
  }

  FilterOptionGroup copyWith({
    FilterOption? imageOption,
    FilterOption? videoOption,
    FilterOption? audioOption,
    DateTimeCond? createTimeCond,
    DateTimeCond? updateTimeCond,
    bool? containsEmptyAlbum,
    bool? containsPathModified,
    List<OrderOption>? orders,
  }) {
    imageOption ??= _map[AssetType.image];
    videoOption ??= _map[AssetType.video];
    audioOption ??= _map[AssetType.audio];

    createTimeCond ??= this.createTimeCond;
    updateTimeCond ??= this.updateTimeCond;

    containsEmptyAlbum ??= this.containsEmptyAlbum;
    containsPathModified ??= this.containsPathModified;

    orders ??= this.orders;

    final result = FilterOptionGroup();

    result.setOption(AssetType.image, imageOption!);
    result.setOption(AssetType.video, videoOption!);
    result.setOption(AssetType.audio, audioOption!);

    result.createTimeCond = createTimeCond;
    result.updateTimeCond = updateTimeCond;

    result.containsEmptyAlbum = containsEmptyAlbum;
    result.containsPathModified = containsPathModified;

    result.orders.addAll(orders);

    return result;
  }

  @override
  String toString() {
    return const JsonEncoder.withIndent('  ').convert(toMap());
  }
}

/// Filter option
///
/// 筛选选项的详细情况
class FilterOption {
  /// See [needTitle], [sizeConstraint] and [durationConstraint]
  const FilterOption({
    this.needTitle = false,
    this.sizeConstraint = const SizeConstraint(),
    this.durationConstraint = const DurationConstraint(),
  });

  /// This property affects performance on iOS. If not needed, please pass false, default is false.
  final bool needTitle;

  /// See [SizeConstraint]
  final SizeConstraint sizeConstraint;

  /// See [DurationConstraint], ignore in [AssetType.image].
  final DurationConstraint durationConstraint;

  /// Create a new [FilterOption] with specific properties merging.
  FilterOption copyWith({
    bool? needTitle,
    SizeConstraint? sizeConstraint,
    DurationConstraint? durationConstraint,
  }) {
    return FilterOption(
      needTitle: needTitle ?? this.needTitle,
      sizeConstraint: sizeConstraint ?? this.sizeConstraint,
      durationConstraint: durationConstraint ?? this.durationConstraint,
    );
  }

  /// Merge a [FilterOption] into another.
  FilterOption merge(FilterOption other) {
    return FilterOption(
      needTitle: other.needTitle,
      sizeConstraint: other.sizeConstraint,
      durationConstraint: other.durationConstraint,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "title": needTitle,
      "size": sizeConstraint.toMap(),
      "duration": durationConstraint.toMap(),
    };
  }

  @override
  String toString() {
    return const JsonEncoder.withIndent('  ').convert(toMap());
  }
}

/// Constraints of asset pixel width and height.
class SizeConstraint {
  final int minWidth;
  final int maxWidth;
  final int minHeight;
  final int maxHeight;

  /// When set to true, all constraints are ignored and all sizes of images are displayed.
  final bool ignoreSize;

  const SizeConstraint({
    this.minWidth = 0,
    this.maxWidth = 100000,
    this.minHeight = 0,
    this.maxHeight = 100000,
    this.ignoreSize = false,
  });

  SizeConstraint copyWith({
    int? minWidth,
    int? maxWidth,
    int? minHeight,
    int? maxHeight,
    bool? ignoreSize,
  }) {
    minWidth ??= this.minWidth;
    maxWidth ??= this.maxHeight;

    minHeight ??= this.minHeight;
    maxHeight ??= this.maxHeight;

    ignoreSize ??= this.ignoreSize;

    return SizeConstraint(
      minWidth: minWidth,
      maxWidth: maxWidth,
      minHeight: minHeight,
      maxHeight: maxHeight,
      ignoreSize: ignoreSize,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "minWidth": minWidth,
      "maxWidth": maxWidth,
      "minHeight": minHeight,
      "maxHeight": maxHeight,
      "ignoreSize": ignoreSize,
    };
  }
}

/// Constraints of duration.
///
/// The Image type ignores this constraints.
class DurationConstraint {
  final Duration min;
  final Duration max;

  const DurationConstraint({
    this.min = Duration.zero,
    this.max = const Duration(days: 1),
  });

  Map<String, dynamic> toMap() {
    return {
      "min": min.inMilliseconds,
      "max": max.inMilliseconds,
    };
  }
}

/// CreateDate
class DateTimeCond {
  static final DateTime zero = DateTime.fromMillisecondsSinceEpoch(0);

  final DateTime min;
  final DateTime max;
  final bool ignore;

  const DateTimeCond({
    required this.min,
    required this.max,
    this.ignore = false,
  });

  factory DateTimeCond.def() {
    return DateTimeCond(
      min: zero,
      max: DateTime.now(),
    );
  }

  DateTimeCond copyWith({
    DateTime? min,
    DateTime? max,
    bool? ignore,
  }) {
    return DateTimeCond(
      min: min ?? this.min,
      max: max ?? this.max,
      ignore: ignore ?? this.ignore,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'min': min.millisecondsSinceEpoch,
      'max': max.millisecondsSinceEpoch,
      'ignore': ignore,
    };
  }
}

class OrderOption {
  final OrderOptionType type;
  final bool asc;

  const OrderOption({
    this.type = OrderOptionType.createDate,
    this.asc = false,
  });

  OrderOption copyWith({
    OrderOptionType? type,
    bool? asc,
  }) {
    return OrderOption(
      asc: asc ?? this.asc,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.index,
      'asc': asc,
    };
  }
}

enum OrderOptionType { createDate, updateDate }
