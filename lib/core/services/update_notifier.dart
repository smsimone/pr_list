import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pr_list/core/di/injection_container.dart';
import 'package:pr_list/core/services/models/update_info.dart';
import 'package:pr_list/core/services/update_service.dart';

enum UpdateStateStatus { idle, checking, available, downloading, installing, error }

class UpdateState {
  final UpdateStateStatus status;
  final UpdateInfo? info;
  final double progress;
  final String? errorMessage;

  const UpdateState({
    required this.status,
    this.info,
    this.progress = 0,
    this.errorMessage,
  });

  const UpdateState.idle()
      : status = UpdateStateStatus.idle,
        info = null,
        progress = 0,
        errorMessage = null;

  UpdateState copyWith({
    UpdateStateStatus? status,
    UpdateInfo? info,
    double? progress,
    String? errorMessage,
  }) {
    return UpdateState(
      status: status ?? this.status,
      info: info ?? this.info,
      progress: progress ?? this.progress,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

final updateStateProvider =
    StateNotifierProvider<UpdateNotifier, UpdateState>((ref) {
  return UpdateNotifier(getIt<UpdateService>());
});

class UpdateNotifier extends StateNotifier<UpdateState> {
  final UpdateService _service;
  final _logger = Logger('UpdateNotifier');
  bool _checkDone = false;

  UpdateNotifier(this._service) : super(const UpdateState.idle());

  Future<void> checkForUpdate() async {
    if (_checkDone) return;
    _checkDone = true;
    state = state.copyWith(status: UpdateStateStatus.checking);
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final info = await _service.checkForUpdate(currentVersion: currentVersion);
      if (info != null) {
        _logger.info('Update available: v${info.version}');
        state = UpdateState(
          status: UpdateStateStatus.available,
          info: info,
        );
      } else {
        _logger.info('No update available');
        state = const UpdateState.idle();
      }
    } catch (e) {
      _logger.warning('Update check error: $e');
      state = const UpdateState.idle();
    }
  }

  Future<void> downloadAndInstall() async {
    final info = state.info;
    if (info == null) return;

    state = state.copyWith(status: UpdateStateStatus.downloading, progress: 0);

    try {
      final file = await _service.downloadUpdate(info, (progress) {
        state = state.copyWith(progress: progress);
      });

      state = state.copyWith(status: UpdateStateStatus.installing);
      _logger.info('Installing update v${info.version}');

      await _service.installUpdate(file, info);
      await Future.delayed(const Duration(milliseconds: 500));
      exit(0);
    } catch (e) {
      _logger.severe('Update failed: $e');
      state = state.copyWith(
        status: UpdateStateStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void dismiss() {
    state = const UpdateState.idle();
  }
}
