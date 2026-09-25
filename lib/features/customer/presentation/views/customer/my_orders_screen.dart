import 'package:eventease/features/booking/data/models/order.dart';
import 'package:eventease/features/booking/data/providers/order_provider.dart';
import 'package:eventease/features/booking/data/providers/payment_provider.dart';
import 'package:flutter/material.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:eventease/shared/models/payment.dart';

class MyOrdersScreen extends StatefulWidget {
  final int initialIndex;

  const MyOrdersScreen({super.key, this.initialIndex = 0});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this, initialIndex: widget.initialIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('My Orders', style: TextStyle(color: AppTheme.textPrimaryColor)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimaryColor),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondaryColor,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: 'To Pay'),
            Tab(text: 'To Ship'),
            Tab(text: 'To Receive'),
            Tab(text: 'To Review'),
            Tab(text: 'Cancelled'),
            Tab(text: 'All'),
          ],
        ),
      ),
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, child) {
          final orders = orderProvider.customerOrders;

          return TabBarView(
            controller: _tabController,
            children: [
              _buildOrderList(orders.where((o) => o.paymentStatus == PaymentStatus.pending && o.status != OrderStatus.cancelled).toList()),
              _buildOrderList(orders.where((o) => (o.status == OrderStatus.ordered || o.status == OrderStatus.processing) && o.paymentStatus == PaymentStatus.completed).toList()),
              _buildOrderList(orders.where((o) => o.status == OrderStatus.shipped).toList()),
              _buildOrderList(orders.where((o) => o.status == OrderStatus.completed || o.status == OrderStatus.delivered).toList()),
              _buildOrderList(orders.where((o) => o.status == OrderStatus.cancelled || o.status == OrderStatus.refunded).toList()),
              _buildOrderList(orders),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOrderList(List<Order> orders) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text('No orders found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return _buildOrderItem(order);
      },
    );
  }

  Widget _buildOrderItem(Order order) {
    final firstItem = order.items.isNotEmpty ? order.items.first : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order #${order.id.substring(order.id.length - 8)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              _buildStatusBadge(order),
            ],
          ),
          const Divider(height: 24),
          if (firstItem != null)
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage(firstItem.imageUrl.isNotEmpty ? firstItem.imageUrl : 'https://via.placeholder.com/60'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        firstItem.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${firstItem.category} • x${firstItem.quantity}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${order.items.length} items',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              Text(
                'Total: RM ${order.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
               if (order.paymentStatus == PaymentStatus.pending && order.status != OrderStatus.cancelled)
                ElevatedButton(
                  onPressed: () {
                    // Navigate to payment
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(80, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Text('Pay Now'),
                ),
               const SizedBox(width: 8), 
               OutlinedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/order-confirmation', arguments: order);
                },
                style: OutlinedButton.styleFrom(
                   minimumSize: const Size(80, 36),
                   padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: const Text('Details'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(Order order) {
    String text;
    Color color;

    if (order.status == OrderStatus.cancelled) {
        text = 'Cancelled';
        color = Colors.red;
    } else if (order.paymentStatus == PaymentStatus.pending) {
        text = 'Payment Pending';
        color = Colors.orange;
    } else if (order.status == OrderStatus.completed) {
        text = 'Completed';
        color = Colors.green;
    } else if (order.status == OrderStatus.shipped) {
        text = 'Shipped';
        color = Colors.blue;
    } else if (order.status == OrderStatus.delivered) {
        text = 'Delivered';
        color = Colors.teal;
    } else {
        text = 'Processing';
        color = AppTheme.primaryColor;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
