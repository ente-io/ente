import 'package:email_validator/email_validator.dart';

bool isValidEmail(String email) {
  return EmailValidator.validate(email);
}
