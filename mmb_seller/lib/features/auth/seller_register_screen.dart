import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mmb_core/mmb_core.dart';

class SellerRegisterScreen extends ConsumerStatefulWidget {
  const SellerRegisterScreen({super.key});
  @override
  ConsumerState<SellerRegisterScreen> createState() => _State();
}

class _State extends ConsumerState<SellerRegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _shop = TextEditingController();
  final _phone = TextEditingController();
  final _whatsapp = TextEditingController();
  final _city = TextEditingController();
  final _area = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_name, _shop, _phone, _whatsapp, _city, _area, _email, _pass]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).register(
            email: _email.text,
            password: _pass.text,
            name: _name.text,
            phone: _phone.text,
            whatsapp: _whatsapp.text.trim().isEmpty ? _phone.text : _whatsapp.text,
            shopName: _shop.text,
            city: _city.text,
            area: _area.text,
            role: UserRole.seller,
          );
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (mounted) showSnack(context, AuthRepository.message(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _field(TextEditingController c, String label, IconData icon,
      {String? Function(String?)? validator, TextInputType? type, bool obscure = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextFormField(
          controller: c,
          keyboardType: type,
          obscureText: obscure,
          decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
          validator: validator,
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SingleChildScrollView(
          child: Column(children: [
            const AuthHeader(title: 'Distributor Sign Up', subtitle: 'Your account is approved by MMB before you can sell'),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _form,
                child: Column(children: [
                  _field(_name, 'Your name', Icons.person_outline, validator: (v) => Validators.required(v, 'Name')),
                  _field(_shop, 'Shop / company name', Icons.storefront_outlined, validator: (v) => Validators.required(v, 'Shop name')),
                  _field(_phone, 'Contact number', Icons.phone_outlined, type: TextInputType.phone, validator: Validators.phone),
                  _field(_whatsapp, 'WhatsApp number (optional)', Icons.chat_outlined, type: TextInputType.phone,
                      validator: (v) => (v == null || v.trim().isEmpty) ? null : Validators.phone(v, 'WhatsApp number')),
                  _field(_city, 'City', Icons.location_city_outlined, validator: (v) => Validators.required(v, 'City')),
                  _field(_area, 'Area / market', Icons.place_outlined),
                  _field(_email, 'Email', Icons.email_outlined, type: TextInputType.emailAddress, validator: Validators.email),
                  _field(_pass, 'Password', Icons.lock_outline, obscure: true, validator: Validators.password),
                  const SizedBox(height: 6),
                  ElevatedButton(
                    onPressed: _busy ? null : _submit,
                    child: _busy ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)) : const Text('Create account'),
                  ),
                ]),
              ),
            ),
          ]),
        ),
      );
}
