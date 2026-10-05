import 'package:url_launcher/url_launcher.dart';

/// Phone dialer + WhatsApp helpers. Assumes India (+91) for 10-digit numbers.
class Contact {
  static String _digits(String number) {
    var d = number.replaceAll(RegExp(r'\D'), '');
    if (d.length == 10) d = '91$d';
    return d;
  }

  static Future<bool> call(String number) async {
    final uri = Uri(scheme: 'tel', path: number.trim());
    return launchUrl(uri);
  }

  static Future<bool> whatsapp(String number, {String? message}) async {
    final text = message == null ? '' : '?text=${Uri.encodeComponent(message)}';
    final uri = Uri.parse('https://wa.me/${_digits(number)}$text');
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
