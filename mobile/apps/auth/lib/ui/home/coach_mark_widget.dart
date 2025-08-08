import 'dart:ui';

import 'package:ente_auth/core/event_bus.dart';
import 'package:ente_auth/events/codes_updated_event.dart';
import 'package:ente_auth/l10n/l10n.dart';
import 'package:ente_auth/services/preference_service.dart';
import 'package:ente_auth/utils/platform_util.dart';
import 'package:flutter/material.dart';

class CoachMarkWidget extends StatelessWidget {
  const CoachMarkWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return GestureDetector(
      onTap: () async {
        await PreferenceService.instance.setHasShownCoachMark(true);
        Bus.instance.fire(CodesUpdatedEvent());
      },
      child: Row(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              color:
                  Theme.of(context).colorScheme.surface.withValues(alpha: 0.1),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 42,
                        ),
                        const SizedBox(
                          height: 24,
                        ),
                        Text(
                          PlatformUtil.isDesktop()
                              ? l10n.hintForDesktop
                              : l10n.hintForMobile,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(
                          height: 36,
                        ),
                        SizedBox(
                          width: 160,
                          child: OutlinedButton(
                            onPressed: () async {
                              await PreferenceService.instance
                                  .setHasShownCoachMark(true);
                              Bus.instance.fire(CodesUpdatedEvent());
                            },
                            child: Text(l10n.ok),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
