import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'pages/home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  int _currentTrack = 1;
  final int _totalTracks = 5;

  @override
  void initState() {
    super.initState();
    _setupAudioPlayer();
  }

  void _setupAudioPlayer() async {
    // 設置音樂結束時的監聽器
    _audioPlayer.onPlayerComplete.listen((event) {
      _playNextTrack();
    });
    
    // 設置音頻模式和音量
    await _audioPlayer.setReleaseMode(ReleaseMode.release);
    await _audioPlayer.setVolume(0.5); // 調整音量
    
    // 開始播放第一首歌
    await _startBackgroundMusic();
  }

  Future<void> _startBackgroundMusic() async {
    try {
      await _audioPlayer.stop(); // 先停止當前播放
      await _audioPlayer.setSourceAsset('sound/$_currentTrack.mp3');
      await _audioPlayer.resume();
    } catch (e) {
      debugPrint('Error playing audio: $e');
    }
  }

  void _playNextTrack() async {
    setState(() {
      if (_currentTrack < _totalTracks) {
        _currentTrack++;
      } else {
        _currentTrack = 1;
      }
    });
    await _startBackgroundMusic();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gamble Game',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        fontFamily: 'manga', // 預設英文字體
        textTheme: TextTheme(
          // 設置所有文字的預設樣式
          bodyLarge: TextStyle(fontFamily: 'boutique'), // 中文字體
          bodyMedium: TextStyle(fontFamily: 'boutique'),
          titleLarge: TextStyle(fontFamily: 'manga'),
          labelLarge: TextStyle(fontFamily: 'manga'),
        ),
      ),
      home: const HomePage(),
    );
  }
}
