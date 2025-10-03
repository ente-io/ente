import 'package:ente_ui/theme/ente_theme.dart';
import 'package:flutter/material.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.l10n.saveInformation,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.informationDescription,
              style: getEnteTextTheme(context).body.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 32),
            _buildInformationOption(
              context,
              icon: Icons.notes,
              title: context.l10n.personalNote,
              description: context.l10n.personalNoteDescription,
              type: InformationType.note,
            ),
            const SizedBox(height: 16),
            _buildInformationOption(
              context,
              icon: Icons.folder_outlined,
              title: context.l10n.physicalRecords,
              description: context.l10n.physicalRecordsDescription,
              type: InformationType.physicalRecord,
            ),
            const SizedBox(height: 16),
            _buildInformationOption(
              context,
              icon: Icons.lock,
              title: context.l10n.accountCredentials,
              description: context.l10n.accountCredentialsDescription,
              type: InformationType.credentials,
            ),
            const SizedBox(height: 16),
            _buildInformationOption(
              context,
              icon: Icons.contact_phone,
              title: context.l10n.emergencyContact,
              description: context.l10n.emergencyContactDescription,
              type: InformationType.emergencyContact,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildInformationOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required InformationType type,
  }) {
    return GestureDetector(
      onTap: () {
        _showInformationForm(context, type);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: getEnteColorScheme(context).fillFaint,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: getEnteColorScheme(context).primary500,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: getEnteTextTheme(context).body.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: getEnteTextTheme(context).small.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
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
