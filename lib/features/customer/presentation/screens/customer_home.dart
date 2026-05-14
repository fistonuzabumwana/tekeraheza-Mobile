import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomerHomeScreen extends StatelessWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Customer Portal',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.shopping_cart_outlined)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.person_outline)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back, Fiston!',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Order your LPG gas with ease.',
              style: GoogleFonts.outfit(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            _buildQuickOrderCard(context),
            const SizedBox(height: 30),
            Text(
              'Recent Orders',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 15),
            _buildOrderItem(context, 'ORD-1234', 'Delivered', '12 May 2026'),
            _buildOrderItem(context, 'ORD-5678', 'In Transit', '14 May 2026'),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickOrderCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.local_gas_station, color: Colors.white, size: 40),
          const SizedBox(height: 20),
          Text(
            'Quick Order',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Get your 12kg gas cylinder delivered in 30 minutes.',
            style: GoogleFonts.outfit(color: Colors.white70),
          ),
          const SizedBox(height: 25),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: const Text('Order Now'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(BuildContext context, String id, String status, String date) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: status == 'Delivered' ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              status == 'Delivered' ? Icons.check : Icons.local_shipping_outlined,
              color: status == 'Delivered' ? Colors.green : Colors.orange,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  id,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                ),
                Text(
                  date,
                  style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Text(
            status,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              color: status == 'Delivered' ? Colors.green : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }
}
