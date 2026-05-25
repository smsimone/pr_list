import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:pr_list/core/services/models/update_info.dart';

class UpdateService {
  static const _githubApi =
      'https://api.github.com/repos/smsimone/pr_list/releases/latest';
  final _logger = Logger('UpdateService');

  Future<UpdateInfo?> checkForUpdate({required String currentVersion}) async {
    try {
      _logger.info('Checking for update (current=$currentVersion)');
      final response = await http.get(
        Uri.parse(_githubApi),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'pr_list',
        },
      );
      if (response.statusCode != 200) {
        _logger.warning('GitHub API returned ${response.statusCode}');
        return null;
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final tagName = body['tag_name'] as String? ?? '';
      final latestVersion = tagName.replaceFirst(RegExp(r'^v'), '');

      if (latestVersion.isEmpty || !_isNewer(latestVersion, currentVersion)) {
        _logger.info('No update available ($currentVersion >= $latestVersion)');
        return null;
      }

      final assets = body['assets'] as List<dynamic>? ?? [];
      final platformPrefix = _platformAssetPrefix();
      final asset = _findAsset(assets, platformPrefix, latestVersion);
      if (asset == null) {
        _logger.warning('No asset found for prefix $platformPrefix');
        return null;
      }

      final downloadUrl = asset['browser_download_url'] as String? ?? '';
      if (downloadUrl.isEmpty) return null;

      _logger.info('Update available: v$latestVersion');
      return UpdateInfo(
        version: latestVersion,
        downloadUrl: downloadUrl,
        releaseNotesUrl: body['html_url'] as String? ?? '',
      );
    } catch (e) {
      _logger.warning('Update check failed: $e');
      return null;
    }
  }

  Future<File> downloadUpdate(
    UpdateInfo info,
    void Function(double) onProgress,
  ) async {
    _logger.info('Downloading update from ${info.downloadUrl}');
    final tmpDir = Directory.systemTemp;
    final dest = File(p.join(tmpDir.path, 'pr_list_update_${info.version}.zip'));
    final request = http.Request('GET', Uri.parse(info.downloadUrl));
    final response = await http.Client().send(request);
    final total = response.contentLength ?? 0;
    var received = 0;
    final sink = dest.openWrite();
    try {
      await for (final chunk in response.stream) {
        received += chunk.length;
        sink.add(chunk);
        if (total > 0) onProgress(received / total);
      }
      await sink.flush();
    } finally {
      await sink.close();
    }
    _logger.info('Downloaded $dest.path ($received bytes)');
    return dest;
  }

  Future<void> installUpdate(File zipFile, UpdateInfo info) async {
    final tmpDir = Directory.systemTemp;
    final extractDir = Directory(p.join(tmpDir.path, 'pr_list_$info.version'));
    if (extractDir.existsSync()) extractDir.deleteSync(recursive: true);
    extractDir.createSync();

    try {
      if (Platform.isWindows) {
        await _installWindows(zipFile, extractDir, tmpDir);
      } else if (Platform.isMacOS) {
        await _installMacOS(zipFile, extractDir, tmpDir);
      } else {
        throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
      }
    } catch (e) {
      _logger.severe('Install failed: $e');
      rethrow;
    }
  }

  Future<void> _installWindows(
    File zipFile,
    Directory extractDir,
    Directory tmpDir,
  ) async {
    final installDir = p.dirname(Platform.resolvedExecutable);
    final exePath = Platform.resolvedExecutable;

    await Process.run('powershell', [
      '-Command',
      'Expand-Archive',
      '-Path',
      zipFile.path,
      '-DestinationPath',
      extractDir.path,
      '-Force',
    ]);

    final updaterScript = '''
@echo off
setlocal
set "SRC=${extractDir.path}"
set "DST=$installDir"
set "EXE=$exePath"

:WAIT
timeout /T 2 /NOBREAK >NUL 2>&1
tasklist /FI "IMAGENAME eq pr_list.exe" 2>NUL | find /I "pr_list.exe" >NUL 2>&1
if not errorlevel 1 goto WAIT

xcopy /E /Y /Q "%SRC%\\*" "%DST%\\" >NUL 2>&1
if errorlevel 1 (
  rmdir /S /Q "%SRC%" 2>NUL
  exit /B 1
)
start "" /D "%DST%" "%EXE%"
rmdir /S /Q "%SRC%" 2>NUL
del "%~f0" 2>NUL
''';

    final scriptFile = File(p.join(tmpDir.path, 'pr_list_updater.bat'));
    scriptFile.writeAsStringSync(updaterScript);

    await Process.start(
      scriptFile.path,
      [],
      runInShell: true,
      mode: ProcessStartMode.detached,
    );
  }

  Future<void> _installMacOS(
    File zipFile,
    Directory extractDir,
    Directory tmpDir,
  ) async {
    final appBundle = Platform.resolvedExecutable;
    final appDir = p.dirname(p.dirname(p.dirname(appBundle)));

    await Process.run('unzip', [
      '-o',
      zipFile.path,
      '-d',
      extractDir.path,
    ]);

    final srcDir = extractDir.path;
    final dstDir = appDir;
    final appPath = appBundle;
    final updaterScript = '''
#!/bin/bash
SRC="$srcDir/pr_list.app"
DST="$dstDir"
APP="$appPath"

sleep 3

rm -rf "\$DST/pr_list.app"
cp -R "\$SRC" "\$DST/"
open "\$APP"

rm -rf "$extractDir"
rm -- "\$0"
''';

    final scriptFile = File(p.join(tmpDir.path, 'pr_list_updater.sh'));
    scriptFile.writeAsStringSync(updaterScript);
    await Process.run('chmod', ['+x', scriptFile.path]);

    await Process.start(
      scriptFile.path,
      [],
      runInShell: true,
      mode: ProcessStartMode.detached,
    );
  }

  Map<String, dynamic>? _findAsset(
    List<dynamic> assets,
    String prefix,
    String version,
  ) {
    for (final a in assets) {
      if (a is! Map) continue;
      final asset = Map<String, dynamic>.from(a);
      final name = asset['name'] as String? ?? '';
      if (name.startsWith(prefix) && name.contains(version)) return asset;
    }
    for (final a in assets) {
      if (a is! Map) continue;
      final asset = Map<String, dynamic>.from(a);
      final name = asset['name'] as String? ?? '';
      if (name.startsWith(prefix)) return asset;
    }
    return null;
  }

  String _platformAssetPrefix() {
    if (Platform.isWindows) return 'pr_list-windows-';
    if (Platform.isMacOS) return 'pr_list-macos-';
    throw UnsupportedError('Unsupported platform');
  }

  bool _isNewer(String latest, String current) {
    final latestParts = latest.split(RegExp(r'[\.+]'));
    final currentParts = current.split(RegExp(r'[\.+]'));
    final len = latestParts.length > currentParts.length
        ? latestParts.length
        : currentParts.length;
    for (var i = 0; i < len; i++) {
      final l =
          i < latestParts.length ? int.tryParse(latestParts[i]) ?? 0 : 0;
      final c = i < currentParts.length ? int.tryParse(currentParts[i]) ?? 0 : 0;
      if (l != c) return l > c;
    }
    return false;
  }
}
