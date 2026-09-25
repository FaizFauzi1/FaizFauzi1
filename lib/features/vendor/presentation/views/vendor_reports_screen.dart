import 'package:eventease/core/utils/app_theme.dart';
import 'package:flutter/material.dart';

class VendorReportsScreen extends StatefulWidget {
  const VendorReportsScreen({super.key});

  @override
  State<VendorReportsScreen> createState() => _VendorReportsScreenState();
}

class _VendorReportsScreenState extends State<VendorReportsScreen> {
  final List<Map<String, dynamic>> _reportTemplates = [
    {
      'name': 'Sales Report',
      'description': 'Comprehensive sales performance report',
      'icon': Icons.attach_money,
      'color': AppTheme.successColor,
      'lastGenerated': '2024-03-10',
      'frequency': 'Weekly',
    },
    {
      'name': 'Booking Report',
      'description': 'Detailed booking analytics and trends',
      'icon': Icons.book_online,
      'color': AppTheme.primaryColor,
      'lastGenerated': '2024-03-08',
      'frequency': 'Daily',
    },
    {
      'name': 'Customer Report',
      'description': 'Customer behavior and demographics analysis',
      'icon': Icons.people,
      'color': AppTheme.secondaryColor,
      'lastGenerated': '2024-03-05',
      'frequency': 'Monthly',
    },
    {
      'name': 'Financial Report',
      'description': 'Revenue, expenses, and profit analysis',
      'icon': Icons.account_balance,
      'color': AppTheme.accentColor,
      'lastGenerated': '2024-03-01',
      'frequency': 'Monthly',
    },
    {
      'name': 'Service Performance',
      'description': 'Individual service performance metrics',
      'icon': Icons.analytics,
      'color': Colors.purple,
      'lastGenerated': '2024-03-07',
      'frequency': 'Weekly',
    },
  ];

  final List<Map<String, dynamic>> _generatedReports = [];

  final List<Map<String, dynamic>> _scheduledReports = [];

  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedReportType = 'Sales Report';
  String _selectedFormat = 'PDF';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Reports & Analytics',
            style: TextStyle(
                color: AppTheme.textPrimaryColor, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick generate section
            _buildQuickGenerateSection(),
            const SizedBox(height: 24),

            // Report templates
            const Text(
              'Report Templates',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),
            ..._reportTemplates.map((template) => _buildReportTemplateCard(template)).toList(),
            const SizedBox(height: 24),

            // Generated reports
            _buildGeneratedReportsSection(),
            const SizedBox(height: 24),

            // Scheduled reports
            _buildScheduledReportsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickGenerateSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Generate Custom Report',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedReportType,
                  items: _reportTemplates.map<DropdownMenuItem<String>>((template) {
                    return DropdownMenuItem<String>(
                      value: template['name'],
                      child: Text(template['name']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedReportType = value!);
                  },
                  decoration: const InputDecoration(
                    labelText: 'Report Type',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedFormat,
                  items: const [
                    DropdownMenuItem(value: 'PDF', child: Text('PDF')),
                    DropdownMenuItem(value: 'Excel', child: Text('Excel')),
                    DropdownMenuItem(value: 'CSV', child: Text('CSV')),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedFormat = value!);
                  },
                  decoration: const InputDecoration(
                    labelText: 'Format',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().subtract(const Duration(days: 30)),
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => _startDate = picked);
                    }
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: Text(_startDate == null ? 'Start Date' : _startDate!.toString().split(' ')[0]),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: _startDate ?? DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => _endDate = picked);
                    }
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: Text(_endDate == null ? 'End Date' : _endDate!.toString().split(' ')[0]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _generateReport,
              icon: const Icon(Icons.file_download),
              label: const Text('Generate Report'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportTemplateCard(Map<String, dynamic> template) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: template['color'].withOpacity(0.1),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Icon(
              template['icon'],
              color: template['color'],
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  template['name'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  template['description'],
                  style: const TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Last: ${template['lastGenerated']}',
                      style: const TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        template['frequency'],
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _generateTemplateReport(template),
            icon: const Icon(Icons.play_arrow),
            color: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratedReportsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Generated Reports',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            TextButton(
              onPressed: () {
                // View all reports
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ..._generatedReports.take(3).map((report) => _buildGeneratedReportCard(report)).toList(),
      ],
    );
  }

  Widget _buildGeneratedReportCard(Map<String, dynamic> report) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              report['format'] == 'PDF' ? Icons.picture_as_pdf :
              report['format'] == 'Excel' ? Icons.table_chart : Icons.file_present,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report['name'],
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${report['generatedDate']} • ${report['size']}',
                  style: const TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Ready',
              style: TextStyle(
                color: Colors.green,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _downloadReport(report),
            icon: const Icon(Icons.download),
            color: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildScheduledReportsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Scheduled Reports',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            TextButton(
              onPressed: _showScheduleReportDialog,
              child: const Text('Schedule New'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ..._scheduledReports.map((report) => _buildScheduledReportCard(report)).toList(),
      ],
    );
  }

  Widget _buildScheduledReportCard(Map<String, dynamic> report) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report['name'],
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${report['frequency']} • Next: ${report['nextRun']}',
                  style: const TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Recipients: ${report['recipients'].length}',
                  style: const TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: report['active'],
            onChanged: (value) {
              setState(() => report['active'] = value);
            },
            activeColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  void _generateReport() {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date range')),
      );
      return;
    }

    // Simulate report generation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Generating $_selectedReportType report...')),
    );

    // In real app, this would trigger report generation
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _generatedReports.insert(0, {
          'name': '$_selectedReportType - ${DateTime.now().toString().split(' ')[0]}',
          'type': _selectedReportType,
          'generatedDate': DateTime.now().toString(),
          'size': '1.5 MB',
          'format': _selectedFormat,
          'status': 'Ready',
        });
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report generated successfully!')),
      );
    });
  }

  void _generateTemplateReport(Map<String, dynamic> template) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Generating ${template['name']}...')),
    );

    // Simulate report generation
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _generatedReports.insert(0, {
          'name': '${template['name']} - ${DateTime.now().toString().split(' ')[0]}',
          'type': template['name'],
          'generatedDate': DateTime.now().toString(),
          'size': '2.1 MB',
          'format': 'PDF',
          'status': 'Ready',
        });
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report generated successfully!')),
      );
    });
  }

  void _downloadReport(Map<String, dynamic> report) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Downloading ${report['name']}...')),
    );
    // In real app, this would trigger download
  }

  void _showScheduleReportDialog() {
    String selectedType = 'Sales Report';
    String selectedFrequency = 'Weekly';
    List<String> recipients = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Schedule Report'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedType,
                  items: _reportTemplates.map<DropdownMenuItem<String>>((template) {
                    return DropdownMenuItem<String>(
                      value: template['name'],
                      child: Text(template['name']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => selectedType = value!);
                  },
                  decoration: const InputDecoration(labelText: 'Report Type'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedFrequency,
                  items: const [
                    DropdownMenuItem(value: 'Daily', child: Text('Daily')),
                    DropdownMenuItem(value: 'Weekly', child: Text('Weekly')),
                    DropdownMenuItem(value: 'Monthly', child: Text('Monthly')),
                  ],
                  onChanged: (value) {
                    setState(() => selectedFrequency = value!);
                  },
                  decoration: const InputDecoration(labelText: 'Frequency'),
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Recipients (comma separated)',
                    hintText: 'email1@example.com, email2@example.com',
                  ),
                  onChanged: (value) {
                    recipients = value.split(',').map((e) => e.trim()).toList();
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (recipients.isNotEmpty) {
                  setState(() {
                    _scheduledReports.add({
                      'name': '$selectedType Report',
                      'type': selectedType,
                      'frequency': selectedFrequency,
                      'nextRun': DateTime.now().add(const Duration(days: 7)).toString().split(' ')[0],
                      'recipients': recipients,
                      'active': true,
                    });
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Report scheduled successfully')),
                  );
                }
              },
              child: const Text('Schedule'),
            ),
          ],
        ),
      ),
    );
  }
}
