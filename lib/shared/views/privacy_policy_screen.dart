import 'package:flutter/material.dart';
import 'package:eventease/core/utils/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
          'Privacy Policy',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.privacy_tip, color: Colors.white, size: 36),
                  const SizedBox(height: 12),
                  const Text(
                    'Your Privacy Matters',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Last updated: 23 March 2026',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildIntroText(
              'EventEase Sdn. Bhd. ("EventEase", "we", "our", or "us") is committed to protecting your personal information. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application and related services.',
            ),
            const SizedBox(height: 8),
            _buildIntroText(
              'By using EventEase, you agree to the collection and use of information in accordance with this policy. This policy applies to both Customers and Vendors registered on the platform.',
            ),

            const SizedBox(height: 24),
            _buildSection(
              number: '1',
              title: 'Information We Collect',
              icon: Icons.folder_open,
              content: [
                _buildSubheading('1.1 Information You Provide'),
                _buildBullet('Account registration details: full name, email address, phone number, and password'),
                _buildBullet('Profile information: profile photo, date of birth, address, and business details (for vendors)'),
                _buildBullet('Payment details: billing address and payment method information (processed securely via payment gateways)'),
                _buildBullet('Booking and event details: event dates, venues, guest counts, and service selections'),
                _buildBullet('Communication content: messages sent via our in-app chat, support tickets, and feedback forms'),
                _buildBullet('Documents & certifications: business licences, identification documents, and permits uploaded by vendors'),
                const SizedBox(height: 8),
                _buildSubheading('1.2 Information Collected Automatically'),
                _buildBullet('Device information: device model, operating system, unique device identifiers, and mobile network details'),
                _buildBullet('Log data: IP addresses, browser type, pages visited, time and date of visits, and other diagnostic data'),
                _buildBullet('Location data: approximate location based on IP address (precise location only with your explicit permission)'),
                _buildBullet('Usage data: features used, search queries, click patterns, booking history, and interaction data'),
                _buildBullet('Cookies and similar tracking technologies to maintain session state and personalise your experience'),
                const SizedBox(height: 8),
                _buildSubheading('1.3 Information from Third Parties'),
                _buildBullet('Social login data (if you sign in via Google or Facebook): name, email, and profile picture'),
                _buildBullet('Payment processors: transaction status and masked payment details'),
                _buildBullet('Analytics providers: aggregated usage and crash reports'),
              ],
            ),

            _buildSection(
              number: '2',
              title: 'How We Use Your Information',
              icon: Icons.settings_applications,
              content: [
                _buildSubheading('2.1 To Provide Our Services'),
                _buildBullet('Process and manage bookings between customers and vendors'),
                _buildBullet('Verify vendor identity, credentials, and business legitimacy'),
                _buildBullet('Process payments, refunds, and payouts'),
                _buildBullet('Send booking confirmations, receipts, and service updates'),
                const SizedBox(height: 8),
                _buildSubheading('2.2 To Improve Our Platform'),
                _buildBullet('Analyse usage patterns to improve features and user experience'),
                _buildBullet('Conduct research and surveys'),
                _buildBullet('Detect, prevent, and address technical issues, fraud, and abuse'),
                const SizedBox(height: 8),
                _buildSubheading('2.3 Communications'),
                _buildBullet('Send important service announcements and policy updates'),
                _buildBullet('Send marketing communications (with your consent; you may opt out at any time)'),
                _buildBullet('Respond to customer support requests'),
                const SizedBox(height: 8),
                _buildSubheading('2.4 Legal & Compliance'),
                _buildBullet('Comply with applicable laws and regulations in Malaysia, including the Personal Data Protection Act 2010 (PDPA)'),
                _buildBullet('Enforce our Terms of Service and other agreements'),
                _buildBullet('Protect the rights, property, or safety of EventEase, our users, or others'),
              ],
            ),

            _buildSection(
              number: '3',
              title: 'Sharing of Your Information',
              icon: Icons.share,
              content: [
                _buildBody(
                  'We do not sell, trade, or rent your personal information to third parties. We may share your information in the following limited circumstances:',
                ),
                const SizedBox(height: 8),
                _buildBullet('Between Customers and Vendors: when a booking is made, relevant contact and event details are shared between the two parties to facilitate service delivery'),
                _buildBullet('Service providers: trusted third parties who assist in operating our platform (e.g., payment gateways, cloud storage, analytics, SMS/email delivery) under strict confidentiality obligations'),
                _buildBullet('Business transfers: in the event of a merger, acquisition, or sale of assets, your information may be transferred with appropriate notice'),
                _buildBullet('Legal requirements: when required by Malaysian law, court order, or government authority'),
                _buildBullet('Safety: to prevent imminent harm or unlawful activity'),
              ],
            ),

            _buildSection(
              number: '4',
              title: 'Data Retention',
              icon: Icons.schedule,
              content: [
                _buildBody(
                  'We retain your personal information for as long as necessary to fulfil the purposes outlined in this policy or as required by law.',
                ),
                const SizedBox(height: 8),
                _buildBullet('Active accounts: data is retained for the duration of your account'),
                _buildBullet('Inactive accounts: data is deleted or anonymised after 3 years of account inactivity, unless legal obligations require longer retention'),
                _buildBullet('Booking records: retained for 7 years in accordance with Malaysian financial record-keeping requirements'),
                _buildBullet('Marketing preferences: retained until you opt out'),
              ],
            ),

            _buildSection(
              number: '5',
              title: 'Data Security',
              icon: Icons.security,
              content: [
                _buildBody(
                  'We implement industry-standard security measures to protect your personal data:',
                ),
                const SizedBox(height: 8),
                _buildBullet('Transport Layer Security (TLS/HTTPS) encryption for all data in transit'),
                _buildBullet('AES-256 encryption for sensitive data at rest'),
                _buildBullet('Access controls: only authorised personnel can access your data on a need-to-know basis'),
                _buildBullet('Regular security audits and vulnerability assessments'),
                _buildBullet('Firewalls and intrusion detection systems'),
                const SizedBox(height: 8),
                _buildBody(
                  'Despite these measures, no method of internet transmission is 100% secure. In the event of a data breach, we will notify affected users in accordance with applicable law.',
                ),
              ],
            ),

            _buildSection(
              number: '6',
              title: 'Your Rights (PDPA)',
              icon: Icons.gavel,
              content: [
                _buildBody(
                  'Under the Personal Data Protection Act 2010 (Malaysia), you have the following rights:',
                ),
                const SizedBox(height: 8),
                _buildBullet('Right of access: request a copy of the personal data we hold about you'),
                _buildBullet('Right of correction: request correction of inaccurate or incomplete data'),
                _buildBullet('Right to withdraw consent: withdraw consent to processing for non-essential purposes (including marketing) at any time'),
                _buildBullet('Right to object: object to processing that causes substantial damage or distress'),
                _buildBullet('Right to data portability: receive your data in a structured, machine-readable format where technically feasible'),
                const SizedBox(height: 8),
                _buildBody(
                  'To exercise your rights, contact us at privacy@eventease.com. We will respond within 21 business days.',
                ),
              ],
            ),

            _buildSection(
              number: '7',
              title: 'Cookies & Tracking',
              icon: Icons.cookie,
              content: [
                _buildBody(
                  'Our app uses cookies and similar technologies to:',
                ),
                const SizedBox(height: 8),
                _buildBullet('Maintain your session (essential cookies — cannot be disabled)'),
                _buildBullet('Remember your preferences such as language and theme'),
                _buildBullet('Analyse app performance and user behaviour (analytics cookies — can be disabled in settings)'),
                _buildBullet('Deliver relevant content and recommendations (personalisation — can be disabled)'),
                const SizedBox(height: 8),
                _buildBody(
                  'You can manage cookie preferences in Settings → Data & Privacy at any time.',
                ),
              ],
            ),

            _buildSection(
              number: '8',
              title: 'Children\'s Privacy',
              icon: Icons.child_care,
              content: [
                _buildBody(
                  'EventEase is not intended for use by persons under 18 years of age. We do not knowingly collect personal information from minors. If we discover that a minor has provided us personal data without parental consent, we will delete it promptly. If you believe a child has provided us with personal data, please contact us immediately.',
                ),
              ],
            ),

            _buildSection(
              number: '9',
              title: 'Third-Party Links & Services',
              icon: Icons.open_in_new,
              content: [
                _buildBody(
                  'Our platform may contain links to third-party websites or integrate with third-party services (e.g., payment providers, map services). We are not responsible for the privacy practices of such third parties. We encourage you to review their privacy policies before providing any personal information.',
                ),
              ],
            ),

            _buildSection(
              number: '10',
              title: 'International Data Transfers',
              icon: Icons.public,
              content: [
                _buildBody(
                  'Your information is primarily stored and processed in Malaysia. Where we transfer data internationally (e.g., when using cloud services), we ensure appropriate safeguards are in place to protect your information consistent with Malaysian PDPA requirements.',
                ),
              ],
            ),

            _buildSection(
              number: '11',
              title: 'Changes to This Policy',
              icon: Icons.update,
              content: [
                _buildBody(
                  'We may update this Privacy Policy from time to time. We will notify you of significant changes via in-app notification or email at least 14 days before the change takes effect. Continued use of EventEase after the effective date constitutes your acceptance of the revised policy.',
                ),
              ],
            ),

            _buildSection(
              number: '12',
              title: 'Contact Us',
              icon: Icons.contact_mail,
              content: [
                _buildBody('For privacy-related questions, requests, or complaints, please contact our Data Protection Officer:'),
                const SizedBox(height: 12),
                _buildContactRow(Icons.email, 'privacy@eventease.com'),
                _buildContactRow(Icons.phone, '+60 3-1234 5678'),
                _buildContactRow(Icons.location_on, 'EventEase Sdn. Bhd., Level 15, Menara Kuala Lumpur,\nKuala Lumpur, 50250, Malaysia'),
                _buildContactRow(Icons.access_time, 'Monday – Friday, 9:00 AM – 6:00 PM (MYT)'),
              ],
            ),

            const SizedBox(height: 24),
            Container(
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
                      'By continuing to use EventEase, you acknowledge that you have read and understood this Privacy Policy.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondaryColor,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String number,
    required String title,
    required IconData icon,
    required List<Widget> content,
  }) {
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
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        number,
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(icon, color: AppTheme.primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 14),
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

  Widget _buildSubheading(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimaryColor,
        ),
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
}
