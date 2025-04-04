import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:media_gallery/main.dart';

class AudioPlayerScreen extends StatefulWidget {
  @override
  _AudioPlayerScreenState createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final TextEditingController _urlController = TextEditingController();
  PlayerState _playerState = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isLoading = false;
  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;

  @override
  void initState() {
    super.initState();
    _playerStateSubscription =
        _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _playerState = state);
      }
    });

    _durationSubscription = _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() => _duration = duration);
      }
    });

    _positionSubscription = _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() => _position = position);
      }
    });

    // Установка тестового URL для проверки
    _urlController.text = 'https://www2.cs.uic.edu/~i101/SoundFiles/taunt.wav';
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _audioPlayer.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _playAudio() async {
    final url = _urlController.text.trim();
    if (url.isEmpty || !Uri.parse(url).isAbsolute) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Введите корректный URL')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _audioPlayer.stop(); // Остановить текущее воспроизведение

      if (kIsWeb) {
        // Для веба используем альтернативный подход
        await _audioPlayer.setSourceUrl(url);
        await _audioPlayer.resume();
      } else {
        await _audioPlayer.play(UrlSource(url));
      }
    } catch (e) {
      print('Ошибка воспроизведения: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Не удалось воспроизвести аудио. Попробуйте другой URL')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pauseAudio() async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при паузе: $e')),
        );
      }
    }
  }

  Future<void> _stopAudio() async {
    try {
      await _audioPlayer.stop();
      if (mounted) {
        setState(() {
          _position = Duration.zero;
          _playerState = PlayerState.stopped;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при остановке: $e')),
        );
      }
    }
  }

  Future<void> _saveAudio() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Введите URL аудио')),
        );
      }
      return;
    }

    final mediaItem = MediaItem(
      url: url,
      type: MediaType.audio,
      date: DateTime.now(),
    );

    Hive.box<MediaItem>('mediaBox').add(mediaItem);
    _urlController.clear();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Аудио сохранено')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Аудио Проигрыватель')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'URL аудио',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.play_arrow),
                  onPressed:
                      _playerState == PlayerState.playing ? null : _playAudio,
                ),
                IconButton(
                  icon: Icon(Icons.pause),
                  onPressed:
                      _playerState != PlayerState.playing ? null : _pauseAudio,
                ),
                IconButton(
                  icon: Icon(Icons.stop),
                  onPressed:
                      _playerState == PlayerState.stopped ? null : _stopAudio,
                ),
              ],
            ),
            if (_isLoading) CircularProgressIndicator(),
            if (_duration != Duration.zero)
              Column(
                children: [
                  Slider(
                    min: 0,
                    max: _duration.inSeconds.toDouble(),
                    value: _position.inSeconds
                        .toDouble()
                        .clamp(0, _duration.inSeconds.toDouble()),
                    onChanged: (value) async {
                      final newPosition = Duration(seconds: value.toInt());
                      await _audioPlayer.seek(newPosition);
                      if (mounted) {
                        setState(() => _position = newPosition);
                      }
                    },
                  ),
                  Text(
                    '${_position.toString().split('.').first} / ${_duration.toString().split('.').first}',
                  ),
                ],
              ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveAudio,
              child: Text('Сохранить аудио'),
            ),
            SizedBox(height: 16),
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: Hive.box<MediaItem>('mediaBox').listenable(),
                builder: (context, Box<MediaItem> box, _) {
                  final audioItems = box.values
                      .where((item) => item.type == MediaType.audio)
                      .toList()
                      .reversed
                      .toList();

                  if (audioItems.isEmpty) {
                    return Center(child: Text('Нет сохраненных аудио'));
                  }

                  return ListView.builder(
                    itemCount: audioItems.length,
                    itemBuilder: (context, index) {
                      final item = audioItems[index];
                      return ListTile(
                        title: Text(item.url),
                        subtitle: Text(item.date.toString()),
                        onTap: () {
                          _urlController.text = item.url;
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
