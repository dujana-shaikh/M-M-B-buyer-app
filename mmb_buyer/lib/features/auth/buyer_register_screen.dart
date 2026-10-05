import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mmb_core/mmb_core.dart';

class BuyerRegisterScreen extends ConsumerStatefulWidget {
  const BuyerRegisterScreen({super.key});
  @override
  ConsumerState<BuyerRegisterScreen> createState() => _State();
}

class _State extends ConsumerState<BuyerRegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _shop = TextEditingController();
  final _phone = TextEditingController();
  final _city = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_name, _shop, _phone, _city, _email, _pass]) {
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
            whatsapp: _phone.text,
            shopName: _shop.text,
            city: _city.text,
            role: UserRole.buyer,
          );
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (mounted) showSnack(context, AuthRepository.message(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _f(TextEditingController c, String label, IconData icon, {String? Function(String?)? v, TextInputType? t, bool obscure = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextFormField(controller: c, keyboardType: t, obscureText: obscure, decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)), validator: v),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SingleChildScrollView(
          child: Column(children: [
            const AuthHeader(title: 'Create your account', subtitle: 'Start buying electronics in bulk'),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _form,
                child: Column(children: [
                  _f(_name, 'Your name', Icons.person_outline, v: (x) => Validators.required(x, 'Name')),
                  _f(_shop, 'Shop name (optional)', Icons.storefront_outlined),
                  _f(_phone, 'Mobile number', Icons.phone_outlined, t: TextInputType.phone, v: Validators.phone),
                  _f(_city, 'City', Icons.location_city_outlined, v: (x) => Validators.required(x, 'City')),
                  _f(_email, 'Email', Icons.email_outlined, t: TextInputType.emailAddress, v: Validators.email),
                  _f(_pass, 'Password', Icons.lock_outline, obscure: true, v: Validators.password),
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
