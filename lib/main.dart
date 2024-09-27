import 'dart:async';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_sound_platform_interface/flutter_sound_recorder_platform_interface.dart';
import 'package:permission_handler/permission_handler.dart';



const theSource = AudioSource.microphone;


class AudioScreen extends StatefulWidget {
  const AudioScreen({super.key});

  @override
  State<AudioScreen> createState() => _AudioScreenState();
}

class _AudioScreenState extends State<AudioScreen> {
  Codec _codec = Codec.aacMP4;
  String _mPath = 'tau_file.mp4';
  FlutterSoundPlayer? _mPlayer = FlutterSoundPlayer();
  FlutterSoundRecorder? _mRecorder = FlutterSoundRecorder();
  bool _mPlayerIsInited = false;
  bool _mRecorderIsInited = false;
  bool _mPlaybackReady = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
    _initRecorder();
  }

  @override
  void dispose() {
    _mPlayer?.closePlayer();
    _mRecorder?.closeRecorder();
    super.dispose();
  }

  Future<void> _initPlayer() async {
    await _mPlayer?.openPlayer();
    setState(() => _mPlayerIsInited = true);
  }

  Future<void> _initRecorder() async {
    if (!kIsWeb) {
      if (await Permission.microphone.request() != PermissionStatus.granted) {
        throw RecordingPermissionException('Microphone permission not granted');
      }
    }

    await _mRecorder?.openRecorder();
    if (kIsWeb && !await _mRecorder!.isEncoderSupported(_codec)) {
      _codec = Codec.opusWebM;
      _mPath = 'tau_file.webm';
    }

    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
      avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.allowBluetooth |
      AVAudioSessionCategoryOptions.defaultToSpeaker,
      avAudioSessionMode: AVAudioSessionMode.spokenAudio,
      androidAudioAttributes: const AndroidAudioAttributes(
        contentType: AndroidAudioContentType.speech,
        usage: AndroidAudioUsage.voiceCommunication,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      androidWillPauseWhenDucked: true,
    ));

    setState(() => _mRecorderIsInited = true);
  }

  void _record() async {
    if (_mRecorderIsInited && _mPlayer!.isStopped) {
      await _mRecorder?.startRecorder(toFile: _mPath, codec: _codec, audioSource: theSource);
      setState(() {});
    }
  }

  void _stopRecorder() async {
    if (_mRecorder!.isRecording) {
      await _mRecorder?.stopRecorder();
      setState(() => _mPlaybackReady = true);
    }
  }

  void _play() async {
    if (_mPlayerIsInited && _mPlaybackReady && _mPlayer!.isStopped) {
      await _mPlayer?.startPlayer(fromURI: _mPath, whenFinished: () => setState(() {}));
      setState(() {});
    }
  }

  void _stopPlayer() async {
    if (_mPlayer!.isPlaying) {
      await _mPlayer?.stopPlayer();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      appBar: AppBar(title: const Text('Jeux Recorder')),
      body: Column(
        children: [
          _buildControlPanel(
            buttonText: _mRecorder!.isRecording ? 'Stop' : 'Record',
            onPressed: _mRecorder!.isRecording ? _stopRecorder : _record,
            statusText: !_mRecorderIsInited
                ? 'Initializing recorder...'
                : _mRecorder!.isRecording
                ? 'Recording in progress'
                : 'Recorder is stopped',
          ),
          _buildControlPanel(
            buttonText: _mPlayer!.isPlaying ? 'Stop' : 'Play',
            onPressed: _mPlayer!.isPlaying ? _stopPlayer : _play,
            statusText: !_mPlayerIsInited
                ? 'Initializing player...'
                : _mPlayer!.isPlaying
                ? 'Playback in progress'
                : 'Player is stopped',
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel({required String buttonText, required VoidCallback onPressed, required String statusText}) {
    return Container(
      margin: const EdgeInsets.all(3),
      padding: const EdgeInsets.all(3),
      height: 80,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFFAF0E6),
        border: Border.all(color: Colors.indigo, width: 3),
      ),
      child: Row(
        children: [
          ElevatedButton(onPressed: onPressed, child: Text(buttonText)),
          const SizedBox(width: 20),
          Text(statusText),
        ],
      ),
    );
  }
}

void main() {
  runApp(const MaterialApp(home: AudioScreen()));
}
