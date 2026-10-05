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
  final _c = {for (final k in ['name', 'shop', 'phone', 'city']) k: TextEditingController()};
  bool _loaded = false;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save(AppUser u) async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(authRepositoryProvider).updateProfile(u.uid, {
        'name': _c['name']!.text.trim(),
        'shopName': _c['shop']!.text.trim(),
        'phone': _c['phone']!.text.trim(),
        'whatsapp': _c['phone']!.text.trim(),
        'city': _c['city']!.text.trim(),
      });
      if (mounted) showSnack(context, 'Profile saved');
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
    if (!_loaded) {
      _loaded = true;
      _c['name']!.text = user.name;
      _c['shop']!.text = user.shopName ?? '';
      _c['phone']!.text = user.phone;
      _c['city']!.text = user.city ?? '';
    }
    Widget f(String k, String label, {String? Function(String?)? v, TextInputType? t}) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextFormField(controller: _c[k], keyboardType: t, decoration: InputDecoration(labelText: label), validator: v),
        );
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: MmbColors.orange, child: Icon(Icons.person, color: Colors.white)),
            title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text(user.email ?? ''),
          ),
        ),
        const SizedBox(height: 16),
        Form(
          key: _form,
          child: Column(children: [
            f('name', 'Your name', v: (x) => Validators.required(x, 'Name')),
            f('shop', 'Shop name'),
            f('phone', 'Mobile number', t: TextInputType.phone, v: Validators.phone),
            f('city', 'City', v: (x) => Validators.required(x, 'City')),
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
