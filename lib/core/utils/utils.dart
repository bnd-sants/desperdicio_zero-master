/// Extensions for DateTime
/// Format: yyyy-MM-dd HH:mm
/// Example: DateTime.now().formattedDate()
extension DateTimeExtension on DateTime {
  String formattedDate() {
    return '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')} ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}

/// Extensions for String
/// Example: 'hello'.capitalize() => 'Hello'
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}

/// Validates if a string is a valid email
bool isValidEmail(String email) {
  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  return emailRegex.hasMatch(email);
}

/// Validates if a string is a strong password
bool isStrongPassword(String password) {
  // Pelo menos 8 caracteres, 1 letra maiúscula, 1 minúscula, 1 número
  final hasMinLength = password.length >= 8;
  final hasUppercase = password.contains(RegExp(r'[A-Z]'));
  final hasLowercase = password.contains(RegExp(r'[a-z]'));
  final hasDigits = password.contains(RegExp(r'[0-9]'));
  final hasSpecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

  return hasMinLength && hasUppercase && hasLowercase && hasDigits && hasSpecial;
}

/// Debounce function to limit the rate at which a function can fire
Function debounce(Function fn, [int milliseconds = 500]) {
  int? timer;
  return () {
    if (timer != null) {
      timer = null;
    }
    timer = Future.delayed(Duration(milliseconds: milliseconds), () {
      fn();
    }).then((_) => timer = null) as int?;
  };
}
