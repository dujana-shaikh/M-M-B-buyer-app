import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mmb_core/mmb_core.dart';
import '../../data/providers.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key, required this.items});
  final List<CartItem> items;
  @override
  ConsumerState<CheckoutScreen> createState() => _State();
}

class _State extends ConsumerState<CheckoutScreen> {
  final _address = TextEditingController();
  final _note = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final u = ref.read(currentUserProvider).valueOrNull;
    if (u != null) {
      _address.text = [u.area, u.city].where((e) => e != null && e.isNotEmpty).join(', ');
    }
  }

  @override
  void dispose() {
    _address.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    final buyer = ref.read(currentUserProvider).valueOrNull;
    if (buyer == null) return;

    if (_address.text.trim().isEmpty) {
      showSnack(context, 'Please enter delivery address', error: true);
      return;
    }

    setState(() => _busy = true);
    try {
      final total = widget.items.fold<double>(0, (t, e) => t + e.lineTotal);
      final orderItems = widget.items
          .map((e) => OrderItem(
                productId: e.productId,
                name: e.name,
                quantity: e.quantity,
                price: e.unitPrice,
              ))
          .toList();

      final order = await ref.read(orderRepositoryProvider).placeOrder(
            customerName: buyer.name,
            phone: buyer.phone,
            address: _address.text.trim(),
            items: orderItems,
            totalAmount: total,
            paymentMethod: 'COD',
            orderStatus: 'Processing',
          );

      // Clear cart
      await ref.read(cartRepositoryProvider).clear();

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: MmbColors.success, size: 56),
          title: const Text('Order Placed Successfully!'),
          content: Text('Order ID: ${order.id}\nAmount: ${formatINR(order.totalAmount)}\nPayment: Cash On Delivery'),
          actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('VIEW ORDERS'))],
        ),
      );

      if (!mounted) return;
      ref.invalidate(myOrdersProvider);
      ref.read(tabIndexProvider.notifier).state = 3;
      Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (mounted) showSnack(context, 'Could not place order: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendEnquiry() async {
    final buyer = ref.read(currentUserProvider).valueOrNull;
    if (buyer == null) return;

    setState(() => _busy = true);
    try {
      final count = await ref.read(enquiryRepositoryProvider).place(buyer: buyer, items: widget.items, note: _note.text);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: MmbColors.success, size: 56),
          title: const Text('Enquiry sent!'),
          content: Text('We sent $count enquiry${count == 1 ? '' : 'ies'} to the distributor${count == 1 ? '' : 's'}. They will contact you soon.'),
          actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('OK'))],
        ),
      );
      if (!mounted) return;
      ref.read(tabIndexProvider.notifier).state = 3;
      Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (_) {
      if (mounted) showSnack(context, 'Could not send enquiry. Please try again.', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final buyer = ref.watch(currentUserProvider).valueOrNull;
    final total = widget.items.fold<double>(0, (t, e) => t + e.lineTotal);
    final sellers = widget.items.map((e) => e.sellerId).toSet().length;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout & Confirm')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.person, color: MmbColors.deepBlue),
            title: Text(buyer?.name ?? ''),
            subtitle: Text('${buyer?.phone ?? ''}\n${buyer?.city ?? ''}'),
            isThreeLine: true,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Items', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              for (final it in widget.items)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(children: [
                    Expanded(child: Text(it.name, maxLines: 1, overflow: TextOverflow.ellipsis)),
                    Text('${it.quantity} × ${formatINR(it.unitPrice)}'),
                  ]),
                ),
              const Divider(height: 22),
              Row(children: [
                const Text('Estimated total', style: TextStyle(fontWeight: FontWeight.w700)),
                const Spacer(),
                Text(formatINR(total), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: MmbColors.deepBlue)),
              ]),
              if (sellers > 1)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('Your items are from $sellers distributors.', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _address,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Delivery address',
            prefixIcon: Icon(Icons.location_on_outlined),
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _note,
          maxLines: 2,
          decoration: const InputDecoration(labelText: 'Note for distributor (optional)', alignLabelWithHint: true),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          icon: const Icon(Icons.shopping_bag_outlined),
          label: _busy
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Place Order (COD)'),
          onPressed: _busy ? null : _placeOrder,
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          icon: const Icon(Icons.chat_outlined),
          label: const Text('Send Wholesale Enquiry Instead'),
          onPressed: _busy ? null : _sendEnquiry,
        ),
      ]),
    );
  }
}
