import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SparePartsScreen extends StatelessWidget {
  const SparePartsScreen({super.key});

  final List<Map<String, dynamic>> sellers = const [
    {
      'name': 'Auto Parts Plus',
      'rating': 4.7,
      'distance': '0.8 km',
      'categories': ['Engine', 'Brakes', 'Filters'],
      'phone': '+237 691 234 567',
    },
    {
      'name': 'Speedy Spares',
      'rating': 4.5,
      'distance': '1.5 km',
      'categories': ['Tires', 'Batteries', 'Oil'],
      'phone': '+237 692 345 678',
    },
    {
      'name': 'Genuine Auto Parts',
      'rating': 4.9,
      'distance': '2.3 km',
      'categories': ['OEM Parts', 'Accessories'],
      'phone': '+237 693 456 789',
    },
  ];

  final List<Map<String, dynamic>> featuredParts = const [
    {
      'name': 'Brake Pads',
      'price': 'XAF 25,000',
      'seller': 'Auto Parts Plus',
      'inStock': true,
    },
    {
      'name': 'Engine Oil 5W-30',
      'price': 'XAF 12,000',
      'seller': 'Speedy Spares',
      'inStock': true,
    },
    {
      'name': 'Car Battery',
      'price': 'XAF 85,000',
      'seller': 'Speedy Spares',
      'inStock': true,
    },
    {
      'name': 'Air Filter',
      'price': 'XAF 8,500',
      'seller': 'Auto Parts Plus',
      'inStock': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spare Parts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            // Category Tabs
            const TabBar(
              tabs: [
                Tab(text: 'Sellers'),
                Tab(text: 'Parts'),
              ],
              indicatorColor: Color(0xFF1A73E8),
              labelColor: Color(0xFF1A73E8),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildSellersTab(),
                  _buildPartsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSellersTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sellers.length,
      itemBuilder: (context, index) {
        final seller = sellers[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A73E8).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.store,
                        size: 28,
                        color: Color(0xFF1A73E8),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            seller['name'],
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                size: 14,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                seller['rating'].toString(),
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Icon(
                                Icons.location_on,
                                size: 14,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                seller['distance'],
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: seller['categories'].map<Widget>((category) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        category,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.call, size: 20),
                      onPressed: () {},
                      color: const Color(0xFF1A73E8),
                    ),
                    IconButton(
                      icon: const Icon(Icons.message, size: 20),
                      onPressed: () {},
                      color: const Color(0xFF1A73E8),
                    ),
                    const Spacer(),
                    OutlinedButton(
                      onPressed: () {},
                      child: const Text('View Parts'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A73E8),
                      ),
                      child: const Text('Contact'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPartsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: featuredParts.length,
      itemBuilder: (context, index) {
        final part = featuredParts[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A73E8).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.build_circle,
                    size: 28,
                    color: Color(0xFF1A73E8),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        part['name'],
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        part['seller'],
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        part['price'],
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: part['inStock']
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        part['inStock'] ? 'In Stock' : 'Out of Stock',
                        style: TextStyle(
                          fontSize: 11,
                          color: part['inStock'] ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: part['inStock'] ? () {} : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A73E8),
                        minimumSize: const Size(80, 32),
                      ),
                      child: const Text('Order', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}