class VisitorValidators {
  const VisitorValidators._();

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _mobilePattern = RegExp(r'^\d{10}$');

  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter the visitor name.';
    }
    return null;
  }

  static String? mobile(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Enter a mobile number.';
    if (!_mobilePattern.hasMatch(text)) {
      return 'Enter a 10-digit mobile number.';
    }
    return null;
  }

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    if (!_emailPattern.hasMatch(text)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  static String? purpose(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter the purpose of the visit.';
    }
    return null;
  }

  static String? visitorType(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Select a visitor type.';
    }
    return null;
  }

  static String? project(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Select a project.';
    }
    return null;
  }
}

/// Payload stored in a visitor QR code: the server id and nothing else.
bool isVisitorId(String value) {
  return RegExp(r'^[A-Za-z0-9_-]{1,64}$').hasMatch(value);
}
