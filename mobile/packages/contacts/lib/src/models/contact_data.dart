import 'dart:convert';

class ContactData {
  final int contactUserId;
  final String email;
  final String name;
  final String? birthDate;

  const ContactData({
    required this.contactUserId,
    required this.email,
    required this.name,
    this.birthDate,
  });

  Map<String, dynamic> toJson() => {
    'contactUserId': contactUserId,
    'email': email,
    'name': name,
    if (birthDate != null) 'birthDate': birthDate,
  };

  factory ContactData.fromJson(Map<String, dynamic> json) {
    return ContactData(
      contactUserId: json['contactUserId'] as int,
      email: json['email'] as String,
      name: json['name'] as String,
      birthDate: json['birthDate'] as String?,
    );
  }

  String toEncodedJson() => jsonEncode(toJson());

  factory ContactData.fromEncodedJson(String jsonValue) =>
      ContactData.fromJson(jsonDecode(jsonValue) as Map<String, dynamic>);
}
