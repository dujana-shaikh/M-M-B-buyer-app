import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mmb_core/mmb_core.dart';
import '../../data/providers.dart';

Color _statusColor(EnquiryStatus s) => switch (s) {
      EnquiryStatus.newEnquiry => MmbColors.orange,
      EnquiryStatus.contacted => MmbColors.deepBlue,
      EnquiryStatus.confirmed => MmbColors.success,
      EnquiryStatus.completed => MmbColors.success,
      EnquiryStatus.cancelled => MmbColors.danger,
    };

Color _orderStatusColor(String status) {
  final s = status.toLowerCase();
  if (s.contains('deliver') || s.contains('complete')) return MmbColors.success;
  if (s.contains('process') || s.contains('dispatch')) return MmbColors.deepBlue;
  if (s.contains('cancel')) return MmbColors.danger;
  return MmbColors.orange;
}

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders & Enquiries'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Orders'),
            Tab(text: 'Enquiries'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _OrdersTab(),
          _EnquiriesTab(),
        ],
      ),
    );
  }
}

class _OrdersTab extends ConsumerWidget {
  const _OrdersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(myOrdersProvider);

    return ordersAsync.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(message: 'Could not load orders: $e', onRetry: () => ref.invalidate(myOrdersProvider)),
      data: (orders) {
        if (orders.isEmpty) {
          return const EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No orders placed yet',
            message: 'Your placed orders will show here with real-time status.',
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(myOrdersProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: orders.length,
            itemBuilder: (_, i) {
              final o = orders[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text(o.id, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      StatusChip(o.orderStatus, _orderStatusColor(o.orderStatus)),
                    ]),
                    const SizedBox(height: 4),
                    Text(formatDate(o.createdAt), style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    const SizedBox(height: 8),
                    for (final it in o.items)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(children: [
                          Expanded(child: Text(it.name, maxLines: 1, overflow: TextOverflow.ellipsis)),
                          Text('${it.quantity} × ${formatINR(it.price)}', style: const TextStyle(fontSize: 12)),
                        ]),
                      ),
                    const Divider(height: 20),
                    Row(children: [
                      Text('Total ${formatINR(o.totalAmount)}', style: const TextStyle(fontWeight: FontWeight.w900, color: MmbColors.deepBlue)),
                      const Spacer(),
                      StatusChip(o.paymentMethod, MmbColors.deepBlue),
                    ]),
                  ]),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _EnquiriesTab extends ConsumerWidget {
  const _EnquiriesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(myEnquiriesProvider);
    final products = ref.watch(approvedProductsProvider).valueOrNull ?? const <Product>[];

    return AsyncBody<List<Enquiry>>(
      value: data,
      onRetry: () => ref.invalidate(myEnquiriesProvider),
      data: (list) {
        if (list.isEmpty) {
          return const EmptyState(
            icon: Icons.chat_outlined,
            title: 'No enquiries yet',
            message: 'Your sent enquiries and their status will show here in real-time.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: list.length,
          itemBuilder: (_, i) {
            final e = list[i];
            final sample = e.items.isNotEmpty ? products.where((p) => p.id == e.items.first.productId).firstOrNull : null;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(formatDate(e.createdAt), style: TextStyle(color: Colors.grey.shade600)),
                    const Spacer(),
                    StatusChip(e.status.label, _statusColor(e.status)),
                  ]),
                  const SizedBox(height: 8),
                  for (final it in e.items)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(children: [
                        if (it.imageUrl.isNotEmpty) ...[
                          SizedBox(width: 40, height: 40, child: MmbImage(it.imageUrl, radius: 8)),
                          const SizedBox(width: 10),
                        ],
                        Expanded(child: Text(it.name, maxLines: 1, overflow: TextOverflow.ellipsis)),
                        Text('${it.quantity} × ${formatINR(it.unitPrice)}', style: const TextStyle(fontSize: 12)),
                      ]),
                    ),
                  if (e.note != null && e.note!.isNotEmpty)
                    Padding(padding: const EdgeInsets.only(top: 6), child: Text('Message: ${e.note}', style: TextStyle(color: Colors.grey.shade700))),
                  const Divider(height: 20),
                  Row(children: [
                    Text('Total ${formatINR(e.totalAmount)}', style: const TextStyle(fontWeight: FontWeight.w900, color: MmbColors.deepBlue)),
                    const Spacer(),
                    if (sample != null) ...[
                      IconButton.outlined(onPressed: () => Contact.call(sample.contactNumber), icon: const Icon(Icons.call, size: 18)),
                      const SizedBox(width: 6),
                      IconButton.outlined(
                        style: IconButton.styleFrom(foregroundColor: MmbColors.success),
                        onPressed: () => Contact.whatsapp(sample.whatsappNumber, message: 'Hello, I sent an enquiry on MMB for ${e.items.first.name}.'),
                        icon: const Icon(Icons.chat, size: 18),
                      ),
                    ],
                  ]),
                ]),
              ),
            );
          },
        );
      },
    );
  }
}
