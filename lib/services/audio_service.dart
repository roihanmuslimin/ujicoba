import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

enum PlayState { stopped, playing, paused, loading, error }

class AudioService {
  final AudioPlayer _player = AudioPlayer();
  PlayState _state = PlayState.stopped;
  double _progress = 0;
  Duration _duration = Duration.zero;
  String? _currentUrl;
  StreamSubscription? _posSub;
  StreamSubscription? _stateSub;
  StreamSubscription? _durSub;

  PlayState get state => _state;
  double get progress => _progress;
  Duration get duration => _duration;
  String? get currentUrl => _currentUrl;

  final StreamController<PlayState> _stateCtrl =
      StreamController<PlayState>.broadcast();
  final StreamController<double> _progressCtrl =
      StreamController<double>.broadcast();

  Stream<PlayState> get stateStream => _stateCtrl.stream;
  Stream<double> get progressStream => _progressCtrl.stream;

  AudioService() {
    _posSub = _player.positionStream.listen((pos) {
      if (_duration.inMilliseconds > 0) {
        _progress = pos.inMilliseconds / _duration.inMilliseconds;
        _progressCtrl.add(_progress);
      }
    });
    _stateSub = _player.playerStateStream.listen((ps) {
      if (ps.processingState == ProcessingState.completed) {
        _setState(PlayState.stopped);
      } else if (ps.processingState == ProcessingState.ready &&
          _state == PlayState.loading) {
        if (_player.playing) _setState(PlayState.playing);
      }
    });
    _durSub = _player.durationStream.listen((d) {
      if (d != null) _duration = d;
    });
  }

  void _setState(PlayState s) {
    _state = s;
    _stateCtrl.add(s);
  }

  Future<void> play(String url) async {
    try {
      _setState(PlayState.loading);
      _currentUrl = url;
      await _player.stop();
      await _player.setUrl(url);
      await _player.play();
      _setState(PlayState.playing);
    } catch (e) {
      _setState(PlayState.error);
    }
  }

  Future<void> playLocal(String path) async {
    try {
      _setState(PlayState.loading);
      _currentUrl = path;
      await _player.stop();
      await _player.setFilePath(path);
      await _player.play();
      _setState(PlayState.playing);
    } catch (e) {
      _setState(PlayState.error);
    }
  }

  Future<void> playList(List<String> urls, {int startIndex = 0}) async {
    try {
      _setState(PlayState.loading);
      await _player.stop();
      final sources = urls.map((u) => AudioSource.uri(Uri.parse(u))).toList();
      await _player.setAudioSource(ConcatenatingAudioSource(children: sources));
      await _player.seek(Duration.zero, index: startIndex);
      await _player.play();
      _setState(PlayState.playing);
    } catch (e) {
      _setState(PlayState.error);
    }
  }

  Future<void> pause() async {
    await _player.pause();
    _setState(PlayState.paused);
  }

  Future<void> stop() async {
    await _player.stop();
    _setState(PlayState.stopped);
    _progress = 0;
    _progressCtrl.add(0);
  }

  Future<String?> download(String url, String fileName) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final saveDir = Directory('${dir.path}/quran_audio');
      if (!await saveDir.exists()) await saveDir.create(recursive: true);

      final filePath = '${saveDir.path}/$fileName.mp3';
      final file = File(filePath);
      if (await file.exists()) return filePath;

      final bytes = await _httpGet(Uri.parse(url));
      await file.writeAsBytes(bytes);
      return filePath;
    } catch (e) {
      return null;
    }
  }

  Future<Uint8List> _httpGet(Uri uri) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      final response = await request.close();
      final chunks = <Uint8List>[];
      await for (final chunk in response) {
        chunks.add(chunk);
      }
      int total = chunks.fold(0, (sum, c) => sum + c.length);
      final result = Uint8List(total);
      int offset = 0;
      for (final chunk in chunks) {
        result.setRange(offset, offset + chunk.length, chunk);
        offset += chunk.length;
      }
      return result;
    } finally {
      client.close();
    }
  }

  Future<bool> isDownloaded(String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/quran_audio/$fileName.mp3').exists();
  }

  Future<String?> getLocalPath(String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/quran_audio/$fileName.mp3';
    if (await File(path).exists()) return path;
    return null;
  }

  void dispose() {
    _posSub?.cancel();
    _stateSub?.cancel();
    _durSub?.cancel();
    _stateCtrl.close();
    _progressCtrl.close();
    _player.dispose();
  }
}
