import 'dart:io';

void main() {
  final libDir = Directory('lib');
  final importLine = "import 'package:out_tracker/theme/app_theme.dart';";

  for (var entity in libDir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart') && !entity.path.contains('app_theme.dart')) {
      String content = entity.readAsStringSync();
      
      bool changed = false;
      
      if (content.contains('Color(0xFF006D5B)')) {
        content = content.replaceAll('const Color(0xFF006D5B)', 'AppTheme.primaryColor');
        content = content.replaceAll('Color(0xFF006D5B)', 'AppTheme.primaryColor');
        changed = true;
      }
      
      if (content.contains('Color(0xFF138D75)')) {
        content = content.replaceAll('const Color(0xFF138D75)', 'AppTheme.secondaryColor');
        content = content.replaceAll('Color(0xFF138D75)', 'AppTheme.secondaryColor');
        changed = true;
      }
      
      if (changed) {
        if (!content.contains("package:out_tracker/theme/app_theme.dart")) {
           int lastImportIndex = content.lastIndexOf("import ");
           if (lastImportIndex != -1) {
             int endOfImport = content.indexOf('\n', lastImportIndex);
             content = content.substring(0, endOfImport + 1) + importLine + '\n' + content.substring(endOfImport + 1);
           } else {
             content = importLine + '\n\n' + content;
           }
        }
        entity.writeAsStringSync(content);
        print('Updated: ${entity.path}');
      }
    }
  }
}
