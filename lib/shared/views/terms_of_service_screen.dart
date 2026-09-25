import 'package:flutter/material.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/shared/views/privacy_policy_screen.dart';

class TermsOfServiceScreen extends StatefulWidget {
  /// Pass [initialTab] = 1 to open on the Vendor tab directly.
  final int initialTab;
  const TermsOfServiceScreen({super.key, this.initialTab = 0});

  @override
  State<TermsOfServiceScreen> createState() => _TermsOfServiceScreenState();
}

class _TermsOfServiceScreenState extends State<TermsOfServiceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab,
    );
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
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Terms of Service',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondaryColor,
          indicatorColor: AppTheme.primaryColor,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(text: 'General'),
            Tab(text: 'Vendors'),
            Tab(text: 'Customers'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGeneralTab(),
          _buildVendorTab(),
          _buildCustomerTab(),
        ],
      ),
    );
  }

  // ─────────────────────────── GENERAL TAB ───────────────────────────

  Widget _buildGeneralTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderBanner(
            'Terms of Service',
            'Last updated: 23 March 2026',
            Icons.description,
          ),
          const SizedBox(height: 20),
          _buildIntroText(
            'Welcome to EventEase. These Terms of Service ("Terms") govern your access to and use of the EventEase mobile application, website, and related services (collectively, the "Platform") operated by EventEase Sdn. Bhd. ("Company", "we", "our", or "us").',
          ),
          const SizedBox(height: 8),
          _buildIntroText(
            'By registering an account or using the Platform, you agree to be bound by these Terms. If you do not agree, you must not use the Platform.',
          ),

          _buildSection('1', 'Acceptance of Terms', Icons.handshake, [
            _buildBody(
              'By accessing or using EventEase you confirm that you are at least 18 years old (or have parental consent), that you have legal capacity to enter into binding agreements, and that your use of the Platform complies with all applicable Malaysian laws and regulations.',
            ),
          ]),

          _buildSection('2', 'Description of Platform', Icons.apps, [
            _buildBody(
              'EventEase is a marketplace platform that connects event organisers ("Customers") with event service providers ("Vendors"). The Platform facilitates discovery, booking, payment, and management of event services including but not limited to catering, photography, entertainment, decorations, venues, and transportation.',
            ),
            const SizedBox(height: 8),
            _buildBody(
              'EventEase acts as an intermediary only. We are not party to the service contract formed between Customers and Vendors. We do not endorse, verify, or guarantee the quality of any services offered on the Platform unless explicitly stated.',
            ),
          ]),

          _buildSection('3', 'Account Registration', Icons.account_circle, [
            _buildBullet('You must provide accurate, current, and complete information during registration'),
            _buildBullet('You are responsible for maintaining the confidentiality of your account credentials'),
            _buildBullet('You must notify us immediately of any unauthorised access to your account'),
            _buildBullet('One person or legal entity may not maintain more than one active account without prior written approval'),
            _buildBullet('Accounts are non-transferable'),
            _buildBullet('We reserve the right to suspend or terminate accounts that violate these Terms'),
          ]),

          _buildSection('4', 'Prohibited Conduct', Icons.block, [
            _buildBody('You agree not to:'),
            const SizedBox(height: 8),
            _buildBullet('Use the Platform for any unlawful purpose or in violation of any applicable law'),
            _buildBullet('Post false, misleading, or deceptive content, reviews, or listings'),
            _buildBullet('Harass, threaten, or abuse other users'),
            _buildBullet('Attempt to gain unauthorised access to the Platform or other users\' accounts'),
            _buildBullet('Scrape, crawl, or use automated tools to extract data from the Platform'),
            _buildBullet('Circumvent the Platform to conduct transactions off-platform to avoid fees'),
            _buildBullet('Upload malicious code, viruses, or any content that could harm the Platform or its users'),
            _buildBullet('Impersonate any person or entity'),
          ]),

          _buildSection('5', 'Intellectual Property', Icons.copyright, [
            _buildBody(
              'All content on the Platform — including logos, text, images, graphics, software, and trademarks — is the property of EventEase Sdn. Bhd. or its licensors and is protected by Malaysian intellectual property law.',
            ),
            const SizedBox(height: 8),
            _buildBody(
              'You are granted a limited, non-exclusive, non-transferable, revocable licence to access and use the Platform for its intended purpose. You may not reproduce, modify, distribute, or create derivative works without prior written consent.',
            ),
          ]),

          _buildSection('6', 'Privacy', Icons.privacy_tip, [
            _buildBody(
              'Your use of the Platform is also governed by our Privacy Policy, which is incorporated into these Terms by reference. By using EventEase, you agree to the collection and processing of your personal data as described in the Privacy Policy.',
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PrivacyPolicyScreen(),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.open_in_new, size: 16, color: AppTheme.primaryColor),
                  const SizedBox(width: 6),
                  Text(
                    'View Privacy Policy',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationColor: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ]),

          _buildSection('7', 'Limitation of Liability', Icons.balance, [
            _buildBody(
              'To the maximum extent permitted by Malaysian law, EventEase shall not be liable for:',
            ),
            const SizedBox(height: 8),
            _buildBullet('The quality, safety, legality, or adequacy of services provided by Vendors'),
            _buildBullet('Any indirect, incidental, special, or consequential damages arising from use of the Platform'),
            _buildBullet('Loss of profits, data, or business opportunities'),
            _buildBullet('Any damages arising from Vendor or Customer conduct'),
            const SizedBox(height: 8),
            _buildBody(
              'Our total liability in any circumstance shall not exceed the amount of fees paid by you to EventEase in the 3 months preceding the claim.',
            ),
          ]),

          _buildSection('8', 'Dispute Resolution', Icons.gavel, [
            _buildBody(
              'Any dispute arising between Customers and Vendors should first be reported to EventEase support. We will make good-faith efforts to mediate within 14 business days.',
            ),
            const SizedBox(height: 8),
            _buildBody(
              'Disputes between you and EventEase Sdn. Bhd. that cannot be resolved informally shall be submitted to the Courts of Malaysia. These Terms are governed by and construed in accordance with the laws of Malaysia.',
            ),
          ]),

          _buildSection('9', 'Modifications to Terms', Icons.edit_document, [
            _buildBody(
              'We may update these Terms from time to time. We will provide at least 14 days\' notice of material changes via in-app notification and/or email. Your continued use of the Platform after the effective date constitutes your acceptance.',
            ),
          ]),

          _buildSection('10', 'Termination', Icons.exit_to_app, [
            _buildBody(
              'We reserve the right to suspend or terminate your access to the Platform at any time, with or without cause. Upon termination, your rights to use the Platform cease immediately. Provisions that by their nature should survive termination will do so, including intellectual property rights, disclaimers, and limitations of liability.',
            ),
          ]),

          _buildSection('11', 'Contact', Icons.contact_support, [
            _buildBody('For questions regarding these Terms, please contact us:'),
            const SizedBox(height: 12),
            _buildContactRow(Icons.email, 'legal@eventease.com'),
            _buildContactRow(Icons.web, 'www.eventease.com/legal'),
            _buildContactRow(Icons.location_on,
                'EventEase Sdn. Bhd., Level 15, Menara Kuala Lumpur,\nKuala Lumpur, 50250, Malaysia'),
          ]),

          _buildAcknowledgementBox(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ─────────────────────────── VENDOR TAB ───────────────────────────

  Widget _buildVendorTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderBanner(
            'Vendor Terms',
            'Additional terms for service providers',
            Icons.store,
            gradient: const LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          const SizedBox(height: 20),
          _buildIntroText(
            'These Vendor-specific terms supplement the General Terms of Service and apply to all users who register or operate as service providers ("Vendors") on EventEase. By creating a vendor account, you agree to these additional terms.',
          ),

          _buildSection('V1', 'Vendor Eligibility', Icons.verified_user, [
            _buildBullet('You must be a legally registered business entity or a sole proprietor operating lawfully in Malaysia'),
            _buildBullet('You must possess all required licences, permits, and certifications applicable to your services'),
            _buildBullet('You must be at least 18 years of age'),
            _buildBullet('Your business must not engage in activities that violate Malaysian law or EventEase community standards'),
            _buildBullet('You must provide accurate and up-to-date business registration details, including SSM registration number where applicable'),
          ]),

          _buildSection('V2', 'Vendor Onboarding & Verification', Icons.badge, [
            _buildBody(
              'Before your listings are published, EventEase may conduct a verification process including:',
            ),
            const SizedBox(height: 8),
            _buildBullet('Review of business registration documents (SSM Certificate or equivalent)'),
            _buildBullet('Identity verification of the account owner'),
            _buildBullet('Review of qualifications and professional certifications where applicable'),
            _buildBullet('Background checks as permitted by law'),
            const SizedBox(height: 8),
            _buildBody(
              'We reserve the right to reject or remove Vendor accounts that do not meet our standards. Verification does not constitute endorsement of your services.',
            ),
          ]),

          _buildSection('V3', 'Listings & Service Descriptions', Icons.list_alt, [
            _buildBullet('All service listings must be accurate, complete, and not misleading'),
            _buildBullet('You must clearly specify what is and is not included in each service package'),
            _buildBullet('Photos and media must represent your actual services'),
            _buildBullet('Pricing must be clearly stated, inclusive of all applicable taxes'),
            _buildBullet('You must keep your availability calendar accurate to avoid double-bookings'),
            _buildBullet('You may not list services that you are not legally authorised to provide'),
            _buildBullet('EventEase reserves the right to remove listings that violate our content standards'),
          ]),

          _buildSection('V4', 'Bookings & Fulfilment', Icons.event_available, [
            _buildBody(
              'When a Customer books your service:',
            ),
            const SizedBox(height: 8),
            _buildBullet('You are bound to fulfil the service as described in your listing and agreed upon with the Customer'),
            _buildBullet('You must respond to booking enquiries within 24 hours'),
            _buildBullet('Auto-accepted bookings are legally binding from the moment of acceptance'),
            _buildBullet('You must communicate any significant changes (e.g., team changes, equipment substitutions) to the Customer in advance'),
            _buildBullet('You are responsible for obtaining any event-specific permits or approvals required to perform your service'),
          ]),

          _buildSection('V5', 'Cancellation Policy', Icons.cancel, [
            _buildBullet('You may set your own cancellation policy within the options provided on the Platform'),
            _buildBullet('Frequent or last-minute cancellations may result in account suspension or termination'),
            _buildBullet('If you cancel a confirmed booking, you may be liable to compensate the Customer and EventEase for losses incurred'),
            _buildBullet('In case of force majeure (e.g., natural disaster, government directive), standard cancellation penalties may be waived at EventEase\'s discretion'),
          ]),

          _buildSection('V6', 'Fees & Payment', Icons.payments, [
            _buildBullet('EventEase charges a platform service fee (commission) on each completed transaction, as communicated during account setup'),
            _buildBullet('Commission rates are subject to change with 30 days\' prior notice'),
            _buildBullet('Payouts are processed within 3–5 business days after service completion confirmation'),
            _buildBullet('EventEase may withhold payouts in cases of active disputes, suspected fraud, or compliance investigations'),
            _buildBullet('You are responsible for declaring income and paying all applicable taxes, including SST, to the relevant Malaysian authorities'),
            _buildBullet('Invoices are generated automatically after each completed booking'),
          ]),

          _buildSection('V7', 'Customer Reviews & Ratings', Icons.star_rate, [
            _buildBullet('Customers may leave reviews and ratings after a completed booking'),
            _buildBullet('You may not solicit, manipulate, or offer incentives for positive reviews'),
            _buildBullet('You may report reviews that you believe violate EventEase\'s review policies'),
            _buildBullet('EventEase does not remove reviews solely because they are negative, unless they violate our content policies'),
            _buildBullet('Repeated poor ratings may result in listing demotion or account review'),
          ]),

          _buildSection('V8', 'Performance Standards', Icons.trending_up, [
            _buildBody(
              'To maintain good standing on EventEase, Vendors are expected to maintain:',
            ),
            const SizedBox(height: 8),
            _buildBullet('Response rate: ≥ 90% within 24 hours'),
            _buildBullet('Booking acceptance rate: ≥ 80%'),
            _buildBullet('Customer rating: ≥ 3.5 / 5.0 (averaged over the last 20 reviews)'),
            _buildBullet('Cancellation rate: ≤ 5%'),
            const SizedBox(height: 8),
            _buildBody(
              'Vendors who consistently fall below these benchmarks may receive warnings, listing suppression, or account suspension.',
            ),
          ]),

          _buildSection('V9', 'Insurance & Liability', Icons.health_and_safety, [
            _buildBullet('You are strongly encouraged to carry appropriate professional indemnity and public liability insurance'),
            _buildBullet('EventEase does not provide insurance coverage for Vendors or their clients'),
            _buildBullet('You are solely responsible for any property damage, personal injury, or financial loss arising from your services'),
            _buildBullet('You must indemnify EventEase against any claims arising from your services or conduct'),
          ]),

          _buildSection('V10', 'Confidentiality', Icons.lock_person, [
            _buildBody(
              'Customer personal data shared with you through the Platform (names, contact details, event details) must be:',
            ),
            const SizedBox(height: 8),
            _buildBullet('Used solely for the purpose of fulfilling the agreed booking'),
            _buildBullet('Kept confidential and not shared with unauthorised third parties'),
            _buildBullet('Handled in accordance with Malaysia\'s Personal Data Protection Act 2010'),
            _buildBullet('Deleted from your systems upon request or after the service is concluded, subject to your own legal retention obligations'),
          ]),

          _buildAcknowledgementBox(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ─────────────────────────── CUSTOMER TAB ───────────────────────────

  Widget _buildCustomerTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderBanner(
            'Customer Terms',
            'Additional terms for event organisers',
            Icons.person,
            gradient: const LinearGradient(
              colors: [Color(0xFF0EA5E9), Color(0xFF6366F1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          const SizedBox(height: 20),
          _buildIntroText(
            'These Customer-specific terms supplement the General Terms of Service and apply to all users who book services on EventEase ("Customers"). By making a booking, you agree to these additional terms.',
          ),

          _buildSection('C1', 'Booking Process', Icons.event_note, [
            _buildBody('When you make a booking through EventEase:'),
            const SizedBox(height: 8),
            _buildBullet('You are entering into a binding service agreement with the Vendor, not with EventEase'),
            _buildBullet('A booking is confirmed only after you receive a booking confirmation email or in-app notification'),
            _buildBullet('You must provide accurate event details (date, location, guest count, requirements) at the time of booking'),
            _buildBullet('Any special requests are subject to Vendor acceptance and may incur additional charges'),
            _buildBullet('You are responsible for ensuring the Vendor\'s service is suitable for your event'),
          ]),

          _buildSection('C2', 'Payments & Deposits', Icons.credit_card, [
            _buildBullet('Payment is processed securely through EventEase\'s approved payment gateways'),
            _buildBullet('A deposit (typically 20–50% of total booking value) may be required to secure a booking, as set by the Vendor'),
            _buildBullet('The remaining balance is due as specified in the booking agreement before or on the day of the event'),
            _buildBullet('Instalment payment plans may be available for eligible bookings, subject to Vendor settings'),
            _buildBullet('By providing your payment details, you authorise EventEase to charge the booking amount'),
            _buildBullet('All prices are displayed in Malaysian Ringgit (MYR) inclusive of applicable taxes unless stated otherwise'),
          ]),

          _buildSection('C3', 'Cancellation & Refund Policy', Icons.money_off, [
            _buildBody(
              'Cancellation and refund terms vary by Vendor. Always review the Vendor\'s cancellation policy before booking. General platform guidelines:',
            ),
            const SizedBox(height: 8),
            _buildBullet('Cancellations made ≥ 30 days before the event: eligible for a full refund of the deposit (minus processing fees), subject to Vendor policy'),
            _buildBullet('Cancellations made 14–29 days before the event: 50% refund of deposit, subject to Vendor policy'),
            _buildBullet('Cancellations made < 14 days before the event: typically non-refundable, subject to Vendor policy'),
            _buildBullet('Refunds are processed within 7–14 business days to your original payment method'),
            _buildBullet('In cases of force majeure (natural disaster, government order), EventEase will mediate to seek fair resolution'),
            const SizedBox(height: 8),
            _buildBody(
              'To cancel a booking, navigate to My Bookings → select booking → tap Cancel Booking. Refunds will be processed automatically per the applicable policy.',
            ),
          ]),

          _buildSection('C4', 'Amendments & Changes', Icons.edit, [
            _buildBullet('Requests to amend a confirmed booking (date, venue, guest count) must be made at least 14 days before the event'),
            _buildBullet('Amendment requests are subject to Vendor acceptance and may incur additional fees'),
            _buildBullet('EventEase facilitates amendment requests but cannot guarantee Vendor availability'),
            _buildBullet('Amendments are considered finalised only when confirmed by the Vendor and reflected in your booking'),
          ]),

          _buildSection('C5', 'Reviews & Ratings', Icons.rate_review, [
            _buildBullet('You may submit a review within 14 days of your event date'),
            _buildBullet('Reviews must be honest, based on genuine experience, and comply with our community guidelines'),
            _buildBullet('Reviews must not contain defamatory, offensive, or false statements'),
            _buildBullet('EventEase reserves the right to moderate or remove reviews that violate these guidelines'),
            _buildBullet('You must not accept incentives from Vendors in exchange for positive reviews'),
          ]),

          _buildSection('C6', 'Conduct & Responsibilities', Icons.people, [
            _buildBullet('You must treat Vendor staff with respect during all interactions'),
            _buildBullet('You are responsible for providing a safe working environment for Vendors performing services at your event'),
            _buildBullet('You must not request services from Vendors outside the Platform to circumvent EventEase fees'),
            _buildBullet('You are responsible for ensuring your event complies with all applicable laws (noise regulation, capacity limits, permits)'),
            _buildBullet('Misuse of the platform including chargebacks filed in bad faith may result in account suspension'),
          ]),

          _buildSection('C7', 'Dispute Resolution', Icons.balance, [
            _buildBody(
              'If you experience an issue with a Vendor\'s service:',
            ),
            const SizedBox(height: 8),
            _buildBullet('First, contact the Vendor directly through the in-app messaging system'),
            _buildBullet('If unresolved, raise a dispute through EventEase Support within 7 days of the event'),
            _buildBullet('Provide documentary evidence (photos, messages, contracts) to support your claim'),
            _buildBullet('EventEase will mediate in good faith within 14 business days'),
            _buildBullet('For refunds arising from valid disputes where the Vendor is at fault, EventEase will facilitate reimbursement'),
            _buildBullet('EventEase\'s decision in disputes is final and binding, subject to Malaysian consumer protection laws'),
          ]),

          _buildSection('C8', 'Consumer Rights', Icons.verified_user, [
            _buildBody(
              'As a customer, you retain all rights afforded by the Consumer Protection Act 1999 (Malaysia) and other applicable consumer protection legislation. These Terms do not limit any statutory rights you are entitled to as a consumer.',
            ),
          ]),

          _buildSection('C9', 'Loyalty & Promotions', Icons.card_giftcard, [
            _buildBullet('EventEase may offer loyalty points, promotional credits, or discount codes from time to time'),
            _buildBullet('Loyalty points are non-transferable, non-cashable, and expire 12 months from the date of earning'),
            _buildBullet('Promotional codes may have specific terms, minimum spend requirements, and expiry dates'),
            _buildBullet('EventEase reserves the right to modify or discontinue loyalty programs with 30 days\' notice'),
            _buildBullet('Abuse of promotions or loyalty programs may result in account suspension'),
          ]),

          _buildSection('C10', 'Data & Privacy', Icons.privacy_tip, [
            _buildBullet('Your personal data shared as part of the booking process (name, contact, event details) will be shared with the relevant Vendor solely for service fulfilment'),
            _buildBullet('You may request deletion of your account and personal data at any time, subject to legal retention requirements'),
            _buildBullet('EventEase will not share your data with third parties for marketing purposes without your explicit consent'),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PrivacyPolicyScreen(),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.open_in_new, size: 16, color: AppTheme.primaryColor),
                  const SizedBox(width: 6),
                  Text(
                    'View Privacy Policy',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationColor: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ]),

          _buildAcknowledgementBox(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ─────────────────────────── SHARED WIDGETS ───────────────────────────

  Widget _buildHeaderBanner(
    String title,
    String subtitle,
    IconData icon, {
    Gradient? gradient,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient ??
            const LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 36),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String number, String title, IconData icon, List<Widget> content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      number,
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(icon, color: AppTheme.primaryColor, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              ...content,
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildIntroText(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        color: AppTheme.textSecondaryColor,
        height: 1.65,
      ),
    );
  }

  Widget _buildBody(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        color: AppTheme.textSecondaryColor,
        height: 1.65,
      ),
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: CircleAvatar(
              radius: 3,
              backgroundColor: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcknowledgementBox() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle, color: AppTheme.primaryColor, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'By using EventEase, you acknowledge that you have read, understood, and agreed to these Terms of Service.',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondaryColor,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
