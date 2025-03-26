import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:media_gallery/main.dart';

class AddMediaScreen extends StatefulWidget {
  @override
  _AddMediaScreenState createState() => _AddMediaScreenState();
}

class _AddMediaScreenState extends State<AddMediaScreen> {
  final TextEditingController _urlController = TextEditingController();
  MediaType _selectedType = MediaType.image;
  Position? _currentPosition;
  bool _isLoadingLocation = false;

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Сервисы геолокации отключены')),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Разрешение на геолокацию отклонено')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Разрешение на геолокацию отклонено навсегда')),
      );
      return;
    }

    try {
      _currentPosition = await Geolocator.getCurrentPosition();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка получения местоположения: $e')),
      );
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  void _addMedia() {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Введите URL')),
      );
      return;
    }

    final mediaItem = MediaItem(
      url: url,
      type: _selectedType,
      date: DateTime.now(),
      latitude: _currentPosition?.latitude,
      longitude: _currentPosition?.longitude,
    );

    Hive.box<MediaItem>('mediaBox').add(mediaItem);
    _urlController.clear();
    setState(() => _currentPosition = null);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Медиа добавлено')),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Добавить медиа')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'URL медиа',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            DropdownButton<MediaType>(
              value: _selectedType,
              items: MediaType.values.map((type) {
                return DropdownMenuItem<MediaType>(
                  value: type,
                  child: Text(
                    type == MediaType.image ? 'Изображение' : 
                    type == MediaType.video ? 'Видео' : 'Аудио',
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedType = value);
                }
              },
            ),
            SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                  child: _isLoadingLocation
                      ? CircularProgressIndicator()
                      : Text('Добавить геолокацию'),
                ),
                SizedBox(width: 8),
                if (_currentPosition != null)
                  Text('Местоположение получено'),
              ],
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _addMedia,
              child: Text('Добавить медиа'),
            ),
          ],
        ),
      ),
    );
  }
}