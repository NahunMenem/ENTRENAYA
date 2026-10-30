import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class ExerciseVideo extends StatefulWidget {
  const ExerciseVideo({super.key, required this.name, required this.url});
  final String name;
  final String url;

  @override
  State<ExerciseVideo> createState() => _ExerciseVideoState();
}

class _ExerciseVideoState extends State<ExerciseVideo>
    with WidgetsBindingObserver {
  late final VideoPlayerController _controller;
  late final Future<void> _ready;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _ready = _controller.initialize().timeout(const Duration(seconds: 25));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _controller.pause();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.name)),
    body: Center(
      child: FutureBuilder<void>(
        future: _ready,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No pudimos cargar el video. Revisá tu conexión e intentá abrirlo otra vez.',
              ),
            );
          }
          if (snapshot.connectionState != ConnectionState.done) {
            return const CircularProgressIndicator();
          }
          return ValueListenableBuilder<VideoPlayerValue>(
            valueListenable: _controller,
            builder: (context, value, _) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (value.hasError)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'Se interrumpió el video. Volvé a abrirlo para reintentar.',
                    ),
                  )
                else
                  AspectRatio(
                    aspectRatio: value.aspectRatio,
                    child: VideoPlayer(_controller),
                  ),
                VideoProgressIndicator(_controller, allowScrubbing: true),
                IconButton.filled(
                  tooltip: value.isPlaying ? 'Pausar' : 'Reproducir',
                  icon: Icon(value.isPlaying ? Icons.pause : Icons.play_arrow),
                  onPressed: value.hasError
                      ? null
                      : () async {
                          if (value.isPlaying) {
                            await _controller.pause();
                          } else {
                            if (value.position >= value.duration) {
                              await _controller.seekTo(Duration.zero);
                            }
                            await _controller.play();
                          }
                        },
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
}
