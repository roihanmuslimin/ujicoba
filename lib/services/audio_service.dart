import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

enum AudioState { stopped, playing, paused, loading, error }

class AudioService {
  final AudioPlayer _player = AudioPlayer();
  final Dio _dio = Dio();
  AudioState _state = AudioState.stopped;
  String? _currentUrl;
  double _progress = 0;
  Duration _duration = Duration.zero;
  StreamSubscription? _positionSub;
  StreamSubscription? _stateSub;
  StreamSubscription? _durationSub;

  AudioState get state => _state;
  double get progress => _progress;
  Duration get duration => _duration;
  String? get currentUrl => _currentUrl;
  bool get isPlaying => _player.playing;

  final StreamController<AudioState> _stateController = StreamController<AudioState>.broadcast();
  final StreamController<double> _progressController = StreamController<double>.broadcast();

  Stream<AudioState> get stateStream => _stateController.stream;
  Stream<double> get progressStream => _progressController.stream;

  AudioService() {
    _positionSub = _player.positionStream.listen((pos) {
      if (_duration.inMilliseconds > 0) {
        _progress = pos.inMilliseconds / _duration.inMilliseconds;
        _progressController.add(_progress);
      }
    });
    _stateSub = _player.playerStateStream.listen((playerState) {
      if (playerState.processingState == ProcessingState.completed) {
        _setState(AudioState.stopped);
      }
    });
    _durationSub = _player.durationStream.listen((dur) {
      if (dur != null) _duration = dur;
    });
  }

  void _setState(AudioState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  Future<void> playUrl(String url) async {
    try {
      _setState(AudioState.loading);
      _currentUrl = url;
      await _player.setUrl(url);
      await _player.play();
      _setState(AudioState.playing);
    } catch (e) {
      _setState(AudioState.error);
    }
  }

  Future<void> playLocal(String filePath) async {
    try {
      _setState(AudioState.loading);
      _currentUrl = filePath;
      await _player.setFilePath(filePath);
      await _player.play();
      _setState(AudioState.playing);
    } catch (e) {
      _setState(AudioState.error);
    }
  }

  Future<void> pause() async {
    await _player.pause();
    _setState(AudioState.paused);
  }

  Future<void> resume() async {
    await _player.play();
    _setState(AudioState.playing);
  }

  Future<void> stop() async {
    await _player.stop();
    _setState(AudioState.stopped);
    _progress = 0;
    _progressController.add(0);
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<String?> downloadAudio(String url, String fileName) async {
    try {
      bool granted = await _requestStoragePermission();
      if (!granted) return null;

      Directory? dir;
      if (Platform.isAndroid) {
        dir = await getExternalStorageDirectory();
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      if (dir == null) return null;

      String savePath = '${dir.path}/quran_audio';
      await Directory(savePath).create(recursive: true);

      String filePath = '$savePath/$fileName.mp3';
      File file = File(filePath);

      if (await file.exists()) return filePath;

      await _dio.download(url, filePath);
      return filePath;
    } catch (e) {
      return null;
    }
  }

  Future<bool> isDownloaded(String fileName) async {
    Directory? dir;
    if (Platform.isAndroid) {
      dir = await getExternalStorageDirectory();
    } else {
      dir = await getApplicationDocumentsDirectory();
    }
    if (dir == null) return false;

    String filePath = '${dir.path}/quran_audio/$fileName.mp3';
    return File(filePath).exists();
  }

  Future<String?> getLocalPath(String fileName) async {
    Directory? dir;
    if (Platform.isAndroid) {
      dir = await getExternalStorageDirectory();
    } else {
      dir = await getApplicationDocumentsDirectory();
    }
    if (dir == null) return null;
    String filePath = '${dir.path}/quran_audio/$fileName.mp3';
    if (await File(filePath).exists()) return filePath;
    return null;
  }

  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      if (await Permission.storage.isGranted) return true;
      if (await Permission.manageExternalStorage.isGranted) return true;

      var status = await Permission.storage.request();
      if (status.isGranted) return true;

      if (await Permission.manageExternalStorage.isGranted) return true;
      status = await Permission.manageExternalStorage.request();
      return status.isGranted;
    }
    return true;
  }

  void dispose() {
    _positionSub?.cancel();
    _stateSub?.cancel();
    _durationSub?.cancel();
    _stateController.close();
    _progressController.close();
    _player.dispose();
  }
}
