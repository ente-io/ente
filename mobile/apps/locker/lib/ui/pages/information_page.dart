import "package:ente_ui/components/title_bar_title_widget.dart";
import "package:ente_ui/theme/colors.dart";
import 'package:ente_ui/theme/ente_theme.dart';
import "package:ente_ui/theme/text_style.dart";
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:locker/l10n/l10n.dart';
import 'package:locker/ui/pages/account_credentials_page.dart';
import 'package:locker/ui/pages/emergency_contact_page.dart';
import 'package:locker/ui/pages/personal_note_page.dart';
import 'package:locker/ui/pages/physical_records_page.dart';

enum InformationType {
  note,
  physicalRecord,
  credentials,
  emergencyContact,
}

class InformationPage extends StatelessWidget {
  const InformationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.backgroundBase,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 48,
        leadingWidth: 48,
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: const Icon(
            Icons.arrow_back_outlined,
          ),
        ),
      ),
      backgroundColor: colorScheme.backgroundBase,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
            child: TitleBarTitleWidget(
              title: "Save Information",
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              children: [
                _buildInformationOption(
                  context,
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedPencilEdit02,
                    size: 24,
                    color: colorScheme.primary700,
                  ),
                  title: context.l10n.personalNote,
                  description: context.l10n.personalNoteDescription,
                  type: InformationType.note,
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                ),
                const SizedBox(height: 16),
                _buildInformationOption(
                  context,
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedFolder02,
                    size: 24,
                    color: colorScheme.primary700,
                  ),
                  title: context.l10n.physicalRecords,
                  description: context.l10n.physicalRecordsDescription,
                  type: InformationType.physicalRecord,
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                ),
                const SizedBox(height: 16),
                _buildInformationOption(
                  context,
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedUserEdit01,
                    size: 24,
                    color: colorScheme.primary700,
                  ),
                  title: context.l10n.accountCredentials,
                  description: context.l10n.accountCredentialsDescription,
                  type: InformationType.credentials,
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                ),
                const SizedBox(height: 16),
                _buildInformationOption(
                  context,
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedContactBook,
                    size: 24,
                    color: colorScheme.primary700,
                  ),
                  title: context.l10n.emergencyContact,
                  description: context.l10n.emergencyContactDescription,
                  type: InformationType.emergencyContact,
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInformationOption(
    BuildContext context, {
    required HugeIcon icon,
    required String title,
    required String description,
    required InformationType type,
    required EnteColorScheme colorScheme,
    required EnteTextTheme textTheme,
  }) {
    return GestureDetector(
      onTap: () {
        _showInformationForm(context, type);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: colorScheme.backdropBase,
        ),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.bodyBold,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: textTheme.smallMuted,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: colorScheme.textBase,
            ),
          ],
        ),
      ),
    );
  }

  void _showInformationForm(BuildContext context, InformationType type) {
    Widget page;
    switch (type) {
      case InformationType.note:
        page = const PersonalNotePage();
        break;
      case InformationType.physicalRecord:
        page = const PhysicalRecordsPage();
        break;
      case InformationType.credentials:
        page = const AccountCredentialsPage();
        break;
      case InformationType.emergencyContact:
        page = const EmergencyContactPage();
        break;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => page),
    );
  }
}
