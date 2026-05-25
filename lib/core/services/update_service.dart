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
    final ext = Platform.isWindows ? '.exe' : '.zip';
    final dest = File(p.join(tmpDir.path, 'pr_list_update_${info.version}$ext'));
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

  Future<void> installUpdate(File downloadedFile, UpdateInfo info) async {
    try {
      if (Platform.isWindows) {
        await _installWindows(downloadedFile);
      } else if (Platform.isMacOS) {
        await _installMacOS(downloadedFile);
      } else {
        throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
      }
    } catch (e) {
      _logger.severe('Install failed: $e');
      rethrow;
    }
  }

  Future<void> _installWindows(File installerExe) async {
    final tmpDir = Directory.systemTemp;
    final appName = 'PR List';
    final appExe = 'pr_list.exe';
    final scriptContent = '''
@echo off
ping -n 6 127.0.0.1 > nul
"${installerExe.path}" /VERYSILENT /SUPPRESSMSGBOXES /NORESTART
start "" "%LOCALAPPDATA%\\$appName\\$appExe"
del "${installerExe.path}" /q
del "%~f0" /q
''';
    final scriptFile = File(p.join(tmpDir.path, 'pr_list_updater.bat'));
    scriptFile.writeAsStringSync(scriptContent);
    _logger.info('Running updater script: ${scriptFile.path}');
    await Process.start(
      scriptFile.path,
      [],
      runInShell: true,
      mode: ProcessStartMode.detached,
    );
  }

  Future<void> _installMacOS(File zipFile) async {
    final tmpDir = Directory.systemTemp;
    final extractDir = Directory(p.join(tmpDir.path, 'pr_list_extract'));
    if (extractDir.existsSync()) extractDir.deleteSync(recursive: true);
    extractDir.createSync();

    final appBundle = Platform.resolvedExecutable;
    final appDir = p.dirname(p.dirname(p.dirname(appBundle)));

    await Process.run('unzip', [
      '-o',
      zipFile.path,
      '-d',
      extractDir.path,
    ]);

    final updaterScript = '''
#!/bin/bash
SRC="${extractDir.path}/pr_list.app"
DST="$appDir"

sleep 3

rm -rf "\$DST/pr_list.app"
cp -R "\$SRC" "\$DST/"

rm -rf "${extractDir.path}"
open "\$DST/pr_list.app"
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
    if (Platform.isWindows) return 'pr_list-setup-';
    if (Platform.isMacOS) return 'pr_list-macos-';
    throw UnsupportedError('Unsupported platform');
  }

  bool _isNewer(String latest, String current) {
    latest = latest.split('+')[0];
    current = current.split('+')[0];
    final latestParts = latest.split('.');
    final currentParts = current.split('.');
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
