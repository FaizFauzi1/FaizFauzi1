import 'package:flutter/material.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/organizer/data/models/exhibitor_vendor.dart';

class VendorFloorPlanScreen extends StatefulWidget {
  final ExhibitorVendor exhibitor;

  const VendorFloorPlanScreen({
    super.key,
    required this.exhibitor,
  });

  static const routeName = '/vendor-floor-plan';

  @override
  State<VendorFloorPlanScreen> createState() => _VendorFloorPlanScreenState();
}

class _VendorFloorPlanScreenState extends State<VendorFloorPlanScreen> {
  String _selectedZone = 'All Zones';
  String? _inspectedBoothNumber;

  // Mock booth grid representing Hall 2
  late final List<Map<String, dynamic>> _booths;

  @override
  void initState() {
    super.initState();
    _inspectedBoothNumber = widget.exhibitor.boothNumber ?? 'A-05';
    _initBooths();
  }

  void _initBooths() {
    final myBooth = widget.exhibitor.boothNumber ?? 'A-05';
    _booths = [
      {'num': 'A-01', 'zone': 'Zone A (Bridal)', 'vendor': 'Bella Wedding Gowns', 'cat': 'Attire', 'status': 'occupied', 'size': '3m x 3m'},
      {'num': 'A-02', 'zone': 'Zone A (Bridal)', 'vendor': 'Chic Bridal Studio', 'cat': 'Attire', 'status': 'occupied', 'size': '3m x 3m'},
      {'num': 'A-03', 'zone': 'Zone A (Bridal)', 'vendor': 'Vogue Tailoring', 'cat': 'Groom Suits', 'status': 'occupied', 'size': '3m x 3m'},
      {'num': 'A-04', 'zone': 'Zone A (Bridal)', 'vendor': 'Available', 'cat': 'Open', 'status': 'available', 'size': '3m x 3m'},
      {'num': myBooth, 'zone': 'Zone A (Bridal)', 'vendor': widget.exhibitor.companyName, 'cat': widget.exhibitor.category, 'status': 'mine', 'size': widget.exhibitor.boothSize},
      {'num': 'A-06', 'zone': 'Zone A (Bridal)', 'vendor': 'Crown Jewels & Bands', 'cat': 'Jewelry', 'status': 'occupied', 'size': '3m x 3m'},
      {'num': 'B-01', 'zone': 'Zone B (Photo)', 'vendor': 'Lumiere Studios', 'cat': 'Photography', 'status': 'occupied', 'size': '3m x 4m'},
      {'num': 'B-02', 'zone': 'Zone B (Photo)', 'vendor': 'Kite Cinematography', 'cat': 'Videography', 'status': 'occupied', 'size': '3m x 4m'},
      {'num': 'B-03', 'zone': 'Zone B (Photo)', 'vendor': 'Available', 'cat': 'Open', 'status': 'available', 'size': '3m x 4m'},
      {'num': 'B-04', 'zone': 'Zone B (Photo)', 'vendor': 'Moments PhotoBooth', 'cat': 'Interactive', 'status': 'occupied', 'size': '3m x 4m'},
      {'num': 'C-01', 'zone': 'Zone C (Catering)', 'vendor': 'Royale Gourmet Catering', 'cat': 'Catering', 'status': 'occupied', 'size': '6m x 6m'},
      {'num': 'C-02', 'zone': 'Zone C (Catering)', 'vendor': 'Sweet Bliss Patisserie', 'cat': 'Desserts & Cakes', 'status': 'occupied', 'size': '3m x 3m'},
      {'num': 'VIP-1', 'zone': 'VIP Lane', 'vendor': 'Mandarin Oriental KL', 'cat': 'Venue Host', 'status': 'vip', 'size': '8m x 8m'},
      {'num': 'VIP-2', 'zone': 'VIP Lane', 'vendor': 'Glitz Luxury Stage Decor', 'cat': 'Floral & Decor', 'status': 'vip', 'size': '8m x 8m'},
    ];
  }

  Map<String, dynamic>? get _inspectedBooth {
    if (_inspectedBoothNumber == null) return null;
    return _booths.firstWhere(
      (b) => b['num'] == _inspectedBoothNumber,
      orElse: () => _booths.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    final myBooth = widget.exhibitor.boothNumber ?? 'A-05';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Interactive Floor Plan', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Top Navigation / Zone Filter
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _zoneFilterChip('All Zones'),
                  _zoneFilterChip('Zone A (Bridal)'),
                  _zoneFilterChip('Zone B (Photo)'),
                  _zoneFilterChip('Zone C (Catering)'),
                  _zoneFilterChip('VIP Lane'),
                ],
              ),
            ),
          ),

          // Legend Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFFF1F5F9),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _legendDot(const Color(0xFF4F46E5), 'Your Booth'),
                _legendDot(const Color(0xFF64748B), 'Booked'),
                _legendDot(const Color(0xFF10B981), 'Available'),
                _legendDot(const Color(0xFFF59E0B), 'VIP Island'),
              ],
            ),
          ),

          // Floor Map Graphic Grid
          Expanded(
            flex: 6,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFCBD5E1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Main Hall Entrance marker
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'MAIN ENTRANCE / REGISTRATION FOYER ▲',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569), letterSpacing: 1),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Booth layout grid
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.25,
                      ),
                      itemCount: _filteredBooths.length,
                      itemBuilder: (ctx, idx) {
                        final b = _filteredBooths[idx];
                        final isMine = b['num'] == myBooth;
                        final isSelected = b['num'] == _inspectedBoothNumber;
                        final isAvailable = b['status'] == 'available';
                        final isVip = b['status'] == 'vip';

                        Color bgColor;
                        Color borderColor;
                        Color textColor;

                        if (isMine) {
                          bgColor = const Color(0xFF4F46E5);
                          borderColor = const Color(0xFF312E81);
                          textColor = Colors.white;
                        } else if (isVip) {
                          bgColor = const Color(0xFFFFFBEB);
                          borderColor = const Color(0xFFF59E0B);
                          textColor = const Color(0xFF92400E);
                        } else if (isAvailable) {
                          bgColor = const Color(0xFFECFDF5);
                          borderColor = const Color(0xFF10B981);
                          textColor = const Color(0xFF065F46);
                        } else {
                          bgColor = const Color(0xFFF8FAFC);
                          borderColor = const Color(0xFFCBD5E1);
                          textColor = const Color(0xFF334155);
                        }

                        return InkWell(
                          onTap: () => setState(() => _inspectedBoothNumber = b['num'] as String),
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF0F172A) : borderColor,
                                width: isSelected ? 2.5 : 1.2,
                              ),
                              boxShadow: isMine
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF4F46E5).withValues(alpha: 0.35),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : null,
                            ),
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (isMine)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'YOU',
                                      style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Color(0xFF4F46E5)),
                                    ),
                                  ),
                                Text(
                                  b['num'] as String,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  b['vendor'] as String,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isMine ? Colors.white70 : const Color(0xFF64748B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 6),
                  // Rear Emergency Exit marker
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '▼ LOADING BAY & FIRE EXIT (HALL 2 REAR)',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF64748B), letterSpacing: 0.5),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Inspected Booth Card Bottom Sheet / Detail
          Expanded(
            flex: 4,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -3)),
                ],
              ),
              child: _inspectedBooth == null
                  ? const Center(child: Text('Tap any booth to see details'))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _inspectedBooth!['num'] == myBooth
                                        ? const Color(0xFF4F46E5)
                                        : const Color(0xFF0F172A),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Booth ${_inspectedBooth!['num']}',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (_inspectedBooth!['num'] == myBooth)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFECFDF5),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFFA7F3D0)),
                                    ),
                                    child: const Text(
                                      'Your Assigned Space',
                                      style: TextStyle(color: Color(0xFF059669), fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                              ],
                            ),
                            Text(
                              _inspectedBooth!['size'] as String,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _inspectedBooth!['vendor'] as String,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              _inspectedBooth!['zone'] as String,
                              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                            ),
                            const Text(' · ', style: TextStyle(color: Color(0xFF94A3B8))),
                            Text(
                              _inspectedBooth!['cat'] as String,
                              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        const Spacer(),
                        if (_inspectedBooth!['num'] == myBooth)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Booth guide & load-in credentials saved')),
                                );
                              },
                              icon: const Icon(Icons.download_rounded, size: 18),
                              label: const Text('Download Booth Technical Specs (PDF)'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          )
                        else
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Sent networking wave to ${_inspectedBooth!['vendor']}')),
                                );
                              },
                              icon: const Icon(Icons.handshake_rounded, size: 18),
                              label: const Text('Connect with Neighbor'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF334155),
                                side: const BorderSide(color: Color(0xFFCBD5E1)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredBooths {
    if (_selectedZone == 'All Zones') return _booths;
    return _booths.where((b) => (b['zone'] as String).contains(_selectedZone.replaceAll(' (Bridal)', '').replaceAll(' (Photo)', '').replaceAll(' (Catering)', ''))).toList();
  }

  Widget _zoneFilterChip(String label) {
    final isSelected = _selectedZone == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        selected: isSelected,
        selectedColor: AppTheme.primaryColor.withValues(alpha: 0.15),
        labelStyle: TextStyle(color: isSelected ? AppTheme.primaryColor : const Color(0xFF64748B)),
        backgroundColor: const Color(0xFFF1F5F9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? AppTheme.primaryColor : Colors.transparent)),
        onSelected: (_) => setState(() => _selectedZone = label),
      ),
    );
  }

  Widget _legendDot(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
      ],
    );
  }
}
