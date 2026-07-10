import 'dart:async';
import 'dart:io';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_service.dart';

enum PlayState { stopped, playing, paused, loading, error }

class AudioService {
  static final AudioService _instance = AudioService._();
  static AudioService get instance => _instance;

  final AudioPlayer _player = AudioPlayer();
  PlayState _state = PlayState.stopped;
  double _progress = 0;
  Duration _duration = Duration.zero;
  int? _currentIndex;
  int _totalItems = 0;
  bool _loopMode = false;
  String? _currentAyahUrl;
  int? activeSurahId;

  PlayState get state => _state;
  double get progress => _progress;
  Duration get duration => _duration;
  int? get currentIndex => _currentIndex;
  int get totalItems => _totalItems;
  bool get loopMode => _loopMode;
  bool get playing => _player.playing;

  final StreamController<PlayState> _stateCtrl =
      StreamController<PlayState>.broadcast();
  final StreamController<double> _progressCtrl =
      StreamController<double>.broadcast();
  final StreamController<int?> _indexCtrl = StreamController<int?>.broadcast();

  Stream<PlayState> get stateStream => _stateCtrl.stream;
  Stream<double> get progressStream => _progressCtrl.stream;
  Stream<int?> get indexStream => _indexCtrl.stream;

  AudioService._() {
    _posSub = _player.positionStream.listen((pos) {
      if (_duration.inMilliseconds > 0) {
        _progress = pos.inMilliseconds / _duration.inMilliseconds;
        _progressCtrl.add(_progress);
      }
    });

    _stateSub = _player.playerStateStream.listen((ps) {
      if (ps.processingState == ProcessingState.completed) {
        if (_loopMode && _totalItems > 0) {
          _player.seek(Duration.zero, index: 0);
          _player.play();
        } else {
          _setState(PlayState.stopped);
        }
      }
    });

    _durSub = _player.durationStream.listen((d) {
      if (d != null) _duration = d;
    });

    _indexSub = _player.currentIndexStream.listen((idx) {
      _currentIndex = idx;
      _indexCtrl.add(idx);
    });
  }

  late StreamSubscription _posSub;
  late StreamSubscription _stateSub;
  late StreamSubscription _durSub;
  late StreamSubscription _indexSub;

  void toggleLoop() {
    _loopMode = !_loopMode;
  }

  void _setState(PlayState s) {
    _state = s;
    _stateCtrl.add(s);
  }

  Future<bool> playUrl(String url, {bool append = false}) async {
    try {
      _setState(PlayState.loading);
      _currentAyahUrl = url;
      await _player.setUrl(url);
      await _player.play();
      _setState(PlayState.playing);
      _totalItems = 1;
      return true;
    } catch (e) {
      _setState(PlayState.error);
      return false;
    }
  }

  Future<bool> playList(List<String> urls, {int startIndex = 0}) async {
    try {
      _setState(PlayState.loading);
      await _player.stop();
      _totalItems = urls.length;
      final sources = urls.map((u) => AudioSource.uri(Uri.parse(u))).toList();
      await _player.setAudioSource(ConcatenatingAudioSource(children: sources));
      await _player.seek(Duration.zero, index: startIndex);
      _currentIndex = startIndex;
      _indexCtrl.add(startIndex);
      await _player.play();
      _setState(PlayState.playing);
      return true;
    } catch (e) {
      _setState(PlayState.error);
      return false;
    }
  }

  Future<bool> playLocalList(
    List<String> filePaths, {
    int startIndex = 0,
  }) async {
    try {
      _setState(PlayState.loading);
      await _player.stop();
      _totalItems = filePaths.length;
      final sources = filePaths.map((p) => AudioSource.file(p)).toList();
      await _player.setAudioSource(ConcatenatingAudioSource(children: sources));
      await _player.seek(Duration.zero, index: startIndex);
      _currentIndex = startIndex;
      _indexCtrl.add(startIndex);
      await _player.play();
      _setState(PlayState.playing);
      return true;
    } catch (e) {
      _setState(PlayState.error);
      return false;
    }
  }

  Future<void> next() async {
    if (_totalItems <= 1) return;
    final nextIdx = (_currentIndex ?? 0) + 1;
    if (nextIdx < _totalItems) {
      await _player.seekToNext();
    }
  }

  Future<void> previous() async {
    if (_totalItems <= 1) return;
    final prevIdx = (_currentIndex ?? 0) - 1;
    if (prevIdx >= 0) {
      await _player.seekToPrevious();
    }
  }

  Future<void> pause() async {
    await _player.pause();
    _setState(PlayState.paused);
  }

  Future<void> resume() async {
    await _player.play();
    _setState(PlayState.playing);
  }

  Future<void> stop() async {
    await _player.stop();
    _setState(PlayState.stopped);
    _progress = 0;
    _currentIndex = null;
    _totalItems = 0;
    activeSurahId = null;
    _indexCtrl.add(null);
    _progressCtrl.add(0);
  }

  Future<String> getDownloadDir() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('download_path');
    if (path != null && Directory(path).existsSync()) {
      return path;
    }

    final docDir = await getApplicationDocumentsDirectory();
    final defaultDir = '${docDir.path}/quran_audio';
    await Directory(defaultDir).create(recursive: true);
    return defaultDir;
  }

  Future<void> setDownloadDir(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('download_path', path);
  }

  Future<String?> downloadAudio(
    String url,
    String fileName, {
    void Function(double progress)? onProgress,
  }) async {
    try {
      final dir = await getDownloadDir();
      final saveDir = Directory('$dir/quran_audio');
      if (!await saveDir.exists()) await saveDir.create(recursive: true);

      final filePath = '${saveDir.path}/$fileName.mp3';
      final file = File(filePath);
      if (await file.exists()) return filePath;

      final client = HttpClient();
      try {
        final request = await client.getUrl(Uri.parse(url));
        final response = await request.close();
        final total = response.contentLength;
        var received = 0;
        final sink = file.openWrite();

        await for (final chunk in response) {
          sink.add(chunk);
          received += chunk.length;
          if (total != null && total > 0 && onProgress != null) {
            onProgress(received / total);
          }
        }
        await sink.close();
      } finally {
        client.close();
      }

      return filePath;
    } catch (e) {
      return null;
    }
  }

  Future<bool> isDownloaded(String fileName) async {
    final dir = await getDownloadDir();
    return File('$dir/quran_audio/$fileName.mp3').exists();
  }

  Future<String?> getLocalPath(String fileName) async {
    final dir = await getDownloadDir();
    final path = '$dir/quran_audio/$fileName.mp3';
    if (await File(path).exists()) return path;
    return null;
  }

  void dispose() {
    _posSub.cancel();
    _stateSub.cancel();
    _durSub.cancel();
    _indexSub.cancel();
    _stateCtrl.close();
    _progressCtrl.close();
    _indexCtrl.close();
    _player.dispose();
  }
}
