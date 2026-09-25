import 'dart:io';

void main() {
  final path = 'lib/features/admin/data/providers/admin_provider.dart';
  final file = File(path);
  if (!file.existsSync()) {
    print('File not found: $path');
    return;
  }
  
  final content = file.readAsStringSync();
  // Using regex with multiline support to replace the calls inside finally blocks
  // but being careful not to replace them twice if someone already added await
  final updatedContent = content
      .replaceAll(RegExp(r'(?<!await\s+)_loadVendors\(\);'), 'await _loadVendors();')
      .replaceAll(RegExp(r'(?<!await\s+)_loadUsers\(\);'), 'await _loadUsers();');
  
  if (content != updatedContent) {
    file.writeAsStringSync(updatedContent);
    print('Updated successfully');
  } else {
    print('No changes needed or matching lines found');
  }
}
