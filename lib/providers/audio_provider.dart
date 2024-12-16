import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:record/record.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';  // 添加 File 类的导入
class Message {
  final String content;
  final bool isUser;

  Message(this.content, this.isUser);
}

class AudioProvider with ChangeNotifier {
  final List<Message> _messages = [];
  bool _isRecording = false;
  bool _isConnected = false;
  
  WebSocketChannel? _channel;
  Record? _recorder;
  Timer? _audioTimer;

  List<Message> get messages => List.unmodifiable(_messages);
  bool get isRecording => _isRecording;
  bool get isConnected => _isConnected;

  AudioProvider() {
    _messages.add(
      Message(
        "你好！我是你的英语口语助手。请说一句英语，我会帮你纠正发音和语法。",
        false,
      ),
    );    
    _initializeWebSocket();
    _initializeRecorder();
  }
 // 添加测试消息的方法
  void addTestMessage() {
    _messages.add(Message("This is a test message", true));
    _messages.add(Message("这是一条 AI 回复的测试消息", false));
    notifyListeners();  // 通知监听者更新 UI
  }
  Future<void> _initializeWebSocket() async {
    final apiKey = dotenv.env['GOOGLE_API_KEY'];
    final uri = 'wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1alpha.GenerativeService.BidiGenerateContent?key=$apiKey';
    
    _channel = WebSocketChannel.connect(Uri.parse(uri));
    
    // Send initial setup message
    final setupMsg = {
      "setup": {
        "model": "models/gemini-2.0-flash-exp",
        "generation_config": {
          "response_modalities": ["TEXT"]
        }
      }
    };
    
    _channel!.sink.add(jsonEncode(setupMsg));
    
    // Send initial prompt
    final initialPrompt = {
      "client_content": {
        "turns": [
          {
            "role": "user",
            "parts": [{
              "text": "你是一名专业的英语口语指导老师，你需要帮助用户纠正语法发音..."
            }]
          }
        ],
        "turn_complete": true
      }
    };
    
    _channel!.sink.add(jsonEncode(initialPrompt));
    
    _channel!.stream.listen(
      (message) {
        _handleWebSocketMessage(message);
      },
      onDone: () {
        _isConnected = false;
        notifyListeners();
      },
      onError: (error) {
        print('WebSocket error: $error');
        _isConnected = false;
        notifyListeners();
      },
    );
    
    _isConnected = true;
    notifyListeners();
  }

  Future<void> _initializeRecorder() async {
    _recorder = Record();
  }

  Future<void> startRecording() async {
    if (!_isRecording) {
      if (await _recorder!.hasPermission()) {
        await _recorder!.start(
          encoder: AudioEncoder.wav,
          samplingRate: 16000,
          numChannels: 1,
        );
        
        _isRecording = true;
        notifyListeners();

        // Start sending audio data periodically
        _audioTimer = Timer.periodic(
          const Duration(milliseconds: 100),
          _sendAudioChunk,
        );
      }
    }
  }

  Future<void> stopRecording() async {
    if (_isRecording) {
      _audioTimer?.cancel();
      await _recorder!.stop();
      _isRecording = false;
      notifyListeners();
    }
  }

  Future<void> _sendAudioChunk(Timer timer) async {
    if (_isRecording && _isConnected) {
      final path = await _recorder!.stop();
      if (path != null) {
        // Read the audio data and send it
        // Implementation depends on how you want to handle the audio chunks
        // This is a simplified version
        final audioData = await File(path).readAsBytes();
        final base64Audio = base64Encode(audioData);
        
        final audioMsg = {
          "realtime_input": {
            "media_chunks": [
              {
                "data": base64Audio,
                "mime_type": "audio/wav"
              }
            ]
          }
        };
        
        _channel!.sink.add(jsonEncode(audioMsg));
        
        // Restart recording for next chunk
        await _recorder!.start(
          encoder: AudioEncoder.wav,
          samplingRate: 16000,
          numChannels: 1,
        );
      }
    }
  }

  void _handleWebSocketMessage(String message) {
    final data = jsonDecode(message);
    if (data['serverContent'] != null) {
      final parts = data['serverContent']['modelTurn']['parts'] as List;
      for (final part in parts) {
        if (part['text'] != null) {
          _messages.add(Message(part['text'], false));
          notifyListeners();
        }
      }
    }
  }

  @override
  void dispose() {
    _audioTimer?.cancel();
    _recorder?.dispose();
    _channel?.sink.close();
    super.dispose();
  }
}