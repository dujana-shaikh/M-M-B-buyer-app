class Validators {
  static String? required(String? v, [String label = 'This field']) =>
      (v == null || v.trim().isEmpty) ? '$label is required' : null;

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());
    return ok ? null : 'Enter a valid email';
  }

  static String? phone(String? v, [String label = 'Mobile number']) {
    final d = (v ?? '').replaceAll(RegExp(r'\D'), '');
    if (d.isEmpty) return '$label is required';
    return (d.length >= 10 && d.length <= 13) ? null : 'Enter a valid $label';
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    return v.length >= 6 ? null : 'Use at least 6 characters';
  }

  static String? positiveInt(String? v, String label, {int min = 1}) {
    final n = int.tryParse((v ?? '').trim());
    if (n == null) return 'Enter a valid $label';
    return n >= min ? null : '$label must be at least $min';
  }

  static String? positiveNum(String? v, String label) {
    final n = double.tryParse((v ?? '').trim());
    if (n == null || n <= 0) return 'Enter a valid $label';
    return null;
  }
}
