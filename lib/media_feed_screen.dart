import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:media_gallery/main.dart';
import 'package:video_player/video_player.dart';

class MediaFeedScreen extends StatefulWidget {
  @override
  _MediaFeedScreenState createState() => _MediaFeedScreenState();
}

class _MediaFeedScreenState extends State<MediaFeedScreen> {
  final ScrollController _scrollController = ScrollController();
  final Box<MediaItem> _mediaBox = Hive.box<MediaItem>('mediaBox');

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Медиа Лента')),
      body: ValueListenableBuilder(
        valueListenable: _mediaBox.listenable(),
        builder: (context, Box<MediaItem> box, _) {
          final mediaItems = box.values.toList().reversed.toList();
          
          if (mediaItems.isEmpty) {
            return Center(child: Text('Нет медиа для отображения'));
          }

          return ListView.builder(
            controller: _scrollController,
            itemCount: mediaItems.length,
            itemBuilder: (context, index) {
              final item = mediaItems[index];
              return MediaItemWidget(item: item);
            },
          );
        },
      ),
    );
  }
}

class MediaItemWidget extends StatefulWidget {
  final MediaItem item;

  const MediaItemWidget({required this.item});

  @override
  _MediaItemWidgetState createState() => _MediaItemWidgetState();
}

class _MediaItemWidgetState extends State<MediaItemWidget> {
  VideoPlayerController? _videoController;
  bool _isVideoPlaying = false;

  @override
  void initState() {
    super.initState();
    if (widget.item.type == MediaType.video) {
      _videoController = VideoPlayerController.network(widget.item.url)
        ..initialize().then((_) {
          setState(() {});
          _videoController!.addListener(() {
            if (_videoController!.value.isPlaying != _isVideoPlaying) {
              setState(() {
                _isVideoPlaying = _videoController!.value.isPlaying;
              });
            }
          });
        });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.item.type == MediaType.image)
            Image.network(widget.item.url),
          if (widget.item.type == MediaType.video && _videoController != null)
            AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  VideoPlayer(_videoController!),
                  IconButton(
                    icon: Icon(
                      _isVideoPlaying ? Icons.pause : Icons.play_arrow,
                      size: 50,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        if (_isVideoPlaying) {
                          _videoController!.pause();
                        } else {
                          _videoController!.play();
                        }
                        _isVideoPlaying = !_isVideoPlaying;
                      });
                    },
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: VideoProgressIndicator(
                      _videoController!,
                      allowScrubbing: true,
                      colors: VideoProgressColors(
                        playedColor: Colors.red,
                        bufferedColor: Colors.grey,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Дата: ${widget.item.date.toString()}',
                  style: TextStyle(fontSize: 12),
                ),
                if (widget.item.latitude != null && widget.item.longitude != null)
                  Text(
                    'Местоположение: ${widget.item.latitude!.toStringAsFixed(4)}, ${widget.item.longitude!.toStringAsFixed(4)}',
                    style: TextStyle(fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}