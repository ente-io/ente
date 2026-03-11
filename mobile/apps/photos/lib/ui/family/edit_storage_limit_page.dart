import 'dart:math' as math;

import 'package:ente_pure_utils/ente_pure_utils.dart';
import 'package:flutter/material.dart';
import 'package:photos/generated/l10n.dart';
import 'package:photos/models/user_details.dart';
import 'package:photos/services/family_service.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/components/buttons/button_widget_v2.dart';
import 'package:photos/ui/family/family_ui.dart';
import 'package:photos/utils/dialog_util.dart';

class EditStorageLimitPage extends StatefulWidget {
  const EditStorageLimitPage({
    required this.member,
    required this.totalStorageInBytes,
    required this.avatarColor,
    super.key,
  });

  final FamilyMember member;
  final int totalStorageInBytes;
  final Color avatarColor;

  @override
  State<EditStorageLimitPage> createState() => _EditStorageLimitPageState();
}

class _EditStorageLimitPageState extends State<EditStorageLimitPage> {
  static const _gigabyte = 1024 * 1024 * 1024;

  late double _sliderValue;

  double get _maxSliderValue =>
      math.max(1, (widget.totalStorageInBytes / _gigabyte).ceilToDouble());

  double get _minimumLimitedSliderValue =>
      (widget.member.usage / _gigabyte).ceilToDouble();

  int? get _selectedStorageLimit {
    if (_sliderValue <= 0) {
      return null;
    }
    return (_sliderValue * _gigabyte).round();
  }

  @override
  void initState() {
    super.initState();
    _sliderValue = widget.member.storageLimit == null
        ? 0
        : (widget.member.storageLimit! / _gigabyte).roundToDouble();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    return FamilyPageScaffold(
      title: l10n.storageLimit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: widget.avatarColor,
                        child: Text(
                          widget.member.email.substring(0, 1).toUpperCase(),
                          style: textTheme.bodyBold.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.member.email,
                              style: textTheme.body,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n.usingStorage(
                                amount: convertBytesToReadableFormat(
                                  widget.member.usage,
                                ),
                              ),
                              style: textTheme.smallMuted,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.storageLimitExplanation,
                    style: textTheme.bodyMuted.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colorScheme.fill,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n.limit,
                              style: textTheme.bodyBold,
                            ),
                            Text(
                              _selectedStorageLimit == null
                                  ? l10n.noLimit
                                  : convertBytesToReadableFormat(
                                      _selectedStorageLimit!,
                                    ),
                              style: textTheme.h3Bold.copyWith(
                                color: colorScheme.greenBase,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: colorScheme.greenBase,
                            inactiveTrackColor: colorScheme.fillMuted,
                            thumbColor: colorScheme.greenBase,
                            overlayColor:
                                colorScheme.greenBase.withValues(alpha: 0.14),
                          ),
                          child: Slider(
                            value: _sliderValue.clamp(0, _maxSliderValue),
                            min: 0,
                            max: _maxSliderValue,
                            divisions: _maxSliderValue <= 500
                                ? _maxSliderValue.toInt()
                                : 500,
                            onChanged: (value) {
                              final roundedValue = value.roundToDouble();
                              final effectiveValue = roundedValue > 0 &&
                                      roundedValue < _minimumLimitedSliderValue
                                  ? _minimumLimitedSliderValue
                                  : roundedValue;
                              setState(() {
                                _sliderValue = effectiveValue;
                              });
                            },
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n.noLimit,
                              style: textTheme.miniMuted,
                            ),
                            Text(
                              convertBytesToReadableFormat(
                                widget.totalStorageInBytes,
                              ),
                              style: textTheme.miniMuted,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      l10n.currentUsageNote(
                        amount:
                            convertBytesToReadableFormat(widget.member.usage),
                      ),
                      style: textTheme.smallFaint.copyWith(height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ButtonWidgetV2(
            buttonType: ButtonTypeV2.primary,
            labelText: l10n.save,
            onTap: _saveLimit,
          ),
        ],
      ),
    );
  }

  Future<void> _saveLimit() async {
    try {
      await FamilyService.instance.updateMemberStorageLimit(
        member: widget.member,
        storageLimit: _selectedStorageLimit,
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (!mounted) {
        throw const _HandledStorageLimitException();
      }
      await showGenericErrorDialog(context: context, error: error);
      throw const _HandledStorageLimitException();
    }
  }
}

class _HandledStorageLimitException implements Exception {
  const _HandledStorageLimitException();
}
