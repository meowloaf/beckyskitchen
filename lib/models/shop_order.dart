import 'package:cloud_firestore/cloud_firestore.dart';

class OrderStatus {
  static const pending = 'pending';
  static const accepted = 'accepted';
  static const ready = 'ready';
  static const completed = 'completed';
  static const declined = 'declined';
}

class PaymentMethod {
  static const online = 'online';
  static const payAtStore = 'pay_at_store';
}

class PaymentStatus {
  static const unpaid = 'unpaid';
  static const pending = 'pending';
  static const paid = 'paid';
  static const expired = 'expired';
  static const refunded = 'refunded';
}

class OrderLine {
  const OrderLine({
    required this.name,
    required this.price,
    required this.quantity,
  });

  final String name;
  final double price;
  final int quantity;
}

class ShopOrder {
  const ShopOrder({
    required this.id,
    required this.userId,
    required this.customerName,
    required this.phone,
    required this.fulfillment,
    required this.address,
    required this.status,
    required this.total,
    required this.items,
    required this.createdAt,
    this.paymentMethod = PaymentMethod.payAtStore,
    this.paymentStatus = PaymentStatus.unpaid,
    this.xenditInvoiceId = '',
  });

  final String id;
  final String userId;
  final String customerName;
  final String phone;
  final String fulfillment; // 'pickup' or 'delivery'
  final String address;
  final String status;
  final double total;
  final List<OrderLine> items;
  final DateTime? createdAt;
  final String paymentMethod;
  final String paymentStatus;
  final String xenditInvoiceId;

  bool get isDelivery => fulfillment == 'delivery';

  String get paymentStatusLabel {
    switch (paymentStatus) {
      case PaymentStatus.paid:
        return 'Paid';
      case PaymentStatus.pending:
        return 'Payment pending';
      case PaymentStatus.expired:
        return 'Payment expired';
      case PaymentStatus.refunded:
        return 'Refunded';
      default:
        return 'Unpaid';
    }
  }

  String get shortId =>
      id.length <= 6 ? id.toUpperCase() : id.substring(0, 6).toUpperCase();

  String get statusLabel {
    switch (status) {
      case OrderStatus.accepted:
        return 'Accepted';
      case OrderStatus.ready:
        return isDelivery ? 'Ready for delivery' : 'Ready for pickup';
      case OrderStatus.completed:
        return isDelivery ? 'Delivered' : 'Picked up';
      case OrderStatus.declined:
        return 'Declined';
      default:
        return 'Pending';
    }
  }

  String get createdLabel {
    final t = createdAt;
    if (t == null) return 'Just now';
    final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.hour >= 12 ? 'PM' : 'AM';
    return '${t.day}/${t.month}/${t.year}  $hour:$minute $period';
  }

  factory ShopOrder.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    final rawItems = d['items'] as List<dynamic>? ?? const [];
    return ShopOrder(
      id: doc.id,
      userId: d['userId'] as String? ?? '',
      customerName: d['customerName'] as String? ?? 'Customer',
      phone: d['phone'] as String? ?? '',
      fulfillment: d['fulfillment'] as String? ?? 'pickup',
      address: d['address'] as String? ?? '',
      status: d['status'] as String? ?? OrderStatus.pending,
      total: (d['total'] as num?)?.toDouble() ?? 0,
      items: rawItems.map((raw) {
        final m = raw as Map<String, dynamic>;
        return OrderLine(
          name: m['name'] as String? ?? '',
          price: (m['price'] as num?)?.toDouble() ?? 0,
          quantity: (m['quantity'] as num?)?.toInt() ?? 1,
        );
      }).toList(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      paymentMethod: d['paymentMethod'] as String? ?? PaymentMethod.payAtStore,
      paymentStatus: d['paymentStatus'] as String? ?? PaymentStatus.unpaid,
      xenditInvoiceId: d['xenditInvoiceId'] as String? ?? '',
    );
  }
}
