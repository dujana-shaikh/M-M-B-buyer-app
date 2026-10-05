import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mmb_core/mmb_core.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _State();
}

class _State extends ConsumerState<ProfileScreen> {
  final _form = GlobalKey<FormState>();
  final _c = {for (final k in ['name', 'shop', 'phone', 'whatsapp', 'city', 'area']) k: TextEditingController()};
  bool _loaded = false;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _fill(AppUser u) {
    if (_loaded) return;
    _loaded = true;
    _c['name']!.text = u.name;
    _c['shop']!.text = u.shopName ?? '';
    _c['phone']!.text = u.phone;
    _c['whatsapp']!.text = u.whatsapp ?? '';
    _c['city']!.text = u.city ?? '';
    _c['area']!.text = u.area ?? '';
  }

  Future<void> _save(AppUser u) async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(authRepositoryProvider).updateProfile(u.uid, {
        'name': _c['name']!.text.trim(),
        'shopName': _c['shop']!.text.trim(),
        'phone': _c['phone']!.text.trim(),
        'whatsapp': _c['whatsapp']!.text.trim(),
        'city': _c['city']!.text.trim(),
        'area': _c['area']!.text.trim(),
      });
      if (mounted) showSnack(context, 'Profile saved. New products will use these details.');
    } catch (e) {
      if (mounted) showSnack(context, AuthRepository.message(e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    if (user == null) return const Scaffold(body: LoadingView());
    _fill(user);
    Widget f(String k, String label, {String? Function(String?)? v, TextInputType? t}) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextFormField(controller: _c[k], keyboardType: t, decoration: InputDecoration(labelText: label), validator: v),
        );
    return Scaffold(
      appBar: AppBar(title: const Text('Distributor Profile')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: MmbColors.deepBlue, child: Icon(Icons.storefront, color: Colors.white)),
            title: Text(user.shopName ?? user.name, style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text(user.email ?? ''),
            trailing: const StatusChip('Approved', MmbColors.success),
          ),
        ),
        const SizedBox(height: 16),
        Form(
          key: _form,
          child: Column(children: [
            f('name', 'Your name', v: (x) => Validators.required(x, 'Name')),
            f('shop', 'Shop / company name', v: (x) => Validators.required(x, 'Shop name')),
            f('phone', 'Contact number', t: TextInputType.phone, v: Validators.phone),
            f('whatsapp', 'WhatsApp number', t: TextInputType.phone, v: (x) => Validators.phone(x, 'WhatsApp number')),
            f('city', 'City', v: (x) => Validators.required(x, 'City')),
            f('area', 'Area'),
            ElevatedButton(onPressed: _saving ? null : () => _save(user), child: Text(_saving ? 'Saving...' : 'Save profile')),
          ]),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(foregroundColor: MmbColors.danger, minimumSize: const Size.fromHeight(48)),
          onPressed: () => ref.read(authRepositoryProvider).signOut(),
          icon: const Icon(Icons.logout),
          label: const Text('Log out'),
        ),
      ]),
    );
  }
}
