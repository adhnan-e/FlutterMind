import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';

class DownloadService extends ChangeNotifier {
  static const String modelUrl = 
      "https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm";
  static const String modelFileName = "gemma-4-E2B-it.litertlm";

  bool _isDownloading = false;
  double _progress = 0.0;
  String _downloadSpeed = "0 KB/s";
  String _downloadedSize = "0 MB / 0 MB";
  String? _error;
  bool _isModelDownloaded = false;
  String _localModelPath = "";

  // Getters
  bool get isDownloading => _isDownloading;
  double get progress => _progress;
  String get downloadSpeed => _downloadSpeed;
  String get downloadedSize => _downloadedSize;
  String? get error => _error;
  bool get isModelDownloaded => _isModelDownloaded;
  String get localModelPath => _localModelPath;

  final Dio _dio = Dio();
  CancelToken? _cancelToken;

  DownloadService() {
    checkModelStatus();
  }

  Future<void> checkModelStatus() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      _localModelPath = "${directory.path}/$modelFileName";
      final file = File(_localModelPath);
      _isModelDownloaded = await file.exists();
      if (_isModelDownloaded) {
        // Also verify file is not empty (a failed download could leave an empty file)
        final length = await file.length();
        if (length < 1000 * 1020) { // Should be ~2.5GB, so < 1MB is likely a corrupt file
          _isModelDownloaded = false;
          await file.delete();
        }
      }
      notifyListeners();
    } catch (e) {
      _error = "Error checking model status: $e";
      notifyListeners();
    }
  }

  Future<void> startDownload() async {
    if (_isDownloading) return;

    _isDownloading = true;
    _progress = 0.0;
    _error = null;
    _cancelToken = CancelToken();
    notifyListeners();

    try {
      final directory = await getApplicationDocumentsDirectory();
      _localModelPath = "${directory.path}/$modelFileName";
      
      // Temporary file to download to, prevents corrupting existing status
      final tempPath = "$_localModelPath.tmp";
      final tempFile = File(tempPath);
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      DateTime startTime = DateTime.now();
      int lastBytes = 0;

      await _dio.download(
        modelUrl,
        tempPath,
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            _progress = received / total;
            
            // Calculate speed
            final now = DateTime.now();
            final elapsedMs = now.difference(startTime).inMilliseconds;
            if (elapsedMs > 500) {
              final bytesDelta = received - lastBytes;
              final speedBytesPerSec = (bytesDelta / (elapsedMs / 1000)).round();
              
              if (speedBytesPerSec > 1024 * 1024) {
                _downloadSpeed = "${(speedBytesPerSec / (1024 * 1024)).toStringAsFixed(1)} MB/s";
              } else {
                _downloadSpeed = "${(speedBytesPerSec / 1024).toStringAsFixed(0)} KB/s";
              }
              
              startTime = now;
              lastBytes = received;
            }

            final receivedMb = (received / (1024 * 1024)).toStringAsFixed(1);
            final totalMb = (total / (1024 * 1024)).toStringAsFixed(0);
            _downloadedSize = "$receivedMb MB / $totalMb MB";
            notifyListeners();
          }
        },
      );

      // Rename temp file to final file
      final finalFile = File(_localModelPath);
      if (await finalFile.exists()) {
        await finalFile.delete();
      }
      await File(tempPath).rename(_localModelPath);

      _isModelDownloaded = true;
      _isDownloading = false;
      logDebug("Model download completed successfully!");
      notifyListeners();
    } catch (e) {
      _isDownloading = false;
      if (CancelToken.isCancel(e as DioException)) {
        _error = "Download cancelled.";
      } else {
        _error = "Download failed: ${e.toString()}";
      }
      notifyListeners();
    }
  }

  void cancelDownload() {
    if (_isDownloading) {
      _cancelToken?.cancel();
      _isDownloading = false;
      notifyListeners();
    }
  }

  Future<void> deleteModel() async {
    try {
      final file = File(_localModelPath);
      if (await file.exists()) {
        await file.delete();
      }
      _isModelDownloaded = false;
      notifyListeners();
    } catch (e) {
      _error = "Failed to delete model: $e";
      notifyListeners();
    }
  }

  void logDebug(String msg) {
    if (kDebugMode) {
      print("[DownloadService] $msg");
    }
  }
}
