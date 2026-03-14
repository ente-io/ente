import 'dart:async';
import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:ente_pure_utils/ente_pure_utils.dart';
import 'package:flutter/material.dart';
import 'package:photos/gateways/billing/models/billing_plan.dart';
import 'package:photos/gateways/billing/models/subscription.dart';
import 'package:photos/generated/l10n.dart';
import 'package:photos/models/button_result.dart';
import 'package:photos/models/user_details.dart';
import 'package:photos/service_locator.dart';
import 'package:photos/services/family_service.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/components/base_bottom_sheet.dart';
import 'package:photos/ui/components/buttons/button_widget.dart';
import 'package:photos/ui/components/buttons/button_widget_v2.dart';
import 'package:photos/ui/family/edit_storage_limit_page.dart';
import 'package:photos/ui/family/family_ui.dart';
import 'package:photos/ui/family/invite_members_page.dart';
import 'package:photos/ui/payment/subscription.dart';
import 'package:photos/utils/dialog_util.dart';

class FamilyPlanPage extends StatefulWidget {
  const FamilyPlanPage({
    required this.initialUserDetails,
    super.key,
  });

  final UserDetails initialUserDetails;

  @override
  State<FamilyPlanPage> createState() => _FamilyPlanPageState();
}

class _FamilyPlanPageState extends State<FamilyPlanPage> {
  late UserDetails _userDetails = widget.initialUserDetails;
  String? _startingPrice;
  bool _isRefreshing = false;

  bool get _isFreeUser =>
      _userDetails.subscription.productID == freeProductID &&
      !_userDetails.hasPaidAddon();

  bool get _showsDashboard => _userDetails.hasConfiguredFamily();

  bool get _isAdmin =>
      (_userDetails.currentFamilyMember()?.isAdmin ?? false) && _showsDashboard;

  int get _remainingSlots {
    final memberCount = _userDetails.familyData?.members
            ?.where(
              (member) => member.email.trim() != _userDetails.email.trim(),
            )
            .length ??
        0;
    return math.max(0, 5 - memberCount);
  }

  @override
  void initState() {
    super.initState();
    unawaited(_refreshUserDetails());
    if (_isFreeUser) {
      unawaited(_loadStartingPrice());
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _showsDashboard
        ? _buildDashboard(context)
        : _isFreeUser
            ? _buildFreeAdvert(context)
            : _buildPaidAdvert(context);

    return FamilyPageScaffold(
      title: _showsDashboard ? AppLocalizations.of(context).family : null,
      child: Stack(
        children: [
          Positioned.fill(child: content),
          if (_isRefreshing)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                minHeight: 2,
                color: getEnteColorScheme(context).greenBase,
                backgroundColor: Colors.transparent,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFreeAdvert(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 8),
                Image.asset(
                  "assets/ducky_share.png",
                  width: 200,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 16),
                _AdvertTitle(text: l10n.designedForFamilies),
                const SizedBox(height: 12),
                _AdvertBody(text: l10n.shareYourSubscription),
                const SizedBox(height: 20),
                _BenefitItem(
                  icon: Icons.group_outlined,
                  text: l10n.shareStorageWith5Members,
                ),
                _BenefitItem(
                  icon: Icons.lock_outline,
                  text: l10n.privateSpaceForEveryMember,
                ),
                _BenefitItem(
                  icon: Icons.forum_outlined,
                  text: l10n.feedToEngageWithFamily,
                ),
                if (_startingPrice != null) ...[
                  const SizedBox(height: 24),
                  Text(
                    l10n.plansStartAt(price: _startingPrice!),
                    style: getEnteTextTheme(context).smallFaint,
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ButtonWidgetV2(
          buttonType: ButtonTypeV2.primary,
          labelText: l10n.viewPlans,
          onTap: () async {
            unawaited(routeToPage(context, getSubscriptionPage()));
          },
        ),
      ],
    );
  }

  Widget _buildPaidAdvert(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 8),
                Image.asset(
                  "assets/ducky_share.png",
                  width: 200,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 16),
                _AdvertTitle(text: l10n.bringYourFamilyAlong),
                const SizedBox(height: 12),
                _AdvertBody(text: l10n.yourPlanSupportsFamily),
                const SizedBox(height: 20),
                _BenefitItem(
                  icon: Icons.group_add_outlined,
                  text: l10n.addUpTo5MembersFree,
                ),
                _BenefitItem(
                  icon: Icons.lock_outline,
                  text: l10n.privateSpaceForEveryMember,
                ),
                _BenefitItem(
                  icon: Icons.forum_outlined,
                  text: l10n.feedToEngageWithFamily,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ButtonWidgetV2(
          buttonType: ButtonTypeV2.primary,
          labelText: l10n.addFamilyMember,
          onTap: () async {
            unawaited(_openInvitePage());
          },
        ),
      ],
    );
  }

  Widget _buildDashboard(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final members = _sortedMembersForList();
    final activeMembers = members.where((member) => member.isActive).toList();
    final colorMap = _memberColorMap(activeMembers);

    return RefreshIndicator(
      onRefresh: () => _refreshUserDetails(showError: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _FamilyStorageOverviewCard(
            userDetails: _userDetails,
            members: activeMembers,
            colorMap: colorMap,
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 8),
            child: Text(
              l10n.members,
              style: getEnteTextTheme(context).smallMuted,
            ),
          ),
          _FamilyMembersCard(
            members: members,
            userDetails: _userDetails,
            colorMap: colorMap,
            isAdminView: _isAdmin,
            onMemberTap: _showMemberActions,
          ),
          const SizedBox(height: 24),
          if (_isAdmin && _remainingSlots > 0) ...[
            ButtonWidgetV2(
              buttonType: ButtonTypeV2.primary,
              labelText: l10n.addMember,
              leadingWidget: const Icon(
                Icons.person_add_outlined,
                color: Colors.white,
                size: 20,
              ),
              onTap: () async {
                unawaited(_openInvitePage());
              },
            ),
            const SizedBox(height: 12),
            ButtonWidgetV2(
              buttonType: ButtonTypeV2.tertiaryCritical,
              labelText: l10n.closeFamilyPlan,
              onTap: () async {
                unawaited(_confirmCloseFamily());
              },
            ),
          ],
          if (_isAdmin && _remainingSlots == 0)
            ButtonWidgetV2(
              buttonType: ButtonTypeV2.tertiaryCritical,
              labelText: l10n.closeFamilyPlan,
              onTap: () async {
                unawaited(_confirmCloseFamily());
              },
            ),
          if (!_isAdmin)
            ButtonWidgetV2(
              buttonType: ButtonTypeV2.tertiaryCritical,
              labelText: l10n.leaveFamilyPlan,
              onTap: () async {
                unawaited(_confirmLeaveFamily());
              },
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _loadStartingPrice() async {
    try {
      final billingPlans = await billingService.getBillingPlans();
      final cheapestPlan = billingPlans.plans
          .where((plan) => plan.id != freeProductID && plan.price.isNotEmpty)
          .map(_monthlyPriceForPlan)
          .whereType<_MonthlyPrice>()
          .sorted((a, b) => a.value.compareTo(b.value))
          .firstOrNull;
      if (mounted && cheapestPlan != null) {
        setState(() => _startingPrice = cheapestPlan.displayPrice);
      }
    } catch (_) {}
  }

  Future<void> _refreshUserDetails({bool showError = false}) async {
    if (_isRefreshing) {
      return;
    }
    setState(() => _isRefreshing = true);
    try {
      final details = await FamilyService.instance.refreshUserDetails();
      if (!mounted) {
        return;
      }
      setState(() => _userDetails = details);
    } catch (error) {
      if (mounted && showError) {
        await showGenericErrorDialog(context: context, error: error);
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  Future<void> _openInvitePage() async {
    final result = await routeToPage<InviteMembersPageResult>(
      context,
      InviteMembersPage(
        userDetails: _userDetails,
        remainingSlots: _remainingSlots,
      ),
    );
    await _refreshUserDetails();
    if (!mounted) {
      return;
    }
    if (result?.invitesSent ?? false) {
      showFamilySnackBar(context, AppLocalizations.of(context).invitesSent);
    }
  }

  Future<void> _showMemberActions(FamilyMember member) async {
    final isCurrentUser = member.email.trim() == _userDetails.email.trim();
    if (!_isAdmin || isCurrentUser) {
      return;
    }

    final l10n = AppLocalizations.of(context);
    final colorMap = _memberColorMap(_legendMembers());
    await showBaseBottomSheet<void>(
      context,
      title: member.email,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ActionGroup(
            children: member.isPending
                ? [
                    _ActionTile(
                      icon: Icons.send_outlined,
                      title: l10n.resendInvite,
                      onTap: () async {
                        Navigator.of(context).pop();
                        await _resendInvite(member);
                      },
                    ),
                    _ActionTile(
                      icon: Icons.link_off_outlined,
                      title: l10n.revokeInvite,
                      isDestructive: true,
                      onTap: () async {
                        Navigator.of(context).pop();
                        await _confirmRevokeInvite(member);
                      },
                    ),
                  ]
                : [
                    _ActionTile(
                      icon: Icons.tune,
                      title: l10n.editStorageLimit,
                      subtitle: member.storageLimit == null
                          ? l10n.noLimitSet
                          : convertBytesToReadableFormat(member.storageLimit!),
                      trailingChevron: true,
                      onTap: () async {
                        Navigator.of(context).pop();
                        await routeToPage(
                          context,
                          EditStorageLimitPage(
                            member: member,
                            totalStorageInBytes: _userDetails.getTotalStorage(),
                            avatarColor: colorMap[member.email] ??
                                getEnteColorScheme(context).greenBase,
                          ),
                        );
                        await _refreshUserDetails();
                      },
                    ),
                    _ActionTile(
                      icon: Icons.person_remove_outlined,
                      title: l10n.removeFromFamily,
                      isDestructive: true,
                      onTap: () async {
                        Navigator.of(context).pop();
                        await _confirmRemoveMember(member);
                      },
                    ),
                  ],
          ),
        ],
      ),
    );
  }

  Future<void> _resendInvite(FamilyMember member) async {
    try {
      await FamilyService.instance.resendInvite(member);
      await _refreshUserDetails();
      if (mounted) {
        showFamilySnackBar(context, AppLocalizations.of(context).inviteResent);
      }
    } catch (error) {
      if (mounted) {
        await showGenericErrorDialog(context: context, error: error);
      }
    }
  }

  Future<void> _confirmRemoveMember(FamilyMember member) async {
    final choice = await showChoiceDialog(
      context,
      title: AppLocalizations.of(context).removeMemberConfirmTitle,
      body: AppLocalizations.of(context).removeMemberConfirmBody(
        email: member.email,
      ),
      firstButtonLabel: AppLocalizations.of(context).remove,
      secondButtonLabel: AppLocalizations.of(context).cancel,
      isCritical: true,
      firstButtonOnTap: () async {
        await FamilyService.instance.removeMember(member);
      },
    );
    await _handleDialogResult(choice);
  }

  Future<void> _confirmRevokeInvite(FamilyMember member) async {
    final choice = await showChoiceDialog(
      context,
      title: AppLocalizations.of(context).revokeInviteConfirmTitle,
      body: AppLocalizations.of(context).revokeInviteConfirmBody(
        email: member.email,
      ),
      firstButtonLabel: AppLocalizations.of(context).revoke,
      secondButtonLabel: AppLocalizations.of(context).cancel,
      isCritical: true,
      firstButtonOnTap: () async {
        await FamilyService.instance.revokeInvite(member);
      },
    );
    await _handleDialogResult(choice);
  }

  Future<void> _confirmCloseFamily() async {
    final choice = await showChoiceDialog(
      context,
      title: AppLocalizations.of(context).closeFamilyConfirmTitle,
      body: AppLocalizations.of(context).closeFamilyConfirmBody,
      firstButtonLabel: AppLocalizations.of(context).closeFamilyPlan,
      secondButtonLabel: AppLocalizations.of(context).cancel,
      isCritical: true,
      firstButtonOnTap: () async {
        await FamilyService.instance.closeFamily(_userDetails);
      },
    );
    await _handleDialogResult(choice);
  }

  Future<void> _confirmLeaveFamily() async {
    final choice = await showChoiceDialog(
      context,
      title: AppLocalizations.of(context).leaveFamilyConfirmTitle,
      body: AppLocalizations.of(context).leaveFamilyConfirmBody,
      firstButtonLabel: AppLocalizations.of(context).leave,
      secondButtonLabel: AppLocalizations.of(context).cancel,
      isCritical: true,
      firstButtonOnTap: () async {
        await FamilyService.instance.leaveFamily();
      },
    );

    if (!mounted || choice == null) {
      return;
    }
    if (choice.action == ButtonAction.error) {
      await showGenericErrorDialog(context: context, error: choice.exception);
      return;
    }
    if (choice.action == ButtonAction.first) {
      await _refreshUserDetails();
      if (!mounted) {
        return;
      }
      replacePage(context, getSubscriptionPage());
    }
  }

  Future<void> _handleDialogResult(ButtonResult? choice) async {
    if (!mounted || choice == null) {
      return;
    }
    if (choice.action == ButtonAction.error) {
      await showGenericErrorDialog(context: context, error: choice.exception);
      return;
    }
    if (choice.action == ButtonAction.first) {
      await _refreshUserDetails();
    }
  }

  List<FamilyMember> _sortedMembersForList() {
    final Iterable<FamilyMember> sourceMembers = _isAdmin
        ? (_userDetails.familyData?.members ?? const <FamilyMember>[])
        : (_userDetails.familyData?.members ?? const <FamilyMember>[])
            .where((member) => member.isActive);
    final members = List<FamilyMember>.from(sourceMembers);
    final currentEmail = _userDetails.email.trim().toLowerCase();

    members.sort((a, b) {
      if (_isAdmin) {
        if (a.email.trim().toLowerCase() == currentEmail) return -1;
        if (b.email.trim().toLowerCase() == currentEmail) return 1;
        if (a.isPending != b.isPending) return a.isPending ? 1 : -1;
        return a.email.compareTo(b.email);
      }

      if (a.isAdmin != b.isAdmin) return a.isAdmin ? -1 : 1;
      if (a.email.trim().toLowerCase() == currentEmail) return -1;
      if (b.email.trim().toLowerCase() == currentEmail) return 1;
      if (a.isPending != b.isPending) return a.isPending ? 1 : -1;
      return a.email.compareTo(b.email);
    });
    return members;
  }

  List<FamilyMember> _legendMembers() {
    final currentEmail = _userDetails.email.trim().toLowerCase();
    final members = (_userDetails.familyData?.members ?? [])
        .where((member) => member.isActive)
        .toList();
    members.sort((a, b) {
      if (a.email.trim().toLowerCase() == currentEmail) return -1;
      if (b.email.trim().toLowerCase() == currentEmail) return 1;
      if (a.isAdmin != b.isAdmin) return a.isAdmin ? -1 : 1;
      return a.email.compareTo(b.email);
    });
    return members;
  }

  Map<String, Color> _memberColorMap(List<FamilyMember> members) {
    final colorScheme = getEnteColorScheme(context);
    final palette = <Color>[
      colorScheme.greenBase,
      ...colorScheme.avatarColors,
      colorScheme.primary500,
      colorScheme.golden500,
    ];
    return {
      for (final entry in members.indexed)
        entry.$2.email: palette[entry.$1 % palette.length],
    };
  }

  _MonthlyPrice? _monthlyPriceForPlan(BillingPlan plan) {
    if (plan.price.isEmpty) {
      return null;
    }
    if (plan.price.length < 2) {
      return _MonthlyPrice(plan.price, double.infinity);
    }

    final currencySymbol = plan.price[0];
    final rawPrice = plan.price.substring(1).replaceAll(",", "");
    final parsedPrice = double.tryParse(rawPrice);
    if (parsedPrice == null) {
      return null;
    }

    final monthlyValue = plan.period == "year" ? parsedPrice / 12 : parsedPrice;
    var displayValue = monthlyValue.toStringAsFixed(2);
    if (displayValue.endsWith(".00")) {
      displayValue = displayValue.substring(0, displayValue.length - 3);
    }
    return _MonthlyPrice("$currencySymbol$displayValue", monthlyValue);
  }
}

class _AdvertTitle extends StatelessWidget {
  const _AdvertTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: getEnteTextTheme(context).h3Bold,
      textAlign: TextAlign.center,
    );
  }
}

class _AdvertBody extends StatelessWidget {
  const _AdvertBody({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: getEnteTextTheme(context).bodyMuted.copyWith(height: 1.5),
      textAlign: TextAlign.center,
    );
  }
}

class _BenefitItem extends StatelessWidget {
  const _BenefitItem({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: colorScheme.greenBase),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: textTheme.body,
            ),
          ),
        ],
      ),
    );
  }
}

class _FamilyStorageOverviewCard extends StatelessWidget {
  const _FamilyStorageOverviewCard({
    required this.userDetails,
    required this.members,
    required this.colorMap,
  });

  final UserDetails userDetails;
  final List<FamilyMember> members;
  final Map<String, Color> colorMap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final l10n = AppLocalizations.of(context);
    final totalUsed =
        userDetails.familyData?.getTotalUsage() ?? userDetails.usage;
    final totalStorage = userDetails.getTotalStorage();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.fill,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                l10n.storage,
                style: textTheme.bodyBold,
              ),
              Text(
                l10n.storageUsedOfTotal(
                  used: convertBytesToReadableFormat(totalUsed),
                  total: convertBytesToReadableFormat(totalStorage),
                ),
                style: textTheme.smallMuted,
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 14,
            child: LayoutBuilder(
              builder: (context, constraints) {
                var currentLeft = 0.0;
                return Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.fillMuted,
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                    for (final member in members)
                      Builder(
                        builder: (context) {
                          final width = totalStorage == 0
                              ? 0.0
                              : constraints.maxWidth *
                                  (member.usage / totalStorage);
                          final segment = Positioned(
                            left: currentLeft,
                            child: Container(
                              width: width,
                              height: 14,
                              decoration: BoxDecoration(
                                color: colorMap[member.email],
                                borderRadius: BorderRadius.circular(7),
                              ),
                            ),
                          );
                          currentLeft += width;
                          return segment;
                        },
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FamilyMembersCard extends StatelessWidget {
  const _FamilyMembersCard({
    required this.members,
    required this.userDetails,
    required this.colorMap,
    required this.isAdminView,
    required this.onMemberTap,
  });

  final List<FamilyMember> members;
  final UserDetails userDetails;
  final Map<String, Color> colorMap;
  final bool isAdminView;
  final ValueChanged<FamilyMember> onMemberTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.fill,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          for (final entry in members.indexed) ...[
            _FamilyMemberRow(
              member: entry.$2,
              currentEmail: userDetails.email,
              avatarColor: colorMap[entry.$2.email],
              isAdminView: isAdminView,
              onTap: () => onMemberTap(entry.$2),
            ),
            if (entry.$1 != members.length - 1)
              Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: colorScheme.strokeSolid,
              ),
          ],
        ],
      ),
    );
  }
}

class _FamilyMemberRow extends StatelessWidget {
  const _FamilyMemberRow({
    required this.member,
    required this.currentEmail,
    required this.isAdminView,
    required this.onTap,
    this.avatarColor,
  });

  final FamilyMember member;
  final String currentEmail;
  final bool isAdminView;
  final VoidCallback onTap;
  final Color? avatarColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final l10n = AppLocalizations.of(context);
    final isCurrentUser =
        member.email.trim().toLowerCase() == currentEmail.trim().toLowerCase();
    final canTap = isAdminView && !isCurrentUser;
    final backgroundColor = member.isPending
        ? colorScheme.fillMuted
        : avatarColor ?? colorScheme.greenBase;
    final foregroundColor =
        member.isPending ? colorScheme.contentLight : Colors.white;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: canTap ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: backgroundColor,
              child: Text(
                member.email.substring(0, 1).toUpperCase(),
                style: textTheme.bodyBold.copyWith(color: foregroundColor),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.email,
                    style: member.isPending
                        ? textTheme.body.copyWith(color: colorScheme.textMuted)
                        : textTheme.body,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    member.isPending
                        ? l10n.pending
                        : l10n.memberStorageUsed(
                            amount: convertBytesToReadableFormat(member.usage),
                          ),
                    style: textTheme.smallMuted,
                  ),
                ],
              ),
            ),
            if (member.isAdmin) _BadgeChip(label: l10n.admin),
            if (!isAdminView && isCurrentUser) ...[
              if (member.isAdmin) const SizedBox(width: 8),
              _BadgeChip(
                label: l10n.you,
                isMuted: true,
              ),
            ],
            if (member.isPending) ...[
              if (member.isAdmin || (!isAdminView && isCurrentUser))
                const SizedBox(width: 8),
              _BadgeChip(label: l10n.pending, isMuted: true),
            ],
            if (canTap) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: colorScheme.contentLighter,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({
    required this.label,
    this.isMuted = false,
  });

  final String label;
  final bool isMuted;

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isMuted ? colorScheme.fillMuted : colorScheme.greenBase,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: textTheme.tinyBold.copyWith(
          color: isMuted ? colorScheme.textMuted : Colors.white,
        ),
      ),
    );
  }
}

class _ActionGroup extends StatelessWidget {
  const _ActionGroup({required this.children});

  final List<_ActionTile> children;

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.fill,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          for (final entry in children.indexed) ...[
            entry.$2,
            if (entry.$1 != children.length - 1)
              Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: colorScheme.strokeSolid,
              ),
          ],
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.isDestructive = false,
    this.trailingChevron = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isDestructive;
  final bool trailingChevron;

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final foregroundColor =
        isDestructive ? colorScheme.redBase : colorScheme.content;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: foregroundColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.body.copyWith(color: foregroundColor),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: textTheme.smallMuted,
                    ),
                  ],
                ],
              ),
            ),
            if (trailingChevron)
              Icon(
                Icons.chevron_right,
                size: 18,
                color: colorScheme.contentLighter,
              ),
          ],
        ),
      ),
    );
  }
}

class _MonthlyPrice {
  const _MonthlyPrice(this.displayPrice, this.value);

  final String displayPrice;
  final double value;
}
