import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RoyalWeddingPage extends StatefulWidget {
  const RoyalWeddingPage({super.key});

  @override
  State<RoyalWeddingPage> createState() => _RoyalWeddingPageState();
}

class _RoyalWeddingPageState extends State<RoyalWeddingPage> {
  double guestCount = 500;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.only(bottom: 150),
            children: [
              // Image Header
              Stack(
                children: [
                  Image.network(
                    "https://lh3.googleusercontent.com/aida-public/AB6AXuD0LnxKEj--7_0Yz7Upkm_dkVsYs2k_sKBCmvrH46T0hkXwdKvSBZMiDxopoH26jD0KhyUfNxy6hnrJVqwsqER2sRx0cWBax2M1CCpeTtLRt-CgoFWiERiQuhdETV3RNSzOQkO6WgyEOfR87squGNfUaZ-g1PWmjllPlvpBbn1TWxHuwbkPlnAEhxVEe5NMIupRSg93-Tajef1otZrekS5qQbcoLHYWqQhJUt7e3XMKFz-OHwO1eCKRVf8sQGkib2a02-J3z19rPSr2",
                    height: 400,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  Container(
                    height: 400,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.6),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD4AF37),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                "Premium Package",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.star, size: 14, color: Colors.yellow[400]),
                                  const SizedBox(width: 2),
                                  const Text("4.9 (240 Reviews)", style: TextStyle(fontSize: 10, color: Colors.white)),
                                ],
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Full Wedding Package with Essentials",
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Row(
                          children: [
                            Icon(Icons.location_on, size: 16, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              "Kuala Lumpur, Malaysia",
                              style: TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Package Selection Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        child: Text("Silver", style: TextStyle(color: Colors.grey[600])),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8E735B),
                        ),
                        onPressed: () {},
                        child: const Text("Gold", style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        child: Text("Platinum", style: TextStyle(color: Colors.grey[600])),
                      ),
                    ),
                  ],
                ),
              ),

              // Guest Capacity Slider
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  elevation: 2,
                  shadowColor: Colors.black12,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Guest Capacity".toUpperCase(),
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey[400], fontWeight: FontWeight.bold)),
                                Text(
                                  "${guestCount.toInt()} Pax",
                                  style: GoogleFonts.playfairDisplay(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF8E735B)),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text("Est. Price/Pax", style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                                const Text("RM 85.00",
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37))),
                              ],
                            )
                          ],
                        ),
                        Slider(
                          value: guestCount,
                          min: 200,
                          max: 1000,
                          divisions: 8,
                          activeColor: const Color(0xFF8E735B),
                          onChanged: (value) {
                            setState(() {
                              guestCount = value;
                            });
                          },
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [200, 300, 500, 1000]
                              .map((e) => Text("$e", style: const TextStyle(fontSize: 10, color: Colors.grey)))
                              .toList(),
                        )
                      ],
                    ),
                  ),
                ),
              ),

              // Inclusions & Sections Example
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Inclusions", style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    const InclusionCard(
                      title: "Grand Ballroom Venue",
                      icon: Icons.domain,
                      description: "Exclusive access to the Grand Crystal Ballroom with premium foyer and stage setup.",
                      imageUrl: "https://lh3.googleusercontent.com/aida-public/AB6AXuD0LnxKEj--7_0Yz7Upkm_dkVsYs2k_sKBCmvrH46T0hkXwdKvSBZMiDxopoH26jD0KhyUfNxy6hnrJVqwsqER2sRx0cWBax2M1CCpeTtLRt-CgoFWiERiQuhdETV3RNSzOQkO6WgyEOfR87squGNfUaZ-g1PWmjllPlvpBbn1TWxHuwbkPlnAEhxVEe5NMIupRSg93-Tajef1otZrekS5qQbcoLHYWqQhJUt7e3XMKFz-OHwO1eCKRVf8sQGkib2a02-J3z19rPSr2",
                    ),
                    const InclusionCard(
                      title: "Premium Catering",
                      icon: Icons.restaurant,
                      description: "7-Course Traditional Malay Menu, authentic dishes prepared by master chefs.",
                      imageUrl: "https://lh3.googleusercontent.com/aida-public/AB6AXuC07ZSL8VoNjxyj-ykYN7cra3CGkufz0yJOq1dBlnL6eoln0m4BYzWF58Nlbm9enmY3GxhEU__JtpjJZzWv2cSrCFp5orXtNwBeSjlhDlOfQ3ekU2jg0--yQspc47JufrMH65blWuh5dDrl6Ic4PJRFxtUmTZk1XrUp_eXJYX27COApXIR7Tygw2pOpyEoSX1iLICxpTgqjpDRZ7jhTG9omLDb8wmTTvtpFYY4e74s9hZSszpRt00Lq5M1q5JbVvvhVWc3YPi7fVco3",
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Icon(Icons.arrow_back_ios_new, color: Color(0xFF8E735B), size: 18),
                      ),
                    ),
                    Text(
                      "Royal Elegance",
                      style: GoogleFonts.playfairDisplay(
                          fontWeight: FontWeight.bold, fontStyle: FontStyle.italic, fontSize: 18, color: const Color(0xFF8E735B)),
                    ),
                    const CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(Icons.favorite_border, color: Color(0xFF8E735B), size: 18),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, -4),
              blurRadius: 10,
            ),
          ],
          border: Border(top: BorderSide(color: Colors.grey.shade100)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Estimated Total".toUpperCase(),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text("RM 42,500", style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                        const SizedBox(width: 4),
                        const Text("incl. tax", style: TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(4)),
                  child: Text("All-Inclusive", style: TextStyle(color: Colors.green[600], fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xFF8E735B)),
                    ),
                    onPressed: () {},
                    icon: const Icon(Icons.chat_bubble_outline, size: 18, color: Color(0xFF8E735B)),
                    label: const Text("Chat", style: TextStyle(color: Color(0xFF8E735B))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8E735B),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {},
                    child: const Text("Book Now", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class InclusionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String description;
  final String imageUrl;

  const InclusionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.description,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: CircleAvatar(
          backgroundColor: Colors.blue[50],
          child: Icon(icon, color: Colors.blue[600], size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        trailing: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF8E735B)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(imageUrl, height: 160, width: double.infinity, fit: BoxFit.cover),
                ),
                const SizedBox(height: 12),
                Text(description, style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
