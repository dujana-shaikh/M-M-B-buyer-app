import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mmb_core/mmb_core.dart';
import '../../data/providers.dart';

class EnquiriesScreen extends ConsumerWidget {
  const EnquiriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(receivedEnquiriesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Buyer Enquiries')),
      body: AsyncBody<List<Enquiry>>(
        value: data,
        onRetry: () => ref.invalidate(receivedEnquiriesProvider),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(icon: Icons.chat_bubble_outline, title: 'No enquiries yet', message: 'When buyers send an enquiry for your products, it will show here.');
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (_, i) => _EnquiryCard(e: list[i]),
          );
        },
      ),
    );
  }
}

class _EnquiryCard extends ConsumerWidget {
  const _EnquiryCard({required this.e});
  final Enquiry e;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(e.buyerName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
              Text(formatDate(e.createdAt), style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ]),
            const SizedBox(height: 8),
            for (final it in e.items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(children: [
                  Expanded(child: Text('${it.name}${it.variantLabel.isEmpty ? '' : ' (${it.variantLabel})'}')),
                  Text('${it.quantity} × ${formatINR(it.unitPrice)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                ]),
              ),
            const Divider(height: 20),
            Row(children: [
              const Text('Total ', style: TextStyle(fontWeight: FontWeight.w600)),
              Text(formatINR(e.totalAmount), style: const TextStyle(fontWeight: FontWeight.w900, color: MmbColors.deepBlue, fontSize: 16)),
            ]),
            if (e.note != null && e.note!.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text('Note: ${e.note}')),
            const SizedBox(height: 10),
            Row(children: [
              OutlinedButton.icon(onPressed: () => Contact.call(e.buyerPhone), icon: const Icon(Icons.call, size: 18), label: const Text('Call')),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: MmbColors.success),
                onPressed: () => Contact.whatsapp(e.buyerPhone, message: 'Hello ${e.buyerName}, thanks for your MMB enquiry.'),
                icon: const Icon(Icons.chat, size: 18),
                label: const Text('WhatsApp'),
              ),
              const Spacer(),
              DropdownButtonHideUnderline(
                child: DropdownButton<EnquiryStatus>(
                  value: e.status,
                  borderRadius: BorderRadius.circular(14),
                  items: EnquiryStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.label))).toList(),
                  onChanged: (s) async {
                    if (s == null) return;
                    try {
                      await ref.read(enquiryRepositoryProvider).setStatus(e.id, s);
                    } catch (_) {
                      if (context.mounted) showSnack(context, 'Could not update status', error: true);
                    }
                  },
                ),
              ),
            ]),
          ]),
        ),
      );
}
