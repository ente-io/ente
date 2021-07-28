import 'package:photos/models/subscription.dart';

class UserDetails {
  final String email;
  final int usage;
  final int fileCount;
  final int sharedCollectionsCount;
  final Subscription subscription;

  UserDetails(
    this.email,
    this.usage,
    this.fileCount,
    this.sharedCollectionsCount,
    this.subscription,
  );

  factory UserDetails.fromMap(Map<String, dynamic> map) {
    return UserDetails(
      map['email'] as String,
      map['usage'] as int,
      map['fileCount'] as int,
      map['sharedCollectionsCount'] as int,
      Subscription.fromMap(map['subscription']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'usage': usage,
      'fileCount': fileCount,
      'sharedCollectionsCount': sharedCollectionsCount,
      'subscription': subscription,
    };
  }
}
