import 'package:flutter/material.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:file_picker/file_picker.dart';

class ComplianceStep extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function(Map<String, dynamic>) onChanged;
  final Future<String?> Function(String fieldName) onUploadFile; // Callback to handle upload

  const ComplianceStep({
    super.key,
    required this.data,
    required this.onChanged,
    required this.onUploadFile,
  });

  @override
  State<ComplianceStep> createState() => _ComplianceStepState();
}

class _ComplianceStepState extends State<ComplianceStep> {
  // URLs
  String? _icUrl;
  String? _ssmUrl;
  String? _bankUrl;
  String? _insuranceUrl;
  String? _halalUrl;
  
  bool _agreedTerms = false;
  bool _agreedSla = false;

  @override
  void initState() {
    super.initState();
    _icUrl = widget.data['ic_upload_url'];
    _ssmUrl = widget.data['ssm_cert_url'];
    _bankUrl = widget.data['bank_statement_url'];
    _insuranceUrl = widget.data['insurance_policy_url'];
    _halalUrl = widget.data['halal_cert_url'];
    
    _agreedTerms = widget.data['agreed_to_terms'] ?? false;
    _agreedSla = widget.data['agreed_to_sla'] ?? false;
  }

  void _updateParent() {
    widget.onChanged({
      'ic_upload_url': _icUrl,
      'ssm_cert_url': _ssmUrl,
      'bank_statement_url': _bankUrl,
      'insurance_policy_url': _insuranceUrl,
      'halal_cert_url': _halalUrl,
      'agreed_to_terms': _agreedTerms,
      'agreed_to_sla': _agreedSla,
    });
  }

  Future<void> _pickAndUpload(String field, Function(String) onUrlSet) async {
    final url = await widget.onUploadFile(field);
    if (url != null) {
      setState(() {
        onUrlSet(url);
      });
      _updateParent();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Compliance & Trust',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Upload required documents for verification',
            style: TextStyle(color: AppTheme.textSecondaryColor),
          ),
          const SizedBox(height: 24),

          _buildSectionHeader('Required Documents'),
          _buildUploadTile('IC / MyKad (Front & Back)', _icUrl, (val) => _icUrl = val, field: 'ic_upload'),
          _buildUploadTile('SSM Certificate (Full Set)', _ssmUrl, (val) => _ssmUrl = val, field: 'ssm_cert'),
          _buildUploadTile('Bank Statement (Header Only)', _bankUrl, (val) => _bankUrl = val, field: 'bank_statement'),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Optional / Specific'),
          _buildUploadTile('Public Liability Insurance', _insuranceUrl, (val) => _insuranceUrl = val, field: 'insurance_policy'),
          _buildUploadTile('Halal Certificate', _halalUrl, (val) => _halalUrl = val, field: 'halal_cert'),

          const SizedBox(height: 32),
          _buildSectionHeader('Agreements'),
          CheckboxListTile(
              title: const Text('I agree to the Terms & Conditions'),
              subtitle: const Text('I confirm all information provided is accurate.'),
              value: _agreedTerms,
              onChanged: (val) {
                  setState(() => _agreedTerms = val!);
                  _updateParent();
              },
              activeColor: AppTheme.primaryColor,
          ),
          CheckboxListTile(
              title: const Text('I agree to the Service Level Agreement (SLA)'),
              value: _agreedSla,
              onChanged: (val) {
                  setState(() => _agreedSla = val!);
                  _updateParent();
              },
              activeColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildUploadTile(String label, String? currentUrl, Function(String) onSet, {required String field}) {
      final isUploaded = currentUrl != null && currentUrl.isNotEmpty;
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
            color: isUploaded ? Colors.green.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isUploaded ? Colors.green : Colors.grey.shade300),
        ),
        child: ListTile(
            leading: Icon(
                isUploaded ? Icons.verified : Icons.upload_file, 
                color: isUploaded ? Colors.green : Colors.grey
            ),
            title: Text(label),
            subtitle: Text(isUploaded ? 'Uploaded' : 'Tap to upload'),
            trailing: isUploaded 
                ? IconButton(icon: const Icon(Icons.close), onPressed: () {
                    // Logic to clear
                    setState(() {
                         onSet('');
                    });
                    _updateParent();
                }) 
                : const Icon(Icons.chevron_right),
            onTap: () {
                _pickAndUpload(field, onSet);
            },
        ),
      );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const Divider(),
        ],
      ),
    );
  }
}
