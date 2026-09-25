import 'package:eventease/core/utils/app_theme.dart';
import 'package:flutter/material.dart';

class VendorThemeCustomizationScreen extends StatefulWidget {
  const VendorThemeCustomizationScreen({super.key});

  @override
  State<VendorThemeCustomizationScreen> createState() => _VendorThemeCustomizationScreenState();
}

class _VendorThemeCustomizationScreenState extends State<VendorThemeCustomizationScreen> {
  final List<Map<String, dynamic>> _predefinedThemes = [
    {
      'name': 'Classic Blue',
      'primaryColor': const Color(0xFF1976D2),
      'secondaryColor': const Color(0xFF42A5F5),
      'accentColor': const Color(0xFF1E88E5),
      'backgroundColor': Colors.white,
      'textColor': const Color(0xFF212121),
      'isSelected': true,
    },
    {
      'name': 'Elegant Purple',
      'primaryColor': const Color(0xFF7B1FA2),
      'secondaryColor': const Color(0xFFBA68C8),
      'accentColor': const Color(0xFF9C27B0),
      'backgroundColor': Colors.white,
      'textColor': const Color(0xFF212121),
      'isSelected': false,
    },
    {
      'name': 'Modern Green',
      'primaryColor': const Color(0xFF388E3C),
      'secondaryColor': const Color(0xFF66BB6A),
      'accentColor': const Color(0xFF4CAF50),
      'backgroundColor': Colors.white,
      'textColor': const Color(0xFF212121),
      'isSelected': false,
    },
    {
      'name': 'Warm Orange',
      'primaryColor': const Color(0xFFF57C00),
      'secondaryColor': const Color(0xFFFFB74D),
      'accentColor': const Color(0xFFFF9800),
      'backgroundColor': Colors.white,
      'textColor': const Color(0xFF212121),
      'isSelected': false,
    },
    {
      'name': 'Dark Theme',
      'primaryColor': const Color(0xFF212121),
      'secondaryColor': const Color(0xFF424242),
      'accentColor': const Color(0xFF757575),
      'backgroundColor': const Color(0xFF121212),
      'textColor': Colors.white,
      'isSelected': false,
    },
  ];

  final List<Map<String, dynamic>> _fonts = [
    {
      'name': 'Roboto',
      'family': 'Roboto',
      'isSelected': true,
      'preview': 'The quick brown fox jumps over the lazy dog',
    },
    {
      'name': 'Open Sans',
      'family': 'OpenSans',
      'isSelected': false,
      'preview': 'The quick brown fox jumps over the lazy dog',
    },
    {
      'name': 'Lato',
      'family': 'Lato',
      'isSelected': false,
      'preview': 'The quick brown fox jumps over the lazy dog',
    },
    {
      'name': 'Poppins',
      'family': 'Poppins',
      'isSelected': false,
      'preview': 'The quick brown fox jumps over the lazy dog',
    },
    {
      'name': 'Montserrat',
      'family': 'Montserrat',
      'isSelected': false,
      'preview': 'The quick brown fox jumps over the lazy dog',
    },
  ];

  final List<Map<String, dynamic>> _layouts = [
    {
      'name': 'Grid Layout',
      'description': 'Display services in a grid format',
      'icon': Icons.grid_view,
      'isSelected': true,
    },
    {
      'name': 'List Layout',
      'description': 'Display services in a vertical list',
      'icon': Icons.list,
      'isSelected': false,
    },
    {
      'name': 'Card Layout',
      'description': 'Display services as cards with images',
      'icon': Icons.view_module,
      'isSelected': false,
    },
    {
      'name': 'Compact Layout',
      'description': 'Space-efficient layout for mobile',
      'icon': Icons.view_compact,
      'isSelected': false,
    },
  ];

  String _selectedTab = 'Themes';

  Color _customPrimaryColor = const Color(0xFF1976D2);
  Color _customSecondaryColor = const Color(0xFF42A5F5);
  Color _customAccentColor = const Color(0xFF1E88E5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Theme Customization',
            style: TextStyle(
                color: AppTheme.textPrimaryColor, fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: _saveChanges,
            child: const Text('Save', style: TextStyle(color: AppTheme.primaryColor)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab selector
          _buildTabSelector(),

          // Content based on selected tab
          Expanded(
            child: _selectedTab == 'Themes'
                ? _buildThemesView()
                : _selectedTab == 'Colors'
                ? _buildColorsView()
                : _selectedTab == 'Fonts'
                ? _buildFontsView()
                : _buildLayoutsView(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildTabButton('Themes', _selectedTab == 'Themes'),
            const SizedBox(width: 8),
            _buildTabButton('Colors', _selectedTab == 'Colors'),
            const SizedBox(width: 8),
            _buildTabButton('Fonts', _selectedTab == 'Fonts'),
            const SizedBox(width: 8),
            _buildTabButton('Layout', _selectedTab == 'Layout'),
          ],
        ),
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

  Widget _buildThemesView() {
    return Column(
      children: [
        // Current theme preview
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Current Theme Preview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getCurrentTheme()['backgroundColor'],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    // Header
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getCurrentTheme()['primaryColor'],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'Header',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Content
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 60,
                            decoration: BoxDecoration(
                              color: _getCurrentTheme()['secondaryColor'],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                'Button',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            height: 60,
                            decoration: BoxDecoration(
                              color: _getCurrentTheme()['accentColor'],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                'Accent',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Predefined themes
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _predefinedThemes.length,
            itemBuilder: (context, index) =>
                _buildThemeCard(_predefinedThemes[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildThemeCard(Map<String, dynamic> theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme['isSelected'] ? AppTheme.primaryColor : Colors.grey.shade300,
          width: theme['isSelected'] ? 2 : 1,
        ),
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
              // Color palette
              Row(
                children: [
                  _buildColorSwatch(theme['primaryColor']),
                  const SizedBox(width: 4),
                  _buildColorSwatch(theme['secondaryColor']),
                  const SizedBox(width: 4),
                  _buildColorSwatch(theme['accentColor']),
                ],
              ),
              const SizedBox(width: 12),

              // Theme name
              Expanded(
                child: Text(
                  theme['name'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ),

              // Selection indicator
              if (theme['isSelected']) ...[
                const Icon(Icons.check_circle, color: AppTheme.primaryColor),
              ],
            ],
          ),

          const SizedBox(height: 12),

          // Action button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _selectTheme(theme),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme['isSelected'] ? AppTheme.primaryColor : Colors.grey.shade100,
                foregroundColor: theme['isSelected'] ? Colors.white : AppTheme.textPrimaryColor,
              ),
              child: Text(theme['isSelected'] ? 'Selected' : 'Select Theme'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorSwatch(Color color) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade300),
      ),
    );
  }

  Widget _buildColorsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Custom Colors',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),

          // Primary color
          _buildColorPicker(
            'Primary Color',
            _customPrimaryColor,
            (color) => setState(() => _customPrimaryColor = color),
          ),

          const SizedBox(height: 16),

          // Secondary color
          _buildColorPicker(
            'Secondary Color',
            _customSecondaryColor,
            (color) => setState(() => _customSecondaryColor = color),
          ),

          const SizedBox(height: 16),

          // Accent color
          _buildColorPicker(
            'Accent Color',
            _customAccentColor,
            (color) => setState(() => _customAccentColor = color),
          ),

          const SizedBox(height: 24),

          // Color presets
          const Text(
            'Color Presets',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildColorPreset(const Color(0xFF1976D2), 'Blue'),
              _buildColorPreset(const Color(0xFF388E3C), 'Green'),
              _buildColorPreset(const Color(0xFFF57C00), 'Orange'),
              _buildColorPreset(const Color(0xFF7B1FA2), 'Purple'),
              _buildColorPreset(const Color(0xFFD32F2F), 'Red'),
              _buildColorPreset(const Color(0xFF1976D2), 'Indigo'),
            ],
          ),

          const SizedBox(height: 24),

          // Preview
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
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
                  'Preview',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: _customPrimaryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text(
                            'Primary',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: _customSecondaryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text(
                            'Secondary',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: _customAccentColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text(
                            'Accent',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorPicker(String label, Color currentColor, Function(Color) onColorChanged) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: currentColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '#${currentColor.value.toRadixString(16).substring(2).toUpperCase()}',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _showColorPicker(currentColor, onColorChanged),
                child: const Text('Change'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColorPreset(Color color, String name) {
    return InkWell(
      onTap: () => setState(() => _customPrimaryColor = color),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Center(
          child: Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFontsView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _fonts.length,
      itemBuilder: (context, index) =>
          _buildFontCard(_fonts[index]),
    );
  }

  Widget _buildFontCard(Map<String, dynamic> font) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: font['isSelected'] ? AppTheme.primaryColor : Colors.grey.shade300,
          width: font['isSelected'] ? 2 : 1,
        ),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      font['name'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      font['preview'],
                      style: TextStyle(
                        fontFamily: font['family'],
                        fontSize: 14,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (font['isSelected']) ...[
                const Icon(Icons.check_circle, color: AppTheme.primaryColor),
              ],
            ],
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _selectFont(font),
              style: ElevatedButton.styleFrom(
                backgroundColor: font['isSelected'] ? AppTheme.primaryColor : Colors.grey.shade100,
                foregroundColor: font['isSelected'] ? Colors.white : AppTheme.textPrimaryColor,
              ),
              child: Text(font['isSelected'] ? 'Selected' : 'Select Font'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLayoutsView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _layouts.length,
      itemBuilder: (context, index) =>
          _buildLayoutCard(_layouts[index]),
    );
  }

  Widget _buildLayoutCard(Map<String, dynamic> layout) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: layout['isSelected'] ? AppTheme.primaryColor : Colors.grey.shade300,
          width: layout['isSelected'] ? 2 : 1,
        ),
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
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  layout['icon'],
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      layout['name'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      layout['description'],
                      style: const TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (layout['isSelected']) ...[
                const Icon(Icons.check_circle, color: AppTheme.primaryColor),
              ],
            ],
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _selectLayout(layout),
              style: ElevatedButton.styleFrom(
                backgroundColor: layout['isSelected'] ? AppTheme.primaryColor : Colors.grey.shade100,
                foregroundColor: layout['isSelected'] ? Colors.white : AppTheme.textPrimaryColor,
              ),
              child: Text(layout['isSelected'] ? 'Selected' : 'Select Layout'),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getCurrentTheme() {
    return _predefinedThemes.firstWhere((theme) => theme['isSelected']);
  }

  void _selectTheme(Map<String, dynamic> theme) {
    setState(() {
      for (var t in _predefinedThemes) {
        t['isSelected'] = false;
      }
      theme['isSelected'] = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${theme['name']} theme selected')),
    );
  }

  void _showColorPicker(Color currentColor, Function(Color) onColorChanged) {
    // In a real app, show a color picker dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Color picker would open here (placeholder)')),
    );
  }

  void _selectFont(Map<String, dynamic> font) {
    setState(() {
      for (var f in _fonts) {
        f['isSelected'] = false;
      }
      font['isSelected'] = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${font['name']} font selected')),
    );
  }

  void _selectLayout(Map<String, dynamic> layout) {
    setState(() {
      for (var l in _layouts) {
        l['isSelected'] = false;
      }
      layout['isSelected'] = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${layout['name']} layout selected')),
    );
  }

  void _saveChanges() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Theme changes saved successfully')),
    );
  }
}
