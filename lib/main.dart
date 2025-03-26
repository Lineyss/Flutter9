import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:media_gallery/add_media_screen.dart';
import 'package:media_gallery/audio_player_screen.dart';
import 'package:media_gallery/media_feed_screen.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
 
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(MediaItemAdapter());
  await Hive.openBox<MediaItem>('mediaBox');
  runApp(MyApp());
}

@HiveType(typeId: 0)
class MediaItem {
  @HiveField(0)
  final String url;
  @HiveField(1)
  final MediaType type;
  @HiveField(2)
  final DateTime date;
  @HiveField(3)
  final double? latitude;
  @HiveField(4)
  final double? longitude;

  MediaItem({
    required this.url,
    required this.type,
    required this.date,
    this.latitude,
    this.longitude,
  });
}

@HiveType(typeId: 1)
enum MediaType {
  @HiveField(0)
  image,
  @HiveField(1)
  video,
  @HiveField(2)
  audio,
}

class MediaItemAdapter extends TypeAdapter<MediaItem> {
  @override
  final int typeId = 0;

  @override
  MediaItem read(BinaryReader reader) {
    return MediaItem(
      url: reader.read(),
      type: reader.read(),
      date: reader.read(),
      latitude: reader.read(),
      longitude: reader.read(),
    );
  }

  @override
  void write(BinaryWriter writer, MediaItem obj) {
    writer.write(obj.url);
    writer.write(obj.type);
    writer.write(obj.date);
    writer.write(obj.latitude);
    writer.write(obj.longitude);
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Медиа Галерея',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    MediaFeedScreen(),
    AddMediaScreen(),
    AudioPlayerScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Лента',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Добавить',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.music_note),
            label: 'Аудио',
          ),
        ],
      ),
    );
  }
}