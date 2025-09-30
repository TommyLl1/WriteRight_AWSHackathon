import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class PlayAudioWidget extends StatefulWidget {
  final String audioUrl;
  final double size;

  const PlayAudioWidget({
    super.key,
    required this.audioUrl,
    this.size = 40,
  });

  @override
  State<PlayAudioWidget> createState() => _PlayAudioWidgetState();
}

class _PlayAudioWidgetState extends State<PlayAudioWidget> {
  late AudioPlayer _player;
  bool isPlaying = false;
  late final StreamSubscription<PlayerState> _playerStateSubscription;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _player.setUrl(widget.audioUrl);
    _playerStateSubscription = _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        if (mounted) {
          setState(() {
            isPlaying = false;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _playerStateSubscription.cancel();
    _player.dispose();
    super.dispose();
  }

  void _togglePlay() async {
    if (isPlaying) {
      await _player.pause();
    } else {
      await _player.seek(Duration.zero);
      await _player.play();
    }

    if (mounted) {
      setState(() {
        isPlaying = !isPlaying;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double iconSize = widget.size;
    final double padding = widget.size * 0.6; // proportional padding
    return ElevatedButton(
      onPressed: _togglePlay,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.all(padding),
        backgroundColor: Colors.lightBlueAccent,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(widget.size * 0.4)),
      ),
      child: Icon(
        isPlaying ? Icons.pause : Icons.volume_up,
        size: iconSize,
        color: Colors.white,
      ),
    );
  }
}
