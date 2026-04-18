import 'package:ente_contacts/src/models/contact_data.dart';

class ContactRecord {
  final String id;
  final int contactUserId;
  final String? email;
  final ContactData? data;
  final String? profilePictureAttachmentId;
  final bool isDeleted;
  final int createdAt;
  final int updatedAt;

  const ContactRecord({
    required this.id,
    required this.contactUserId,
    required this.email,
    required this.data,
    required this.profilePictureAttachmentId,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
  });
}
