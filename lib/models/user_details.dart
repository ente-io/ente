import 'package:photos/models/subscription.dart';

class UserDetails {
  final String email;
  final int usage;
  final int fileCount;
  final int sharedCollectionsCount;
  final Subscription subscription;
  final FamilyData familyData;

  UserDetails(
    this.email,
    this.usage,
    this.fileCount,
    this.sharedCollectionsCount,
    this.subscription,
    this.familyData,
  );

  factory UserDetails.fromMap(Map<String, dynamic> map) {
    return UserDetails(
      map['email'] as String,
      map['usage'] as int,
      map['fileCount'] as int,
      map['sharedCollectionsCount'] as int,
      Subscription.fromMap(map['subscription']),
      FamilyData.fromMap(map['familyData']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'usage': usage,
      'fileCount': fileCount,
      'sharedCollectionsCount': sharedCollectionsCount,
      'subscription': subscription,
      'familyData': familyData
    };
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

  Map<String, dynamic> toMap() {
    return {'email': email, 'usage': usage, 'id': id, 'isAdmin': isAdmin};
  }
}

class FamilyData {
  final List<FamilyMember> members;

  // Storage available based on the family plan
  final int storage;
  final int expiry;

  FamilyData(this.members, this.storage, this.expiry);

  factory FamilyData.fromMap(Map<String, dynamic> map) {
    if (map == null) {
      return null;
    }
    assert(map['members'] != null && map['members'].length >= 0);
    final members = List<FamilyMember>.from(
        map['members'].map((x) => FamilyMember.fromMap(x)));
    return FamilyData(
      members,
      map['storage'] as int,
      map['expiry'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'members': members.map((x) => x?.toMap())?.toList(),
      'storage': storage,
      'expiry': expiry
    };
  }
}
