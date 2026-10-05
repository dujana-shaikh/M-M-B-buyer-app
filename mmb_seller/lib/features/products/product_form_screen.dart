import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mmb_core/mmb_core.dart';
import '../../data/providers.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  const ProductFormScreen({super.key, this.product});
  final Product? product; // null = add new
  @override
  ConsumerState<ProductFormScreen> createState() => _State();
}

class _State extends ConsumerState<ProductFormScreen> {
  static const _maxImages = 6;
  final _form = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _c;
  late String _category;
  late ProductCondition _condition;
  late StockStatus _stock;
  late List<String> _existing;
  final List<Uint8List> _newImages = [];
  bool _saving = false;

  bool get _editing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    final u = ref.read(currentUserProvider).valueOrNull;
    TextEditingController t(String? v) => TextEditingController(text: v ?? '');
    _c = {
      'name': t(p?.name),
      'brand': t(p?.brand),
      'model': t(p?.model),
      'storage': t(p?.storage),
      'ram': t(p?.ram),
      'color': t(p?.color),
      'qty': t(p?.quantityAvailable.toString()),
      'price': t(p?.bulkPrice.toStringAsFixed(p.bulkPrice % 1 == 0 ? 0 : 2)),
      'moq': t(p?.minOrderQty.toString()),
      'desc': t(p?.description),
      'shop': t(p?.shopName ?? u?.shopName),
      'city': t(p?.city ?? u?.city),
      'area': t(p?.area ?? u?.area),
      'contact': t(p?.contactNumber ?? u?.phone),
      'whatsapp': t(p?.whatsappNumber ?? u?.whatsapp ?? u?.phone),
    };
    _category =
        p?.category.isNotEmpty == true ? p!.category : defaultCategories.first;
    if (!defaultCategories.contains(_category)) {
      _category = defaultCategories.first;
    }
    _condition = p?.condition ?? ProductCondition.newItem;
    _stock = p?.stockStatus ?? StockStatus.inStock;
    _existing = List.of(p?.imageUrls ?? const []);
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _v(String k) => _c[k]!.text.trim();

  Future<void> _pickImages() async {
    final left = _maxImages - _existing.length - _newImages.length;
    if (left <= 0) {
      showSnack(context, 'You can add up to $_maxImages images', error: true);
      return;
    }
    final files =
        await ImagePicker().pickMultiImage(imageQuality: 80, maxWidth: 1280);
    for (final f in files.take(left)) {
      _newImages.add(await f.readAsBytes());
    }
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_existing.isEmpty && _newImages.isEmpty) {
      showSnack(context, 'Please add at least one product image', error: true);
      return;
    }
    final qty = int.parse(_v('qty'));
    final moq = int.parse(_v('moq'));
    if (moq > qty) {
      showSnack(context, 'Minimum order cannot be more than available quantity',
          error: true);
      return;
    }
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;

    setState(() => _saving = true);
    try {
      final repo = ref.read(productRepositoryProvider);
      final id = widget.product?.id ?? repo.newId();
      final uploaded = await repo.uploadImages(user.uid, id, _newImages);
      final p = Product(
        id: id,
        sellerId: user.uid, // privacy: always the logged-in seller
        name: _v('name'),
        brand: _v('brand'),
        model: _v('model'),
        category: _category,
        storage: _v('storage').isEmpty ? null : _v('storage'),
        ram: _v('ram').isEmpty ? null : _v('ram'),
        color: _v('color'),
        condition: _condition,
        quantityAvailable: qty,
        bulkPrice: double.parse(_v('price')),
        minOrderQty: moq,
        description: _v('desc'),
        imageUrls: [..._existing, ...uploaded],
        sellerName: user.name,
        shopName: _v('shop'),
        city: _v('city'),
        area: _v('area').isEmpty ? null : _v('area'),
        contactNumber: _v('contact'),
        whatsappNumber: _v('whatsapp'),
        stockStatus: _stock,
      );
      _editing ? await repo.update(p) : await repo.create(p);
      if (!mounted) return;
      showSnack(context,
          _editing ? 'Product updated' : 'Product submitted for review');
      Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        showSnack(context, 'Could not save product. Please try again.',
            error: true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _text(String key, String label,
          {String? Function(String?)? validator,
          TextInputType? type,
          int lines = 1}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: _c[key],
          keyboardType: type,
          maxLines: lines,
          decoration: InputDecoration(labelText: label),
          validator: validator,
        ),
      );

  Widget _section(String t) => Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 10),
        child: Text(t,
            style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: MmbColors.deepBlue)),
      );

  @override
  Widget build(BuildContext context) {
    req(String l) => (String? v) => Validators.required(v, l);
    return Scaffold(
      appBar: AppBar(title: Text(_editing ? 'Edit product' : 'Add product')),
      body: AbsorbPointer(
        absorbing: _saving,
        child: Form(
          key: _form,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            _section('Images (up to $_maxImages)'),
            SizedBox(
              height: 92,
              child: ListView(scrollDirection: Axis.horizontal, children: [
                InkWell(
                  onTap: _pickImages,
                  child: Container(
                    width: 88,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: MmbColors.deepBlue, width: 1.5),
                      borderRadius: BorderRadius.circular(14),
                      color: MmbColors.deepBlue.withValues(alpha: 0.06),
                    ),
                    child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined,
                              color: MmbColors.deepBlue),
                          SizedBox(height: 4),
                          Text('Add',
                              style: TextStyle(color: MmbColors.deepBlue)),
                        ]),
                  ),
                ),
                for (final url in _existing)
                  _Thumb(
                      child: MmbImage(url, radius: 14),
                      onRemove: () => setState(() => _existing.remove(url))),
                for (final bytes in _newImages)
                  _Thumb(
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.memory(bytes, fit: BoxFit.cover)),
                    onRemove: () => setState(() => _newImages.remove(bytes)),
                  ),
              ]),
            ),
            _section('Product details'),
            _text('name', 'Product name', validator: req('Product name')),
            _text('brand', 'Brand', validator: req('Brand')),
            _text('model', 'Model name / number', validator: req('Model')),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: defaultCategories
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _text('storage', 'Storage (e.g. 128GB)')),
              const SizedBox(width: 10),
              Expanded(child: _text('ram', 'RAM (e.g. 8GB)')),
            ]),
            _text('color', 'Color', validator: req('Color')),
            DropdownButtonFormField<ProductCondition>(
              initialValue: _condition,
              decoration: const InputDecoration(labelText: 'Condition'),
              items: ProductCondition.values
                  .map((e) => DropdownMenuItem(value: e, child: Text(e.label)))
                  .toList(),
              onChanged: (v) => setState(() => _condition = v!),
            ),
            const SizedBox(height: 12),
            _text('desc', 'Description',
                lines: 4, validator: req('Description')),
            _section('Price & quantity'),
            _text('price', 'Bulk price per unit (₹)',
                type: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => Validators.positiveNum(v, 'price')),
            Row(children: [
              Expanded(
                  child: _text('qty', 'Quantity available',
                      type: TextInputType.number,
                      validator: (v) =>
                          Validators.positiveInt(v, 'quantity', min: 0))),
              const SizedBox(width: 10),
              Expanded(
                  child: _text('moq', 'Minimum order qty',
                      type: TextInputType.number,
                      validator: (v) =>
                          Validators.positiveInt(v, 'minimum order'))),
            ]),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('In stock'),
              value: _stock == StockStatus.inStock,
              onChanged: (v) => setState(() =>
                  _stock = v ? StockStatus.inStock : StockStatus.outOfStock),
            ),
            _section('Seller details shown to buyers'),
            _text('shop', 'Shop name', validator: req('Shop name')),
            Row(children: [
              Expanded(child: _text('city', 'City', validator: req('City'))),
              const SizedBox(width: 10),
              Expanded(child: _text('area', 'Area')),
            ]),
            _text('contact', 'Contact number',
                type: TextInputType.phone, validator: Validators.phone),
            _text('whatsapp', 'WhatsApp number',
                type: TextInputType.phone,
                validator: (v) => Validators.phone(v, 'WhatsApp number')),
            const SizedBox(height: 8),
            if (!_editing)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                    'New products are reviewed by MMB before they appear to buyers.',
                    style:
                        TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white))
                  : Text(_editing ? 'Save changes' : 'Submit product'),
            ),
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.child, required this.onRemove});
  final Widget child;
  final VoidCallback onRemove;
  @override
  Widget build(BuildContext context) => Container(
        width: 88,
        margin: const EdgeInsets.only(right: 10),
        child: Stack(fit: StackFit.expand, children: [
          child,
          Positioned(
            top: 2,
            right: 2,
            child: GestureDetector(
              onTap: onRemove,
              child: const CircleAvatar(
                  radius: 11,
                  backgroundColor: Colors.black54,
                  child: Icon(Icons.close, size: 14, color: Colors.white)),
            ),
          ),
        ]),
      );
}
