import 'package:flutter/material.dart';
import 'package:eventease/core/utils/app_theme.dart';

class EmergencyPartnerMatcherScreen extends StatefulWidget {
  final String incidentId;
  final String categoryRequired;

  const EmergencyPartnerMatcherScreen({
    Key? key,
    required this.incidentId,
    required this.categoryRequired,
  }) : super(key: key);

  @override
  State<EmergencyPartnerMatcherScreen> createState() => _EmergencyPartnerMatcherScreenState();
}

class _EmergencyPartnerMatcherScreenState extends State<EmergencyPartnerMatcherScreen> {
  bool _isSearching = true;

  // Mock list of emergency partners
  final List<Map<String, dynamic>> _partners = [
    {
      'name': 'Elite Captures Photography',
      'rating': 4.9,
      'reliability': 99,
      'distance': '3.2 km away',
      'eta': '15 mins',
      'status': 'available', // available, pinged, accepted
      'price_multiplier': 1.5,
    },
    {
      'name': 'QuickSnap Studio',
      'rating': 4.7,
      'reliability': 95,
      'distance': '5.1 km away',
      'eta': '25 mins',
      'status': 'available',
      'price_multiplier': 1.2,
    },
    {
      'name': 'ProEvent Shooters',
      'rating': 4.8,
      'reliability': 98,
      'distance': '8.0 km away',
      'eta': '35 mins',
      'status': 'available',
      'price_multiplier': 1.3,
    },
  ];

  @override
  void initState() {
    super.initState();
    // Simulate API delay for finding partners
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    });
  }

  void _pingPartner(int index) {
    setState(() {
      _partners[index]['status'] = 'pinged';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('High-Priority SMS & Push sent to ${_partners[index]['name']}!'),
        backgroundColor: Colors.orange,
      ),
    );

    // Simulate partner accepting after a few seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && _partners[index]['status'] == 'pinged') {
        setState(() {
          _partners[index]['status'] = 'accepted';
        });
        _showSuccessDialog(_partners[index]);
      }
    });
  }

  void _showSuccessDialog(Map<String, dynamic> partner) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Rescue Accepted!'),
          ],
        ),
        content: Text('${partner['name']} has accepted the emergency job and is en route. ETA is ${partner['eta']}. The customer has been notified.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // go back to rescue room
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            child: const Text('Back to Rescue Room'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Emergency Partners', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        elevation: 1,
      ),
      body: _isSearching
          ? _buildSearchingState()
          : _buildResultsList(),
    );
  }

  Widget _buildSearchingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(color: Colors.redAccent, strokeWidth: 8),
          ),
          const SizedBox(height: 32),
          Text(
            'Scanning for ${widget.categoryRequired}...',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            'Filtering by Reliability Score > 95%\nand Distance < 15km',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _partners.length + 1, // +1 for header
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              '${_partners.length} highly reliable partners found near the venue.',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          );
        }

        final partner = _partners[index - 1];
        final isPinged = partner['status'] == 'pinged';
        final isAccepted = partner['status'] == 'accepted';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isAccepted ? Colors.green : Colors.transparent, width: 2),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue.shade50,
                    child: const Icon(Icons.business, color: Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(partner['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 14),
                            Text(' ${partner['rating']}  •  ', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            const Icon(Icons.shield, color: Colors.green, size: 14),
                            Text(' ${partner['reliability']}% Reliability', style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(partner['distance'], style: const TextStyle(fontSize: 13, color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.flash_on, size: 14, color: Colors.orange),
                          const SizedBox(width: 4),
                          Text('ETA: ${partner['eta']}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.orange)),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Surge Rate', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                      Text('${partner['price_multiplier']}x', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (isPinged || isAccepted) ? null : () => _pingPartner(index - 1),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAccepted ? Colors.green : (isPinged ? Colors.orange : Colors.black87),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    isAccepted ? 'Accepted' : (isPinged ? 'Pinging Vendor...' : 'Send Rescue Request'),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
