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
  StreamSubscription? _posSub;
  StreamSubscription? _stateSub;
  StreamSubscription? _durSub;

  PlayState get state => _state;
  double get progress => _progress;
  Duration get duration => _duration;

  final StreamController<PlayState> _stateCtrl = StreamController<PlayState>.broadcast();
  final StreamController<double> _progressCtrl = StreamController<double>.broadcast();

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
      await _player.setFilePath(path);
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

      final response = await httpGet(Uri.parse(url));
      await file.writeAsBytes(response);
      return filePath;
    } catch (e) {
      return null;
    }
  }

  Future<Uint8List> httpGet(Uri uri) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      final response = await request.close();
      final bytes = await response.fold<Uint8List>(
        Uint8List(0),
        (prev, chunk) => Uint8List.fromList([...prev, ...chunk]),
      );
      return bytes;
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
