import 'dart:convert';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:ente_auth/models/subscription.dart';

class UserDetails {
  final String email;
  final int usage;
  final int fileCount;
  final int sharedCollectionsCount;
  final Subscription subscription;
  final FamilyData? familyData;
  final ProfileData? profileData;

  UserDetails(
    this.email,
    this.usage,
    this.fileCount,
    this.sharedCollectionsCount,
    this.subscription,
    this.familyData,
      this.profileData,
  );

  bool isPartOfFamily() {
    return familyData?.members?.isNotEmpty ?? false;
  }

  bool isFamilyAdmin() {
    assert(isPartOfFamily(), "verify user is part of family before calling");
    final FamilyMember currentUserMember = familyData!.members!
        .firstWhere((element) => element.email.trim() == email.trim());
    return currentUserMember.isAdmin;
  }

  // getFamilyOrPersonalUsage will return total usage for family if user
  // belong to family group. Otherwise, it will return storage consumed by
  // current user
  int getFamilyOrPersonalUsage() {
    return isPartOfFamily() ? familyData!.getTotalUsage() : usage;
  }

  int getFreeStorage() {
    return max(
      isPartOfFamily()
          ? (familyData!.storage - familyData!.getTotalUsage())
          : (subscription.storage - (usage)),
      0,
    );
  }

  int getTotalStorage() {
    return isPartOfFamily() ? familyData!.storage : subscription.storage;
  }

  factory UserDetails.fromMap(Map<String, dynamic> map) {
    return UserDetails(
      map['email'] as String,
      map['usage'] as int,
      (map['fileCount'] ?? 0) as int,
      (map['sharedCollectionsCount'] ?? 0) as int,
      Subscription.fromMap(map['subscription']),
      FamilyData.fromMap(map['familyData']),
      ProfileData.fromJson(map['profileData']),
    );
  }

}

class FamilyMember {
  final String email;
  final int usage;
  final String id;
  final bool isAdmin;

  FamilyMember(this.email, this.usage, this.id, this.isAdmin);

  factory FamilyMember.fromMap(Map<String, dynamic> map) {
    return FamilyMember(
      (map['email'] ?? '') as String,
      map['usage'] as int,
      map['id'] as String,
      map['isAdmin'] as bool,
    );
  }
}
class ProfileData {
  bool canDisableEmailMFA;
  bool isEmailMFAEnabled;
  bool isTwoFactorEnabled;

  // Constructor with default values
  ProfileData({
    this.canDisableEmailMFA = false,
    this.isEmailMFAEnabled = false,
    this.isTwoFactorEnabled = false,
  });

  // Factory method to create ProfileData instance from JSON
  factory ProfileData.fromJson(Map<String, dynamic>? json) {
    if (json == null) null;

    return ProfileData(
      canDisableEmailMFA: json!['canDisableEmailMFA'] ?? false,
      isEmailMFAEnabled: json['isEmailMFAEnabled'] ?? false,
      isTwoFactorEnabled: json['isTwoFactorEnabled'] ?? false,
    );
  }

  // Method to convert ProfileData instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'canDisableEmailMFA': canDisableEmailMFA,
      'isEmailMFAEnabled': isEmailMFAEnabled,
      'isTwoFactorEnabled': isTwoFactorEnabled,
    };
  }
  String toJsonString() => json.encode(toJson());
}
class FamilyData {
  final List<FamilyMember>? members;

  // Storage available based on the family plan
  final int storage;
  final int expiryTime;

  FamilyData(this.members, this.storage, this.expiryTime);

  int getTotalUsage() {
    return members!.map((e) => e.usage).toList().sum;
  }

  static fromMap(Map<String, dynamic>? map) {
    if (map == null) return null;
    assert(map['members'] != null && map['members'].length >= 0);
    final members = List<FamilyMember>.from(
      map['members'].map((x) => FamilyMember.fromMap(x)),
    );
    return FamilyData(
      members,
      map['storage'] as int,
      map['expiryTime'] as int,
    );
  }
}
