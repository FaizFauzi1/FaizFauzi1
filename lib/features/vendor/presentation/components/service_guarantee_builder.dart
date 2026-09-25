import 'package:flutter/material.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/shared/models/services/service_guarantee.dart';

class ServiceGuaranteeBuilder extends StatefulWidget {
  final ServiceGuarantee? initialGuarantee;
  final ValueChanged<ServiceGuarantee> onChanged;

  const ServiceGuaranteeBuilder({
    super.key,
    this.initialGuarantee,
    required this.onChanged,
  });

  @override
  State<ServiceGuaranteeBuilder> createState() => _ServiceGuaranteeBuilderState();
}

class _ServiceGuaranteeBuilderState extends State<ServiceGuaranteeBuilder> {
  late ServiceGuarantee _guarantee;

  @override
  void initState() {
    super.initState();
    _guarantee = widget.initialGuarantee?.copyWith() ?? ServiceGuarantee();
  }

  void _updateGuarantee(ServiceGuarantee updated) {
    setState(() {
      _guarantee = updated;
    });
    widget.onChanged(_guarantee);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF10B981), const Color(0xFF059669)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified_user, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Service Guarantee',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Build customer trust by clearly stating your guarantees and backup plans.',
                      style: TextStyle(fontSize: 13, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // --- Satisfaction Guarantee ---
        _buildSectionCard(
          title: '✅ Satisfaction Guarantee',
          subtitle: 'Do you guarantee customer satisfaction?',
          child: Column(
            children: [
              _buildToggleRow(
                label: 'Offer Satisfaction Guarantee',
                value: _guarantee.hasSatisfactionGuarantee,
                onChanged: (v) => _updateGuarantee(_guarantee.copyWith(hasSatisfactionGuarantee: v)),
              ),
              if (_guarantee.hasSatisfactionGuarantee) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: Color(0xFF10B981)),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'A satisfaction guarantee badge will be shown on your service listing.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF10B981)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        // --- Refund Policy ---
        _buildSectionCard(
          title: '💰 Refund Policy',
          subtitle: 'What refund do customers get if they cancel?',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...RefundPolicyType.values.map((policy) => RadioListTile<RefundPolicyType>(
                value: policy,
                groupValue: _guarantee.refundPolicy,
                onChanged: (v) => _updateGuarantee(_guarantee.copyWith(refundPolicy: v!)),
                title: Text(policy.displayName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                subtitle: Text(policy.description, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
                dense: true,
                activeColor: AppTheme.primaryColor,
                contentPadding: EdgeInsets.zero,
              )),
              if (_guarantee.refundPolicy != RefundPolicyType.noRefund) ...[
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: _guarantee.refundConditions,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Refund Conditions',
                    hintText: 'e.g. 50% refund if cancelled 30+ days before event',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: AppTheme.backgroundColor,
                  ),
                  onChanged: (v) => _updateGuarantee(_guarantee.copyWith(refundConditions: v)),
                ),
              ],
            ],
          ),
        ),

        // --- Backup Plan ---
        _buildSectionCard(
          title: '🛡️ Backup Plan',
          subtitle: 'Do you have contingency arrangements if something goes wrong?',
          child: Column(
            children: [
              _buildToggleRow(
                label: 'We provide a backup arrangement',
                value: _guarantee.hasBackupPlan,
                onChanged: (v) => _updateGuarantee(_guarantee.copyWith(hasBackupPlan: v)),
              ),
              if (_guarantee.hasBackupPlan) ...[
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: _guarantee.backupPlanDescription,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Describe Your Backup Plan',
                    hintText: 'e.g. We have a backup caterer on standby. If our team is unavailable, we will coordinate a replacement.',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: AppTheme.backgroundColor,
                  ),
                  onChanged: (v) => _updateGuarantee(_guarantee.copyWith(backupPlanDescription: v)),
                ),
              ],
            ],
          ),
        ),

        // --- SLA / Response Time ---
        _buildSectionCard(
          title: '⚡ Response Time SLA',
          subtitle: 'How fast do you respond to customer enquiries?',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Maximum Response Time', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [null, 1, 4, 12, 24, 48].map((hours) {
                  final isSelected = _guarantee.slaResponseHours == hours;
                  final label = hours == null
                      ? 'Not specified'
                      : hours == 1
                          ? '< 1 hour'
                          : hours < 24
                              ? '< $hours hours'
                              : '< ${hours ~/ 24} day${hours ~/ 24 > 1 ? 's' : ''}';
                  return GestureDetector(
                    onTap: () => _updateGuarantee(_guarantee.copyWith(slaResponseHours: hours)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryColor : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        // --- Certification ---
        _buildSectionCard(
          title: '🏅 Certification / Accreditation',
          subtitle: 'Are you certified or accredited by any body?',
          child: Column(
            children: [
              _buildToggleRow(
                label: 'We hold quality certification',
                value: _guarantee.isCertifiedQuality,
                onChanged: (v) => _updateGuarantee(_guarantee.copyWith(isCertifiedQuality: v)),
              ),
              if (_guarantee.isCertifiedQuality) ...[
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: _guarantee.certificationName,
                  decoration: InputDecoration(
                    labelText: 'Certification Name',
                    hintText: 'e.g. MOTAC Certified, ISO 9001, PEKA',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: AppTheme.backgroundColor,
                  ),
                  onChanged: (v) => _updateGuarantee(_guarantee.copyWith(certificationName: v)),
                ),
              ],
            ],
          ),
        ),

        // --- Custom Terms ---
        _buildSectionCard(
          title: '📋 Additional Terms',
          subtitle: 'Any other commitments you want to communicate?',
          child: TextFormField(
            initialValue: _guarantee.customTerms,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'e.g. All our food is halal certified. We guarantee your setup will be completed 2 hours before event time.',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              filled: true,
              fillColor: AppTheme.backgroundColor,
            ),
            onChanged: (v) => _updateGuarantee(_guarantee.copyWith(customTerms: v)),
          ),
        ),

        const SizedBox(height: 24),

        // Preview card
        if (_guarantee.hasAnyGuarantee) _buildGuaranteePreview(_guarantee),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildToggleRow({required String label, required bool value, required ValueChanged<bool> onChanged}) {
    return Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
        Switch(value: value, onChanged: onChanged, activeColor: AppTheme.primaryColor),
      ],
    );
  }

  Widget _buildGuaranteePreview(ServiceGuarantee guarantee) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF10B981).withOpacity(0.08), const Color(0xFF6366F1).withOpacity(0.08)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.visibility, size: 16, color: AppTheme.textSecondaryColor),
              SizedBox(width: 6),
              Text('Customer Preview', style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (guarantee.hasSatisfactionGuarantee) _guaranteeChip(Icons.thumb_up, 'Satisfaction Guaranteed', const Color(0xFF10B981)),
              if (guarantee.refundPolicy == RefundPolicyType.fullRefund) _guaranteeChip(Icons.refresh, 'Full Refund Policy', const Color(0xFF6366F1)),
              if (guarantee.refundPolicy == RefundPolicyType.partialRefund) _guaranteeChip(Icons.refresh, 'Partial Refund Policy', const Color(0xFF8B5CF6)),
              if (guarantee.hasBackupPlan) _guaranteeChip(Icons.security, 'Backup Plan Provided', const Color(0xFFF59E0B)),
              if (guarantee.slaResponseHours != null) _guaranteeChip(Icons.bolt, 'Responds < ${guarantee.slaResponseHours}h', const Color(0xFF0EA5E9)),
              if (guarantee.isCertifiedQuality) _guaranteeChip(Icons.verified, guarantee.certificationName ?? 'Certified', const Color(0xFFEC4899)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _guaranteeChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
