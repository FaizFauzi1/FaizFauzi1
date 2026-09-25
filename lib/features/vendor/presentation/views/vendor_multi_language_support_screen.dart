import 'package:eventease/core/utils/app_theme.dart';
import 'package:flutter/material.dart';

class VendorMultiLanguageSupportScreen extends StatefulWidget {
  const VendorMultiLanguageSupportScreen({super.key});

  @override
  State<VendorMultiLanguageSupportScreen> createState() => _VendorMultiLanguageSupportScreenState();
}

class _VendorMultiLanguageSupportScreenState extends State<VendorMultiLanguageSupportScreen> {
  final List<Map<String, dynamic>> _languages = [
    {
      'code': 'en',
      'name': 'English',
      'nativeName': 'English',
      'flag': '🇺🇸',
      'isEnabled': true,
      'isDefault': true,
      'completion': 100,
      'translatedStrings': 1250,
      'totalStrings': 1250,
    },
    {
      'code': 'ms',
      'name': 'Malay',
      'nativeName': 'Bahasa Melayu',
      'flag': '🇲🇾',
      'isEnabled': true,
      'isDefault': false,
      'completion': 95,
      'translatedStrings': 1188,
      'totalStrings': 1250,
    },
    {
      'code': 'zh',
      'name': 'Chinese',
      'nativeName': '中文',
      'flag': '🇨🇳',
      'isEnabled': true,
      'isDefault': false,
      'completion': 78,
      'translatedStrings': 975,
      'totalStrings': 1250,
    },
    {
      'code': 'hi',
      'name': 'Hindi',
      'nativeName': 'हिन्दी',
      'flag': '🇮🇳',
      'isEnabled': false,
      'isDefault': false,
      'completion': 45,
      'translatedStrings': 563,
      'totalStrings': 1250,
    },
    {
      'code': 'ar',
      'name': 'Arabic',
      'nativeName': 'العربية',
      'flag': '🇸🇦',
      'isEnabled': false,
      'isDefault': false,
      'completion': 32,
      'translatedStrings': 400,
      'totalStrings': 1250,
    },
    {
      'code': 'es',
      'name': 'Spanish',
      'nativeName': 'Español',
      'flag': '🇪🇸',
      'isEnabled': false,
      'isDefault': false,
      'completion': 67,
      'translatedStrings': 838,
      'totalStrings': 1250,
    },
  ];

  final List<Map<String, dynamic>> _contentSections = [
    {
      'name': 'Service Descriptions',
      'key': 'service_descriptions',
      'totalItems': 25,
      'translatedItems': {'en': 25, 'ms': 23, 'zh': 18, 'hi': 8, 'ar': 5, 'es': 15},
      'lastUpdated': '2024-03-15',
    },
    {
      'name': 'Terms & Conditions',
      'key': 'terms_conditions',
      'totalItems': 1,
      'translatedItems': {'en': 1, 'ms': 1, 'zh': 1, 'hi': 0, 'ar': 0, 'es': 1},
      'lastUpdated': '2024-03-10',
    },
    {
      'name': 'Privacy Policy',
      'key': 'privacy_policy',
      'totalItems': 1,
      'translatedItems': {'en': 1, 'ms': 1, 'zh': 1, 'hi': 0, 'ar': 0, 'es': 1},
      'lastUpdated': '2024-03-10',
    },
    {
      'name': 'Email Templates',
      'key': 'email_templates',
      'totalItems': 12,
      'translatedItems': {'en': 12, 'ms': 10, 'zh': 8, 'hi': 3, 'ar': 2, 'es': 8},
      'lastUpdated': '2024-03-12',
    },
    {
      'name': 'Notifications',
      'key': 'notifications',
      'totalItems': 35,
      'translatedItems': {'en': 35, 'ms': 32, 'zh': 25, 'hi': 12, 'ar': 8, 'es': 22},
      'lastUpdated': '2024-03-14',
    },
  ];

  String _selectedTab = 'Languages';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Multi-Language Support',
            style: TextStyle(
                color: AppTheme.textPrimaryColor, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.translate, color: AppTheme.primaryColor),
            onPressed: _autoTranslate,
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab selector
          _buildTabSelector(),

          // Content based on selected tab
          Expanded(
            child: _selectedTab == 'Languages'
                ? _buildLanguagesView()
                : _buildContentView(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton('Languages', _selectedTab == 'Languages'),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildTabButton('Content', _selectedTab == 'Content'),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, bool isSelected) {
    return ElevatedButton(
      onPressed: () => setState(() => _selectedTab = title),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? AppTheme.primaryColor : Colors.white,
        foregroundColor: isSelected ? Colors.white : AppTheme.textPrimaryColor,
        elevation: isSelected ? 2 : 0,
        side: BorderSide(
          color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
        ),
      ),
      child: Text(title),
    );
  }

  Widget _buildLanguagesView() {
    final enabledLanguages = _languages.where((lang) => lang['isEnabled']).length;
    final totalCompletion = _languages
        .where((lang) => lang['isEnabled'])
        .fold<double>(0, (sum, lang) => sum + lang['completion']) / enabledLanguages;

    return Column(
      children: [
        // Overview stats
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Enabled Languages',
                  enabledLanguages.toString(),
                  Icons.language,
                  AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Avg Completion',
                  '${totalCompletion.toStringAsFixed(1)}%',
                  Icons.translate,
                  AppTheme.successColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Total Strings',
                  '7,500',
                  Icons.text_fields,
                  AppTheme.accentColor,
                ),
              ),
            ],
          ),
        ),

        // Languages list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _languages.length,
            itemBuilder: (context, index) =>
                _buildLanguageCard(_languages[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageCard(Map<String, dynamic> language) {
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
      child: Column(
        children: [
          Row(
            children: [
              // Language flag and name
              Text(
                language['flag'],
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          language['name'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (language['isDefault']) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Default',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      language['nativeName'],
                      style: const TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              // Enable/Disable switch
              Switch(
                value: language['isEnabled'],
                onChanged: (value) => _toggleLanguage(language, value),
                activeColor: AppTheme.primaryColor,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Translation progress
          if (language['isEnabled']) ...[
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Translation Progress',
                      style: const TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${language['completion']}%',
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: language['completion'] / 100,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    language['completion'] == 100 ? AppTheme.successColor : AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${language['translatedStrings']}/${language['totalStrings']} strings translated',
                  style: const TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _editTranslations(language),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _exportLanguage(language),
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Export'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _importTranslations(language),
                    icon: const Icon(Icons.upload, size: 16),
                    label: const Text('Import'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContentView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _contentSections.length,
      itemBuilder: (context, index) =>
          _buildContentSectionCard(_contentSections[index]),
    );
  }

  Widget _buildContentSectionCard(Map<String, dynamic> section) {
    final enabledLanguages = _languages.where((lang) => lang['isEnabled']).toList();

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
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                section['name'],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              Text(
                'Last updated: ${section['lastUpdated']}',
                style: const TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Translation status for each language
          ...enabledLanguages.map((language) {
            final translated = section['translatedItems'][language['code']] ?? 0;
            final total = section['totalItems'];
            final completion = total > 0 ? (translated / total * 100).round() : 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 60,
                    child: Text(
                      language['code'].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: completion / 100,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        completion == 100 ? AppTheme.successColor : AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 40,
                    child: Text(
                      '$completion%',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryColor,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _editContentSection(section),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit Content'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _translateContentSection(section),
                  icon: const Icon(Icons.translate, size: 16),
                  label: const Text('Auto Translate'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _toggleLanguage(Map<String, dynamic> language, bool enabled) {
    setState(() {
      language['isEnabled'] = enabled;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${language['name']} ${enabled ? 'enabled' : 'disabled'}')),
    );
  }

  void _editTranslations(Map<String, dynamic> language) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit translations for ${language['name']} (placeholder)')),
    );
  }

  void _exportLanguage(Map<String, dynamic> language) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Export ${language['name']} translations (placeholder)')),
    );
  }

  void _importTranslations(Map<String, dynamic> language) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Import translations for ${language['name']} (placeholder)')),
    );
  }

  void _autoTranslate() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Auto translating missing strings (placeholder)')),
    );
  }

  void _editContentSection(Map<String, dynamic> section) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit ${section['name']} content (placeholder)')),
    );
  }

  void _translateContentSection(Map<String, dynamic> section) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Auto translate ${section['name']} (placeholder)')),
    );
  }
}
