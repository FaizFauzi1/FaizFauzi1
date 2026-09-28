import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/organizer/data/models/exhibitor_vendor.dart';
import 'package:eventease/features/organizer/data/repositories/organizer_repository.dart';

class VendorPostEventScreen extends StatefulWidget {
  final ExhibitorVendor exhibitor;

  const VendorPostEventScreen({
    super.key,
    required this.exhibitor,
  });

  static const routeName = '/vendor-post-event';

  @override
  State<VendorPostEventScreen> createState() => _VendorPostEventScreenState();
}

class _VendorPostEventScreenState extends State<VendorPostEventScreen> {
  late ExhibitorVendor _exhibitor;
  double _overallRating = 5.0;
  double _crowdQualityRating = 4.5;
  double _facilitiesRating = 4.0;
  double _supportRating = 5.0;
  final TextEditingController _feedbackController = TextEditingController();
  String _exhibitAgain = 'yes'; // 'yes', 'maybe', 'no'
  bool _isSubmittingReview = false;
  bool _reviewSubmitted = false;

  @override
  void initState() {
    super.initState();
    _exhibitor = widget.exhibitor;
    if (_exhibitor.postEventRating != null) {
      _overallRating = _exhibitor.postEventRating!;
      _reviewSubmitted = true;
    }
    if (_exhibitor.postEventReview != null) {
      _feedbackController.text = _exhibitor.postEventReview!;
    }
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    setState(() => _isSubmittingReview = true);
    try {
      await OrganizerRepository.instance.submitPostEventReview(
        _exhibitor.id,
        rating: _overallRating,
        comment: _feedbackController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _isSubmittingReview = false;
        _reviewSubmitted = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thank you! Your feedback has been submitted to the organiser.'),
          backgroundColor: Color(0xFF059669),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmittingReview = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit review: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'ms_MY', symbol: 'RM ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Post-Event Insights & Review', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Summary Banner
            _buildEventHeader(),
            const SizedBox(height: 20),

            // Performance Metrics
            const Text(
              'Exhibition ROI & Impact',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 12),
            _buildMetricsGrid(currency),
            const SizedBox(height: 20),

            // Certificate of Participation
            _buildCertificateCard(),
            const SizedBox(height: 24),

            // Organiser Review & Rating Form
            _buildReviewCard(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildEventHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'EXPO WRAP-UP',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                ),
              ),
              const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
                  SizedBox(width: 4),
                  Text('Completed', style: TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _exhibitor.expoName ?? 'Exhibition',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          Text(
            'Booth ${_exhibitor.boothNumber ?? "Not assigned"} · ${_exhibitor.companyName}',
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(NumberFormat currency) {
    final metrics = [
      {'label': 'Booth Footfall', 'value': '1,480+', 'icon': Icons.people_outline_rounded, 'color': const Color(0xFF3B82F6)},
      {'label': 'Leads Captured', 'value': '142 leads', 'icon': Icons.contact_page_outlined, 'color': const Color(0xFF10B981)},
      {'label': 'On-Site Bookings', 'value': '18 orders', 'icon': Icons.shopping_bag_outlined, 'color': const Color(0xFFF59E0B)},
      {'label': 'Est. Revenue', 'value': currency.format(42800), 'icon': Icons.payments_outlined, 'color': const Color(0xFF8B5CF6)},
    ];

    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: metrics.length,
          itemBuilder: (ctx, idx) {
            final m = metrics[idx];
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(m['icon'] as IconData, color: m['color'] as Color, size: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m['value'] as String,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        m['label'] as String,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Exported 142 leads to leads_export.csv')),
              );
            },
            icon: const Icon(Icons.download_rounded, size: 18),
            label: const Text('Export All Captured Leads (CSV)'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF334155),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCertificateCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.military_tech_rounded, color: Color(0xFFD97706), size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Certificate of Participation',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF92400E)),
                ),
                const SizedBox(height: 2),
                Text(
                  'Verified official exhibitor badge & credential',
                  style: TextStyle(fontSize: 11, color: Colors.brown.shade700),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded, color: Color(0xFF92400E)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Downloading official Certificate PDF...')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.rate_review_rounded, color: Color(0xFF3B82F6), size: 22),
              const SizedBox(width: 8),
              Text(
                _reviewSubmitted ? 'Your Feedback' : 'Rate Your Expo Experience',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Rating sliders / stars
          _starRatingRow('Overall Satisfaction', _overallRating, (v) => setState(() => _overallRating = v)),
          const SizedBox(height: 10),
          _starRatingRow('Visitor Footfall Quality', _crowdQualityRating, (v) => setState(() => _crowdQualityRating = v)),
          const SizedBox(height: 10),
          _starRatingRow('Venue & Hall Facilities', _facilitiesRating, (v) => setState(() => _facilitiesRating = v)),
          const SizedBox(height: 10),
          _starRatingRow('Organiser Support & Team', _supportRating, (v) => setState(() => _supportRating = v)),
          const SizedBox(height: 18),

          const Text(
            'Would you participate again next year?',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _choiceButton('yes', 'Definitely Yes 👍'),
              const SizedBox(width: 8),
              _choiceButton('maybe', 'Undecided 🤔'),
              const SizedBox(width: 8),
              _choiceButton('no', 'No 👎'),
            ],
          ),
          const SizedBox(height: 16),

          const Text(
            'Comments / Suggestions for Organiser',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _feedbackController,
            enabled: !_reviewSubmitted,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Share what went well and what could be improved next time...',
              hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 18),

          if (!_reviewSubmitted)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmittingReview ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmittingReview
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Submit Review to Organiser', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Review submitted · Thank you!',
                    style: TextStyle(color: Color(0xFF065F46), fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _starRatingRow(String label, double rating, ValueChanged<double> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF334155))),
        ),
        Row(
          children: List.generate(5, (index) {
            final starIndex = index + 1;
            final isFilled = rating >= starIndex;
            return InkWell(
              onTap: _reviewSubmitted ? null : () => onChanged(starIndex.toDouble()),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Icon(
                  isFilled ? Icons.star_rounded : Icons.star_border_rounded,
                  color: isFilled ? const Color(0xFFF59E0B) : const Color(0xFFCBD5E1),
                  size: 24,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _choiceButton(String value, String label) {
    final isSelected = _exhibitAgain == value;
    return Expanded(
      child: OutlinedButton(
        onPressed: _reviewSubmitted ? null : () => setState(() => _exhibitAgain = value),
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.1) : Colors.white,
          side: BorderSide(
            color: isSelected ? AppTheme.primaryColor : const Color(0xFFCBD5E1),
            width: isSelected ? 1.8 : 1,
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppTheme.primaryColor : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }
}
