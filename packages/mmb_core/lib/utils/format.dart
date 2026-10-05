/// Formats a number as Indian Rupees with Indian digit grouping (e.g. ₹1,25,000).
String formatINR(num value) {
  final s = value.round().abs().toString();
  final sign = value < 0 ? '-' : '';
  if (s.length <= 3) return '$sign₹$s';
  final last3 = s.substring(s.length - 3);
  var rest = s.substring(0, s.length - 3);
  final parts = <String>[];
  while (rest.length > 2) {
    parts.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) parts.insert(0, rest);
  return '$sign₹${parts.join(',')},$last3';
}

String formatDate(DateTime? d) {
  if (d == null) return '';
  const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${d.day} ${m[d.month - 1]} ${d.year}';
}
