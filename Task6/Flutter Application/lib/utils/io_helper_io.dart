import 'dart:io';

Future<bool> databaseFileExists(String path) => File(path).exists();

Future<void> writeDatabaseFile(String path, List<int> bytes) =>
    File(path).writeAsBytes(bytes, flush: true);

bool get isDesktopPlatform =>
    Platform.isWindows || Platform.isLinux || Platform.isMacOS;
