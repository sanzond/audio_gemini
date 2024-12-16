// lib/screens/tutor_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../providers/audio_provider.dart';

class TutorScreen extends StatelessWidget {
  const TutorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text(
          'AI English Tutor',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Consumer<AudioProvider>(
        builder: (context, audioProvider, child) {
          // 添加调试信息
          print('Messages count: ${audioProvider.messages.length}');
          print('Is recording: ${audioProvider.isRecording}');
          
          return Column(
            children: [
              // 添加一个固定的文本组件测试是否显示
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  '欢迎使用英语口语助手',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  color: Colors.grey[100],  // 添加背景色以便于识别
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: audioProvider.messages.length,
                    itemBuilder: (context, index) {
                      final message = audioProvider.messages[index];
                      return MessageBubble(message: message);
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (audioProvider.isRecording) {
                      audioProvider.stopRecording();
                    } else {
                      audioProvider.startRecording();
                    }
                  },
                  icon: Icon(
                    audioProvider.isRecording ? Icons.stop : Icons.mic,
                    color: Colors.white,
                  ),
                  label: Text(
                    audioProvider.isRecording ? '停止录音' : '开始录音',
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: audioProvider.isRecording ? Colors.red : Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      // 添加在这里，与 appBar 和 body 同级
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.read<AudioProvider>().addTestMessage();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final Message message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Align(
        alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: message.isUser ? Colors.blue : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: message.isUser
              ? Text(
                  message.content,
                  style: const TextStyle(color: Colors.white),
                )
              : MarkdownBody(data: message.content),
        ),
      ),
    );
  }
}